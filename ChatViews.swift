import SwiftUI
import WebKit
import AVFoundation

// MARK: - Chat List
struct ChatListView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var conversations: [Conversation] = []
    @State private var showNew = false
    @State private var selected: Conversation?

    var body: some View {
        NavigationStack {
            Group {
                if conversations.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 48)).foregroundColor(Color.brand.opacity(0.4))
                        Text("No conversations yet").foregroundColor(.secondary)
                        Button(action: { showNew = true }) {
                            Text("Start a conversation")
                                .font(.system(size: 15, weight: .medium)).foregroundColor(.white)
                                .padding(.horizontal, 24).padding(.vertical, 12)
                                .background(Color.accent).cornerRadius(12)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(conversations) { conv in
                            Button(action: { selected = conv }) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle().fill(Color.brand.opacity(0.1)).frame(width: 40, height: 40)
                                        Image(systemName: "bubble.left.fill").foregroundColor(Color.brand)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(conv.displayTitle).font(.system(size: 15, weight: .medium))
                                        Text(relativeDate(conv.createdAt)).font(.system(size: 12)).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Chat")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showNew = true }) {
                        Image(systemName: "square.and.pencil").foregroundColor(Color.brand)
                    }
                }
            }
            .navigationDestination(isPresented: $showNew) { NativeChatView(conversationId: nil) }
            .navigationDestination(item: $selected) { NativeChatView(conversationId: $0.id) }
        }
        .task { await load() }
    }

    func load() async {
        if let c = try? await APIService.shared.request(path: "/api/conversations") as [Conversation] {
            conversations = c
        }
    }

    func relativeDate(_ str: String) -> String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = fmt.date(from: str) else { return "" }
        let rel = RelativeDateTimeFormatter(); rel.unitsStyle = .abbreviated
        return rel.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Native Chat
struct NativeChatView: View {
    let conversationId: Int?
    var openingMode: String? = nil
    @State private var messages: [Message] = []
    @State private var input = ""
    @State private var isStreaming = false
    @State private var streamingText = ""
    @State private var activeConvId: Int?
    @State private var isRecording = false
    @State private var isTranscribing = false
    @State private var recorder: AVAudioRecorder?
    @State private var audioURL: URL?
    @State private var showMood = true
    @State private var selectedMood: String? = nil
    @State private var playingMessageId: Int? = nil
    @State private var audioPlayer: AVAudioPlayer? = nil
    @FocusState private var focused: Bool

    let moods: [(id: String, emoji: String, label: String)] = [
        ("anxious", "😟", "Anxious"),
        ("sad", "😔", "Sad"),
        ("stressed", "😩", "Stressed"),
        ("hopeful", "🙏", "Hopeful"),
        ("joyful", "😊", "Grateful"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { msg in
                            VStack(spacing: 6) {
                                MessageBubble(
                                    message: msg,
                                    isPlaying: playingMessageId == msg.id,
                                    onListen: { listenTo(msg) }
                                )
                            }
                            .id(msg.id)
                        }
                        if !streamingText.isEmpty {
                            MessageBubble(
                                message: Message(id: -1, role: "assistant", content: streamingText, createdAt: ""),
                                isPlaying: false,
                                onListen: {}
                            ).id("streaming")
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)
                }
                .onChange(of: messages.count) { _, _ in
                    withAnimation { proxy.scrollTo(messages.last?.id, anchor: .bottom) }
                }
                .onChange(of: streamingText) { _, _ in
                    proxy.scrollTo("streaming", anchor: .bottom)
                }
            }

            // Mood check-in
            if showMood && messages.count <= 1 && conversationId == nil {
                MoodCheckInView(moods: moods, selected: $selectedMood, onSkip: { showMood = false })
            }

            Divider()

