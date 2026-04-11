import SwiftUI
import WebKit
import AVFoundation

// MARK: - Native Onboarding
struct NativeOnboardingView: View {
    @EnvironmentObject var auth: AuthViewModel
    var onComplete: () -> Void
    @State private var step = 0
    @State private var selectedStruggle = ""
    @State private var depthAnswers: [String] = []
    @State private var selectedGoals: Set<String> = []
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMsg = ""

    var totalSteps: Int { 4 }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                ForEach(0..<totalSteps, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i <= step ? Color.accent : Color.accent.opacity(0.2))
                        .frame(height: 3)
                }
            }
            .padding(.horizontal, 24).padding(.top, 60).padding(.bottom, 8)

            Text("Step \(step + 1) of \(totalSteps)")
                .font(.system(size: 12)).foregroundColor(.secondary)
                .padding(.bottom, 24)

            if step == 0 { phase1 }
            else if step == 1 { phase2 }
            else if step == 2 { phase3 }
            else { phase4 }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .ignoresSafeArea(edges: .top)
        .animation(.easeInOut(duration: 0.3), value: step)
    }

    // MARK: Phase 1 - Struggle
    var phase1: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What brings you\nhere today?")
                        .font(.custom("Georgia", size: 30)).fontWeight(.bold)
                    Text("Pick the one that feels most true right now.")
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 10) {
                    ForEach([
                        ("distant_from_god", "cloud", "I feel distant from God, prayer feels empty"),
                        ("wrestling_doubts", "questionmark.circle", "I'm wrestling with doubts I can't shake"),
                        ("feel_alone", "person", "I feel alone in my faith journey"),
                        ("guilt_shame", "heart", "I'm carrying guilt or shame I can't let go of"),
                        ("life_overwhelming", "bolt", "Life is overwhelming and my faith is slipping"),
                        ("new_to_faith", "leaf", "I'm new to faith and don't know where to start"),
                    ], id: \.0) { id, icon, label in
                        Button(action: { selectedStruggle = id; depthAnswers = [] }) {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(selectedStruggle == id ? Color.white.opacity(0.2) : Color.brand.opacity(0.08))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: icon)
                                        .foregroundColor(selectedStruggle == id ? .white : Color.brand)
                                        .font(.system(size: 18))
                                }
                                Text(label)
                                    .font(.system(size: 15))
                                    .foregroundColor(selectedStruggle == id ? .white : .primary)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                if selectedStruggle == id {
                                    Image(systemName: "checkmark").foregroundColor(.white).font(.system(size: 13))
                                }
                            }
                            .padding(14)
                            .background(selectedStruggle == id ? Color.brand : Color(.secondarySystemBackground))
                            .cornerRadius(14)
                        }
                        .buttonStyle(.plain)
                    }
                }

                SGButton(title: "Continue", disabled: selectedStruggle.isEmpty) {
                    withAnimation { step = 1 }
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: Phase 2 - Depth questions based on struggle
    var phase2: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                let config = depthConfig(for: selectedStruggle)

                VStack(alignment: .leading, spacing: 8) {
                    Text(config.question)
                        .font(.custom("Georgia", size: 26)).fontWeight(.bold)
                    Text(config.subtitle)
                        .foregroundColor(.secondary).font(.system(size: 14))
                }

                VStack(spacing: 10) {
                    ForEach(config.options, id: \.0) { id, label in
                        Button(action: {
                            if depthAnswers.contains(id) {
                                depthAnswers.removeAll { $0 == id }
                            } else if depthAnswers.count < config.maxSelect {
                                depthAnswers.append(id)
                            }
                        }) {
                            HStack {
                                Text(label)
                                    .font(.system(size: 15))
                                    .foregroundColor(depthAnswers.contains(id) ? .white : .primary)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                if depthAnswers.contains(id) {
                                    Image(systemName: "checkmark").foregroundColor(.white)
                                }
                            }
                            .padding(14)
                            .background(depthAnswers.contains(id) ? Color.brand : Color(.secondarySystemBackground))
                            .cornerRadius(14)
                        }
                        .buttonStyle(.plain)
                        .opacity(!depthAnswers.contains(id) && depthAnswers.count >= config.maxSelect ? 0.4 : 1)
                        .disabled(!depthAnswers.contains(id) && depthAnswers.count >= config.maxSelect)
                    }
                }

                HStack(spacing: 12) {
                    Button("Back") { withAnimation { step = 0 } }
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .background(Color(.secondarySystemBackground)).cornerRadius(14)
                        .foregroundColor(.primary)

                    SGButton(title: "Continue", disabled: depthAnswers.isEmpty) {
                        withAnimation { step = 2 }
                    }
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: Phase 3 - Goals
    var phase3: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Three months from now, things have shifted. What does that look like?")
                        .font(.custom("Georgia", size: 26)).fontWeight(.bold)
                    Text("Pick up to 3" + (selectedGoals.isEmpty ? "" : " (\(selectedGoals.count) of 3 selected)"))
                        .foregroundColor(.secondary).font(.system(size: 14))
                }

                VStack(spacing: 10) {
                    ForEach([
                        ("gods_presence", "I feel God's presence in my daily life"),
                        ("doubts_controlled", "My doubts don't control me anymore"),
                        ("prayer_meaningful", "Prayer actually means something to me"),
                        ("free_from_guilt", "I'm free from the guilt I've been carrying"),
                        ("faith_steady", "My faith is steady, not up and down"),
                        ("understand_bible", "I understand the Bible in a way that matters"),
                        ("peace_not_anxiety", "I wake up with peace instead of anxiety"),
                        ("friends_understand", "I have friends who understand my journey"),
                    ], id: \.0) { id, label in
                        Button(action: {
                            if selectedGoals.contains(id) { selectedGoals.remove(id) }
                            else if selectedGoals.count < 3 { selectedGoals.insert(id) }
                        }) {
                            HStack {
                                Text(label).font(.system(size: 15))
                                    .foregroundColor(selectedGoals.contains(id) ? .white : .primary)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                if selectedGoals.contains(id) {
                                    Image(systemName: "checkmark").foregroundColor(.white)
                                }
                            }
                            .padding(14)
                            .background(selectedGoals.contains(id) ? Color.brand : Color(.secondarySystemBackground))
                            .cornerRadius(14)
                        }
                        .buttonStyle(.plain)
                        .opacity(!selectedGoals.contains(id) && selectedGoals.count >= 3 ? 0.4 : 1)
                        .disabled(!selectedGoals.contains(id) && selectedGoals.count >= 3)
                    }
                }

                HStack(spacing: 12) {
                    Button("Back") { withAnimation { step = 1 } }
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .background(Color(.secondarySystemBackground)).cornerRadius(14)
                        .foregroundColor(.primary)

                    SGButton(title: "Continue", disabled: selectedGoals.isEmpty) {
                        withAnimation { step = 3 }
                    }
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: Phase 4 - Signup
    var phase4: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(name.isEmpty ? "One last thing." : "Almost there, \(name.components(separatedBy: " ").first ?? name).")
                        .font(.custom("Georgia", size: 30)).fontWeight(.bold)
                    Text("Create your account to save your journey.")
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 12) {
                    SGField("Your name", text: $name)
                    SGField("Email address", text: $email, keyboard: .emailAddress, caps: false)
                    SGSecureField("Create a password", text: $password)
                    if !password.isEmpty {
                        PasswordStrength(password: password)
                    }
                }

                if !errorMsg.isEmpty {
                    Text(errorMsg).font(.system(size: 14)).foregroundColor(.red)
                        .padding(12).background(Color.red.opacity(0.08)).cornerRadius(10)
                }

                Text("By continuing you agree to our Terms of Service and Privacy Policy.")
                    .font(.system(size: 12)).foregroundColor(.secondary).multilineTextAlignment(.center)

                HStack(spacing: 12) {
                    Button("Back") { withAnimation { step = 2 } }
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .background(Color(.secondarySystemBackground)).cornerRadius(14)
                        .foregroundColor(.primary)

                    SGButton(title: "Start my journey", isLoading: isLoading,
                             disabled: name.isEmpty || email.isEmpty || password.count < 8) {
                        createAndComplete()
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: Actions
    func createAndComplete() {
        isLoading = true; errorMsg = ""
        Task {
            let ok = await auth.signup(name: name, email: email, password: password)
            if ok {
                do {
                    let body: [String: Any] = [
                        "primaryStruggle": selectedStruggle,
                        "transformationGoals": Array(selectedGoals) as [Any],
                    ]
                    let _: OnboardingResponse = try await APIService.shared.request(
                        path: "/api/onboarding",
                        method: "POST",
                        body: body
                    )
                    // Don't refreshUser here — PostOnboardingView will do it
                    // after the transition screens, so isOnboarded stays false
                    // and we can show the transition flow first
                    await MainActor.run {
                        isLoading = false
                        onComplete()
                    }
                } catch {
                    print("Onboarding error: \(error)")
                    await MainActor.run { isLoading = false }
                }
            } else {
                await MainActor.run {
                    errorMsg = auth.error ?? "Something went wrong"
                    isLoading = false
                }
            }
        }
    }

    // MARK: Depth config
    struct DepthConfig {
        let question: String
        let subtitle: String
        let options: [(String, String)]
        let maxSelect: Int
    }

    func depthConfig(for struggle: String) -> DepthConfig {
        switch struggle {
        case "distant_from_god":
            return DepthConfig(
                question: "When you pray or worship, what does it feel like?",
                subtitle: "Select 1-2 that resonate",
                options: [
                    ("empty_room", "Like talking to an empty room"),
                    ("rushed_mechanical", "Rushed and mechanical, just going through motions"),
                    ("fades_quickly", "I feel something but it fades quickly"),
                    ("dont_know_how", "I want to connect but don't know how"),
                ],
                maxSelect: 2
            )
        case "wrestling_doubts":
            return DepthConfig(
                question: "What kind of doubts are you wrestling with?",
                subtitle: "Select all that apply",
                options: [
                    ("intellectual", "Intellectual — I have questions I can't answer"),
                    ("emotional", "Emotional — my heart doesn't feel what I think it should"),
                    ("experiential", "Experiential — I haven't seen God work in my life"),
                    ("triggered_by_life", "Triggered by life events that shook my faith"),
                ],
                maxSelect: 2
            )
        case "feel_alone":
            return DepthConfig(
                question: "What does feeling alone in faith look like for you?",
                subtitle: "Pick the closest",
                options: [
                    ("no_community", "I don't have a faith community or church"),
                    ("community_not_connect", "I'm in a community but don't feel connected"),
                    ("different_from_others", "I feel different from other believers around me"),
                    ("hide_real_self", "I hide my real struggles from others"),
                ],
                maxSelect: 1
            )
        case "guilt_shame":
            return DepthConfig(
                question: "Where is the guilt or shame coming from?",
                subtitle: "Pick the closest",
                options: [
                    ("past_actions", "Past actions I regret deeply"),
                    ("ongoing_struggles", "Ongoing struggles I can't seem to overcome"),
                    ("not_good_enough", "A general sense that I'm not good enough"),
                    ("failing_others", "Failing the people I love or letting them down"),
                ],
                maxSelect: 1
            )
        case "life_overwhelming":
            return DepthConfig(
                question: "What's making life feel overwhelming right now?",
                subtitle: "Select all that apply",
                options: [
                    ("work_career", "Work or career demands"),
                    ("family_responsibilities", "Family responsibilities"),
                    ("health_challenges", "Health challenges (mine or loved ones)"),
                    ("financial_stress", "Financial stress"),
                    ("relationship_issues", "Relationship issues"),
                ],
                maxSelect: 3
            )
        default: // new_to_faith
            return DepthConfig(
                question: "How would you describe where you're starting from?",
                subtitle: "Pick the closest",
                options: [
                    ("completely_new", "Completely new — I'm just starting to explore"),
                    ("grew_up_away", "I grew up around faith but stepped away"),
                    ("returning_after_break", "Returning after a long break"),
                    ("different_background", "Coming from a different spiritual background"),
                ],
                maxSelect: 1
            )
        }
    }
}

// MARK: - Password Strength
struct PasswordStrength: View {
    let password: String

    var strength: (label: String, color: Color, width: CGFloat) {
        let hasLength = password.count >= 8
        let hasUpper = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        let score = [hasLength, hasUpper, hasNumber].filter { $0 }.count
        switch score {
        case 0, 1: return ("Weak", .red, 0.33)
        case 2: return ("Fair", .orange, 0.66)
        default: return ("Strong", .green, 1.0)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(Color(.systemGray5)).frame(height: 4)
                    RoundedRectangle(cornerRadius: 2).fill(strength.color)
                        .frame(width: geo.size.width * strength.width, height: 4)
                        .animation(.easeInOut, value: strength.width)
                }
            }.frame(height: 4)
            Text(strength.label).font(.system(size: 12)).foregroundColor(strength.color)
        }
    }
}

