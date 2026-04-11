import SwiftUI
import WebKit
import AVFoundation

// MARK: - Profile
struct ProfileView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var persona: FullPersona?
    @State private var stats: UserStats?
    @State private var showEditJourney = false
    @State private var showArchetypeInfo = false

    var struggle: String? {
        guard let s = persona?.primaryStruggle else { return nil }
        return STRUGGLE_DISPLAY[s] ?? s.replacingOccurrences(of: "_", with: " ")
    }
    var archetype: (name: String, description: String)? {
        guard let a = persona?.graceArchetype else { return nil }
        return ARCHETYPE_DISPLAY[a]
    }
    var goals: [String] {
        (persona?.transformationGoals ?? []).map { GOAL_DISPLAY[$0] ?? $0.replacingOccurrences(of: "_", with: " ") }
    }
    var relationalDescription: String {
        let count = stats?.conversationCount ?? 0
        if count == 0 { return "Your journey together is just beginning." }
        if count < 3 { return "You've just started getting to know each other." }
        if count < 8 { return "Your companion is learning your story." }
        if count < 20 { return "Your companion knows where you've been." }
        return "Your companion knows you well."
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {

                    // ── Identity card ──
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(Color.brand.opacity(0.15)).frame(width: 56, height: 56)
                            Text(auth.user?.initials ?? "?")
                                .font(.system(size: 20, weight: .semibold)).foregroundColor(Color.brand)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(auth.user?.name ?? "")
                                .font(.system(size: 16, weight: .semibold)).lineLimit(1)
                            Text(auth.user?.email ?? "")
                                .font(.system(size: 12)).foregroundColor(.secondary).lineLimit(1)
                        }
                        Spacer()
                        // Streak flame
                        VStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 16)).foregroundColor(Color.accent)
                            Text("\(stats?.currentStreak ?? 0)")
                                .font(.system(size: 18, weight: .bold)).foregroundColor(Color.accent)
                            Text("days")
                                .font(.system(size: 10)).foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(Color.accent.opacity(0.08)).cornerRadius(12)
                    }
                    .padding(14)
                    .background(Color(.secondarySystemBackground)).cornerRadius(16)

                    // ── Your Journey ──
                    VStack(alignment: .leading, spacing: 0) {
                        Text("YOUR JOURNEY")
                            .font(.system(size: 11, weight: .medium)).foregroundColor(.secondary)
                            .padding(.bottom, 6)

                        VStack(alignment: .leading, spacing: 0) {
                            if let arch = archetype {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("ARCHETYPE").font(.system(size: 10, weight: .medium)).foregroundColor(.secondary)
                                        Spacer()
                                        Button(showArchetypeInfo ? "Less" : "What's this?") {
                                            withAnimation { showArchetypeInfo.toggle() }
                                        }
                                        .font(.system(size: 11, weight: .medium)).foregroundColor(Color.accent)
                                    }
                                    Text(arch.name).font(.system(size: 15, weight: .semibold))
                                    Text(arch.description).font(.system(size: 13)).foregroundColor(.secondary)
                                    if showArchetypeInfo {
                                        Text(archetypeExplainer(persona?.graceArchetype ?? ""))
                                            .font(.system(size: 12)).foregroundColor(.secondary)
                                            .lineSpacing(3).padding(.top, 4)
                                    }
                                }.padding(14)
                                Divider().padding(.horizontal, 14)
                            }
                            if let s = struggle {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("CURRENT FOCUS").font(.system(size: 10, weight: .medium)).foregroundColor(.secondary)
                                    Text(s).font(.system(size: 15))
                                }.padding(14)
                                Divider().padding(.horizontal, 14)
                            }
                            if !goals.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("GOALS").font(.system(size: 10, weight: .medium)).foregroundColor(.secondary)
                                    FlexWrap(items: goals) { goal in
                                        Text(goal).font(.system(size: 12, weight: .medium))
                                            .padding(.horizontal, 10).padding(.vertical, 5)
                                            .background(Color.brand.opacity(0.08))
                                            .foregroundColor(Color.brand).cornerRadius(20)
                                    }
                                }.padding(14)
                                Divider().padding(.horizontal, 14)
                            }
                            HStack {
                                Text(relationalDescription)
                                    .font(.system(size: 13)).foregroundColor(.secondary).italic()
                                Spacer()
                                Button("Edit →") { showEditJourney = true }
                                    .font(.system(size: 13, weight: .medium)).foregroundColor(Color.accent)
                            }.padding(14)
                        }
                        .background(Color(.secondarySystemBackground)).cornerRadius(16)
                    }

                    // ── Progress ──
                    VStack(alignment: .leading, spacing: 0) {
                        Text("PROGRESS")
                            .font(.system(size: 11, weight: .medium)).foregroundColor(.secondary)
                            .padding(.bottom, 6)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ProgressStatCard(value: "\(stats?.conversationCount ?? 0)", label: "Conversations")
                            ProgressStatCard(value: "\(stats?.messageCount ?? 0)", label: "Messages sent")
                            ProgressStatCard(value: "\(stats?.currentStreak ?? 0)", label: "Current streak")
                            ProgressStatCard(value: "\(stats?.longestStreak ?? 0)", label: "Longest streak")
                        }
                    }

                    // ── Preferences ──
                    VStack(alignment: .leading, spacing: 0) {
                        Text("PREFERENCES")
                            .font(.system(size: 11, weight: .medium)).foregroundColor(.secondary)
                            .padding(.bottom, 6)

                        VStack(spacing: 0) {
                            NavigationLink(destination: JournalView()) {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8).fill(Color.accent.opacity(0.12)).frame(width: 36, height: 36)
                                        Image(systemName: "book").font(.system(size: 15)).foregroundColor(Color.accent)
                                    }
                                    Text("Prayer Journal").font(.system(size: 15)).foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.system(size: 13)).foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 14).padding(.vertical, 12)
                            }
                            .buttonStyle(.plain)
                            Divider().padding(.leading, 54)
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8).fill(Color.accent.opacity(0.12)).frame(width: 36, height: 36)
                                    Image(systemName: "bell").font(.system(size: 15)).foregroundColor(Color.accent)
                                }
                                Text("Daily reminder").font(.system(size: 15))
                                Spacer()
                                Text("Coming soon").font(.system(size: 13)).foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 14).padding(.vertical, 12)
                        }
                        .background(Color(.secondarySystemBackground)).cornerRadius(16)
                    }

                    // ── Log out ──
                    Button(action: { Task { await auth.logout() } }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Log out")
                        }
                        .font(.system(size: 15, weight: .medium)).foregroundColor(.red)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(Color(.secondarySystemBackground)).cornerRadius(16)
                    }

                    VStack(spacing: 12) {
                        Button(action: deleteAccount) {
                            Text("Delete account and all data")
                                .font(.system(size: 12)).foregroundColor(.secondary.opacity(0.5))
                        }
                        HStack(spacing: 12) {
                            Text("Privacy").font(.system(size: 12)).foregroundColor(.secondary)
                            Circle().fill(.secondary.opacity(0.4)).frame(width: 3, height: 3)
                            Text("Terms").font(.system(size: 12)).foregroundColor(.secondary)
                            Circle().fill(.secondary.opacity(0.4)).frame(width: 3, height: 3)
                            Text("Help").font(.system(size: 12)).foregroundColor(.secondary)
                        }
                    }
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 16).padding(.top, 16)
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showEditJourney) {
                NavigationStack {
                    SGWebView(path: "/account")
                        .ignoresSafeArea(edges: .bottom)
                        .navigationTitle("Edit Journey")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") { showEditJourney = false }
                            }
                        }
                }
            }
        }
        .task { await loadData() }
    }

    func loadData() async {
        async let personaReq: FullPersona? = try? APIService.shared.request(path: "/api/persona")
        async let statsReq: UserStats? = try? APIService.shared.request(path: "/api/user/stats")
        let (p, s) = await (personaReq, statsReq)
        persona = p
        stats = s
    }

    func deleteAccount() {
        Task {
            _ = try? await APIService.shared.request(path: "/api/auth/account", method: "DELETE", body: [:]) as AuthResponse
            await auth.logout()
        }
    }

    func archetypeExplainer(_ key: String) -> String {
        let map: [String: String] = [
            "wounded_seeker": "You're carrying pain. Your companion meets you in that honesty rather than rushing you past it.",
            "eager_builder": "You show up consistently and want to grow. Your companion helps you build with intention.",
            "curious_explorer": "Questions drive you. Your companion engages your mind, not just your heart.",
            "returning_prodigal": "You're finding your way back. Your companion doesn't make you earn trust back.",
            "struggling_saint": "You've been faithful but it's hard right now. Your companion sits with you in that tension.",
        ]
        return map[key] ?? ""
    }
}

struct ProgressStatCard: View {
    let value: String; let label: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(.system(size: 28, weight: .bold)).foregroundColor(.primary)
            Text(label).font(.system(size: 12)).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemBackground)).cornerRadius(14)
    }
}

struct PrefRow: View {
    let icon: String; let label: String; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(Color.accent.opacity(0.12)).frame(width: 36, height: 36)
                    Image(systemName: icon).font(.system(size: 15)).foregroundColor(Color.accent)
                }
                Text(label).font(.system(size: 15)).foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 13)).foregroundColor(.secondary)
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}

struct StatCell: View {
    let value: String; let label: String
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 22, weight: .bold)).foregroundColor(Color.accent)
            Text(label).font(.system(size: 11)).foregroundColor(.secondary)
        }.frame(maxWidth: .infinity)
    }
}

struct FlexWrap<Item: Hashable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content
    init(items: [Item], @ViewBuilder content: @escaping (Item) -> Content) {
        self.items = items; self.content = content
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(stride(from: 0, to: items.count, by: 2)), id: \.self) { i in
                HStack(spacing: 6) {
                    content(items[i])
                    if i + 1 < items.count { content(items[i + 1]) }
                }
            }
        }
    }
}