            HStack(spacing: 10) {
                TextField("Share what's on your heart...", text: $input, axis: .vertical)
                    .lineLimit(1...5)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(Color(.secondarySystemBackground)).cornerRadius(20)
                    .focused($focused)

                if input.isEmpty && !isStreaming {
                    Button(action: handleMic) {
                        ZStack {
                            Circle()
                                .fill(isRecording ? Color.red : Color(.secondarySystemBackground))
                                .frame(width: 36, height: 36)
                            if isTranscribing {
                                ProgressView().tint(Color.brand).scaleEffect(0.7)
                            } else {
                                Image(systemName: isRecording ? "stop.fill" : "mic")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(isRecording ? .white : Color.brand)
                            }
                        }
                    }
                }

                Button(action: send) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(input.isEmpty || isStreaming ? Color.secondary : Color.accent)
                        .clipShape(Circle())
                }
                .disabled(input.isEmpty || isStreaming)
            }
            .padding(.horizontal, 12).padding(.vertical, 8).padding(.bottom, 4)
        }
        .navigationTitle("Soul Care").navigationBarTitleDisplayMode(.inline)
        .task { await setup() }
    }

    func listenTo(_ message: Message) {
        if playingMessageId == message.id {
            audioPlayer?.stop()
            playingMessageId = nil
            return
        }
        playingMessageId = message.id
        Task {
            do {
                struct SpeakResponse: Codable { let audio: String; let format: String }
                let r: SpeakResponse = try await APIService.shared.request(
                    path: "/api/voice/speak", method: "POST",
                    body: ["text": message.content, "voice": "nova"]
                )
                if let data = Data(base64Encoded: r.audio) {
                    await MainActor.run {
                        try? AVAudioSession.sharedInstance().setCategory(.playback)
                        try? AVAudioSession.sharedInstance().setActive(true)
                        audioPlayer = try? AVAudioPlayer(data: data)
                        audioPlayer?.play()
                    }
                    try? await Task.sleep(nanoseconds: UInt64((audioPlayer?.duration ?? 0) * 1_000_000_000))
                    await MainActor.run { playingMessageId = nil }
                }
            } catch {
                await MainActor.run { playingMessageId = nil }
            }
        }
    }

    func handleMic() {
        if isRecording { stopRecording() } else { startRecording() }
    }

    func startRecording() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            guard granted else { return }
            DispatchQueue.main.async {
                let session = AVAudioSession.sharedInstance()
                try? session.setCategory(.record, mode: .default)
                try? session.setActive(true)
                let url = FileManager.default.temporaryDirectory.appendingPathComponent("recording.m4a")
                let settings: [String: Any] = [
                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                    AVSampleRateKey: 44100,
                    AVNumberOfChannelsKey: 1,
                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                ]
                recorder = try? AVAudioRecorder(url: url, settings: settings)
                recorder?.record()
                audioURL = url
                isRecording = true
            }
        }
    }

    func stopRecording() {
        recorder?.stop(); recorder = nil; isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false)
        guard let url = audioURL else { return }
        isTranscribing = true
        Task {
            do {
                let data = try Data(contentsOf: url)
                struct TranscribeResponse: Codable { let transcript: String }
                let r: TranscribeResponse = try await APIService.shared.request(
                    path: "/api/voice/transcribe", method: "POST",
                    body: ["audio": data.base64EncodedString(), "format": "mp4"]
                )
                await MainActor.run {
                    if !r.transcript.isEmpty { input = r.transcript }
                    isTranscribing = false
                }
            } catch { await MainActor.run { isTranscribing = false } }
        }
    }

    func setup() async {
        if let id = conversationId {
            activeConvId = id
            showMood = false
            if let r = try? await APIService.shared.request(path: "/api/conversations/\(id)/messages") as MessagesResponse {
                messages = r.messages
            }
        } else {
            if let r = try? await APIService.shared.request(
                path: "/api/conversations", method: "POST",
                body: ["title": "New Conversation", "channel": "general"]
            ) as CreateConversationResponse {
                activeConvId = r.id
            }
            let mode = openingMode ?? "checkin"
            struct OpeningResponse: Codable { let message: String }
            if let opening = try? await APIService.shared.request(
                path: "/api/chat/personalized-opening?mode=\(mode)"
            ) as OpeningResponse {
                await MainActor.run {
                    messages.append(Message(id: Int.random(in: 100000...999999), role: "assistant", content: opening.message, createdAt: ""))
                }
            }
        }
    }

    func send() {
        guard let convId = activeConvId, !input.isEmpty, !isStreaming else { return }
        let content = input; input = ""
        let mood = selectedMood
        showMood = false
        messages.append(Message(id: Int.random(in: 100000...999999), role: "user", content: content, createdAt: ""))
        isStreaming = true; streamingText = ""
        Task {
            do {
                for try await chunk in APIService.shared.streamChat(conversationId: convId, content: content, mood: mood) {
                    await MainActor.run { streamingText += chunk }
                }
                await MainActor.run {
                    if !streamingText.isEmpty {
                        messages.append(Message(id: Int.random(in: 100000...999999), role: "assistant", content: streamingText, createdAt: ""))
                        streamingText = ""
                    }
                    isStreaming = false
                    selectedMood = nil
                }
            } catch { await MainActor.run { isStreaming = false } }
        }
    }
}

// MARK: - Mood Check-In
struct MoodCheckInView: View {
    let moods: [(id: String, emoji: String, label: String)]
    @Binding var selected: String?
    let onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("How are you feeling right now?")
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                Button("Skip", action: onSkip)
                    .font(.system(size: 13)).foregroundColor(.secondary)
            }
            HStack(spacing: 8) {
                ForEach(moods, id: \.id) { mood in
                    Button(action: { selected = selected == mood.id ? nil : mood.id }) {
                        VStack(spacing: 4) {
                            Text(mood.emoji).font(.system(size: 22))
                            Text(mood.label).font(.system(size: 10, weight: .medium))
                                .foregroundColor(selected == mood.id ? Color.brand : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(selected == mood.id ? Color.brand.opacity(0.1) : Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(selected == mood.id ? Color.brand : Color.clear, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(Color(.systemBackground))
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: Message
    var isPlaying: Bool = false
    var onListen: () -> Void = {}

    var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
            HStack(alignment: .bottom, spacing: 8) {
                if message.isUser { Spacer(minLength: 60) }
                if !message.isUser {
                    ZStack {
                        Circle().fill(Color.brand.opacity(0.15)).frame(width: 28, height: 28)
                        Image(systemName: "flame.fill").font(.system(size: 12)).foregroundColor(Color.brand)
                    }
                }
                Text(message.content)
                    .font(.system(size: 16)).lineSpacing(2)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(message.isUser ? Color.brand : Color(.secondarySystemBackground))
                    .foregroundColor(message.isUser ? .white : .primary)
                    .cornerRadius(18)
                if !message.isUser { Spacer(minLength: 60) }
            }
            // Listen button for AI messages
            if !message.isUser && message.id != -1 {
                Button(action: onListen) {
                    HStack(spacing: 4) {
                        Image(systemName: isPlaying ? "pause.fill" : "speaker.wave.2")
                            .font(.system(size: 11))
                        Text(isPlaying ? "Playing..." : "Listen")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.secondary)
                    .padding(.leading, 44)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

