import SwiftUI
import WebKit
import AVFoundation

// MARK: - Home View
struct HomeView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var greeting: DevotionalGreeting?
    @State private var devotional: Devotional?
    @State private var completedTaskIds: Set<String> = []
    @State private var unreadCount = 0
    @State private var persona: Persona?
    @State private var completedDays: [String] = []
    @State private var showNotifications = false
    @State private var navigateToChat = false
    @State private var navigateToDevotional = false
    @State private var navigateToJournal = false

    var struggle: String? {
        guard let s = persona?.primaryStruggle else { return nil }
        return STRUGGLE_DISPLAY[s] ?? s
    }

    var tasks: [(id: String, title: String, subtitle: String, duration: String)] {[
        ("soul-checkin", "Soul Check-In", "A personalized reflection based on your journey", "2m"),
        ("gods-message", "God's Message", devotional?.scriptureReference ?? "Today's verse", "1m"),
        ("devotional-prayer", "Daily Devotional & Prayer", devotional?.title ?? "Finding Peace in the Present", "5m"),
        ("prayer-journal", "Reflect & Journal", "Record your thoughts and prayers", "3m"),
    ]}

    var progressPercent: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(completedTaskIds.count) / Double(tasks.count)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        ZStack {
                            Circle().fill(Color.brand).frame(width: 38, height: 38)
                            Text(auth.user?.initials ?? "?")
                                .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                        }
                        Spacer()
                        if let streak = greeting?.currentStreak, streak > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill").font(.system(size: 12)).foregroundColor(Color.accent)
                                Text("\(streak) day streak").font(.system(size: 13, weight: .semibold)).foregroundColor(Color.accent)
                            }
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Color.accent.opacity(0.15)).cornerRadius(20)
                        }
                        Spacer()
                        Button(action: { showNotifications = true }) {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "bell").font(.system(size: 20))
                                if unreadCount > 0 {
                                    Circle().fill(.red).frame(width: 8, height: 8).offset(x: 2, y: -2)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }

                    // Title
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today's Journey")
                            .font(.custom("Georgia", size: 26)).fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if let s = struggle {
                            Text(s).font(.system(size: 14)).foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    // Week Calendar
                    WeekCalendarView(completedDays: completedDays, joinedAt: greeting?.joinedAt)

                    // Progress
                    VStack(spacing: 6) {
                        HStack {
                            Text("PROGRESS TODAY").font(.system(size: 11, weight: .semibold)).foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(progressPercent * 100))%").font(.system(size: 11)).foregroundColor(.secondary)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3).fill(Color(.systemGray5)).frame(height: 5)
                                RoundedRectangle(cornerRadius: 3).fill(Color.accent)
                                    .frame(width: geo.size.width * progressPercent, height: 5)
                                    .animation(.easeInOut, value: progressPercent)
                            }
                        }.frame(height: 5)
                    }

                    // Tasks
                    VStack(spacing: 10) {
                        ForEach(tasks, id: \.id) { task in
                            TaskCard(task: task, isCompleted: completedTaskIds.contains(task.id)) {
                                completedTaskIds.insert(task.id)
                                switch task.id {
                                case "soul-checkin": navigateToChat = true
                                case "prayer-journal": navigateToJournal = true
                                default: navigateToDevotional = true
                                }
                            }
                        }
                    }

                    // Verse card
                    if let d = devotional, let ref = d.scriptureReference {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 6) {
                                Image(systemName: "book.fill").font(.system(size: 11)).foregroundColor(Color.accent)
                                Text("VERSE OF THE DAY").font(.system(size: 11, weight: .semibold)).foregroundColor(Color.accent)
                            }
                            if let text = d.scriptureText {
                                Text("\u{201C}\(text)\u{201D}")
                                    .font(.custom("Georgia", size: 16)).italic().lineSpacing(3)
                            }
                            Text(ref).font(.system(size: 13, weight: .medium)).foregroundColor(Color.accent)
                        }
                        .padding(16).background(Color(.secondarySystemBackground)).cornerRadius(16)
                    }

                    // Streak card
                    if let streak = greeting?.currentStreak {
                        StreakCard(streak: streak)
                    }
                }
                .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 32)
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToChat) { NativeChatView(conversationId: nil, openingMode: "checkin") }
            .navigationDestination(isPresented: $navigateToDevotional) { DevotionalView() }
            .navigationDestination(isPresented: $navigateToJournal) { JournalView() }
            .sheet(isPresented: $showNotifications) { NotificationsView() }
        }
        .task { await loadData() }
    }

    func loadData() async {
        async let greetingReq: GreetingResponse? = try? APIService.shared.request(path: "/api/devotional/greeting")
        async let devotionalReq: DevotionalResponse? = try? APIService.shared.request(path: "/api/devotional/today")
        async let personaReq: Persona? = try? APIService.shared.request(path: "/api/persona")
        async let notificationsReq: NotificationsResponse? = try? APIService.shared.request(path: "/api/notifications")
        async let journeyReq: JourneyResponse? = try? APIService.shared.request(path: "/api/devotional/journey")

        let (gr, dr, p, n, jr) = await (greetingReq, devotionalReq, personaReq, notificationsReq, journeyReq)

        if let gr { greeting = gr.data }
        if let dr {
            devotional = dr.data
            if let c = dr.completedTaskIds { completedTaskIds = Set(c) }
        }
        if let p { persona = p }
        if let n { unreadCount = n.unreadCount }
        if let jr { completedDays = jr.data?.compactMap { $0.completedAt }.map { String($0.prefix(10)) } ?? [] }
    }
}

