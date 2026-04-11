import SwiftUI
import WebKit
import AVFoundation

// MARK: - Native Journal
struct JournalView: View {
    @State private var entries: [JournalEntryFull] = []
    @State private var showNew = false
    @State private var isLoading = true

    let moods = [
        ("grateful", "🙏", "Grateful"),
        ("hopeful", "✨", "Hopeful"),
        ("peaceful", "🕊️", "Peaceful"),
        ("anxious", "😟", "Anxious"),
        ("sad", "😔", "Sad"),
        ("wrestling", "⚡", "Wrestling"),
    ]

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if entries.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed").font(.system(size: 48)).foregroundColor(Color.brand.opacity(0.4))
                        Text("Your journal is empty").font(.system(size: 16)).foregroundColor(.secondary)
                        Text("Record your prayers, reflections and moments with God.")
                            .font(.system(size: 14)).foregroundColor(.secondary)
                            .multilineTextAlignment(.center).padding(.horizontal, 40)
                        Button(action: { showNew = true }) {
                            Text("Write your first entry")
                                .font(.system(size: 15, weight: .medium)).foregroundColor(.white)
                                .padding(.horizontal, 24).padding(.vertical, 12)
                                .background(Color.accent).cornerRadius(12)
                        }
                    }.frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(entries) { entry in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    if let mood = entry.mood,
                                       let m = moods.first(where: { $0.0 == mood }) {
                                        Text(m.1).font(.system(size: 16))
                                        Text(m.2).font(.system(size: 12, weight: .medium)).foregroundColor(Color.accent)
                                    }
                                    Spacer()
                                    Text(relativeDate(entry.createdAt))
                                        .font(.system(size: 11)).foregroundColor(.secondary)
                                }
                                if let ref = entry.verseReference {
                                    Text(ref).font(.system(size: 12, weight: .medium)).foregroundColor(Color.brand)
                                }
                                Text(entry.content)
                                    .font(.system(size: 14)).foregroundColor(.primary)
                                    .lineLimit(3).lineSpacing(2)
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: deleteEntry)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Prayer Journal")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showNew = true }) {
                        Image(systemName: "square.and.pencil").foregroundColor(Color.accent)
                    }
                }
            }
            .sheet(isPresented: $showNew, onDismiss: { Task { await load() } }) {
                NavigationStack { NewJournalEntryView(moods: moods) }
            }
        }
        .task { await load() }
    }

    func load() async {
        if let r = try? await APIService.shared.request(path: "/api/journal") as JournalListResponse {
            entries = r.entries
        }
        isLoading = false
    }

    func deleteEntry(at offsets: IndexSet) {
        for i in offsets {
            let id = entries[i].id
            Task { try? await APIService.shared.requestVoid(path: "/api/journal/\(id)") }
        }
        entries.remove(atOffsets: offsets)
    }

    func relativeDate(_ str: String) -> String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = fmt.date(from: str) else { return "" }
        let rel = RelativeDateTimeFormatter(); rel.unitsStyle = .abbreviated
        return rel.localizedString(for: date, relativeTo: Date())
    }
}

struct NewJournalEntryView: View {
    let moods: [(String, String, String)]
    @Environment(\.dismiss) var dismiss
    @State private var content = ""
    @State private var selectedMood: String? = nil
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Mood selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(moods, id: \.0) { id, emoji, label in
                            Button(action: { selectedMood = selectedMood == id ? nil : id }) {
                                HStack(spacing: 6) {
                                    Text(emoji)
                                    Text(label).font(.system(size: 13, weight: .medium))
                                        .foregroundColor(selectedMood == id ? Color.accent : .secondary)
                                }
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(selectedMood == id ? Color.accent.opacity(0.1) : Color(.secondarySystemBackground))
                                .cornerRadius(20)
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(selectedMood == id ? Color.accent : Color.clear, lineWidth: 1.5))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                }
                Divider()
                TextEditor(text: $content)
                    .padding(16)
                    .font(.system(size: 16)).lineSpacing(4)
            }
            .navigationTitle("New entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: save) {
                        if isSaving { ProgressView() }
                        else { Text("Save").bold().foregroundColor(Color.accent) }
                    }
                    .disabled(content.isEmpty || isSaving)
                }
            }
        }
    }

    func save() {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isSaving = true
        Task {
            do {
                var body: [String: Any] = ["content": content.trimmingCharacters(in: .whitespacesAndNewlines)]
                if let mood = selectedMood { body["mood"] = mood }
                let _: CreateJournalResponse = try await APIService.shared.request(
                    path: "/api/journal", method: "POST", body: body
                )
                await MainActor.run { dismiss() }
            } catch {
                print("Journal save error: \(error)")
                await MainActor.run { isSaving = false }
            }
        }
    }
}

