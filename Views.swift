import SwiftUI
import WebKit
import AVFoundation

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (r, g, b) = (1, 1, 1)
        }
        self.init(red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255)
    }
    static let brand = Color(hex: "7C6AC7")
    static let gold = Color(hex: "C8A96E")
}

// MARK: - Splash
struct SplashView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 16) {
                FlameLogo(size: 64)
                Text("SoulGuide")
                    .font(.custom("Georgia", size: 28))
                    .fontWeight(.semibold)
            }
        }
    }
}

// MARK: - Flame Logo
struct FlameLogo: View {
    let size: CGFloat
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.25)
                .fill(Color.brand)
                .frame(width: size, height: size)
            Image(systemName: "flame.fill")
                .resizable().scaledToFit()
                .frame(width: size * 0.45, height: size * 0.55)
                .foregroundColor(.white)
        }
    }
}

// MARK: - Welcome
struct WelcomeView: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                // Logo + wordmark
                HStack(spacing: 10) {
                    FlameLogo(size: 44)
                    (Text("Soul").foregroundColor(.primary) + Text("Guide").foregroundColor(Color(hex: "C8A96E")))
                        .font(.custom("Georgia", size: 22)).fontWeight(.bold)
                }
                .padding(.top, 60)

                VStack(alignment: .leading, spacing: 12) {
                    Text("A companion\nfor your faith.")
                        .font(.custom("Georgia", size: 40))
                        .fontWeight(.bold)
                        .lineSpacing(4)
                        .padding(.top, 32)
                    Text("Wherever you are on your journey, doubting, searching, or simply tired, you don't have to walk it alone.")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .lineSpacing(3)
                }

                VStack(spacing: 10) {
                    FeatureRow(icon: "bubble.left.fill", title: "AI companion", subtitle: "Listens without judgment")
                    FeatureRow(icon: "book.fill", title: "Scripture", subtitle: "Matched to your moment")
                    FeatureRow(icon: "sparkles", title: "Personalised", subtitle: "Grows with you over time")
                }.padding(.top, 28)

                Spacer()

                VStack(spacing: 12) {
                    NavigationLink(destination: NativeOnboardingView(onComplete: {}).environmentObject(auth)) {
                        Text("Get started")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity).frame(height: 56)
                            .background(Color(hex: "C8A96E"))
                            .cornerRadius(16)
                    }
                    NavigationLink(destination: LoginView().environmentObject(auth)) {
                        Text("I already have an account")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity).frame(height: 44)
                    }
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
        }
    }
}

struct FeatureRow: View {
    let icon: String; let title: String; let subtitle: String
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "C8A96E").opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .foregroundColor(Color(hex: "C8A96E"))
                    .font(.system(size: 18))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 15, weight: .semibold))
                Text(subtitle).font(.system(size: 13)).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }
}

// MARK: - Signup
struct SignupView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMsg = ""

    var formValid: Bool { !name.isEmpty && !email.isEmpty && password.count >= 6 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Create your account.")
                        .font(.custom("Georgia", size: 32)).fontWeight(.bold)
                    Text("Let's get you set up.")
                        .foregroundColor(.secondary)
                }.padding(.top, 16)

                VStack(spacing: 12) {
                    SGField("Your name", text: $name)
                    SGField("Email address", text: $email, keyboard: .emailAddress, caps: false)
                    SGSecureField("Password (6+ characters)", text: $password)
                }

                if !errorMsg.isEmpty {
                    Text(errorMsg).font(.system(size: 14)).foregroundColor(.red)
                        .padding(12).background(Color.red.opacity(0.08)).cornerRadius(10)
                }

                SGButton(title: "Create Account", isLoading: isLoading, disabled: !formValid) {
                    isLoading = true; errorMsg = ""
                    Task {
                        let ok = await auth.signup(name: name, email: email, password: password)
                        await MainActor.run {
                            isLoading = false
                            if !ok { errorMsg = auth.error ?? "Something went wrong" }
                        }
                    }
                }

                Text("By continuing you agree to our Terms and Privacy Policy.")
                    .font(.system(size: 12)).foregroundColor(.secondary).multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 24).padding(.bottom, 32)
        }
        .navigationTitle("").navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Login
struct LoginView: View {
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMsg = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome back.")
                        .font(.custom("Georgia", size: 32)).fontWeight(.bold)
                    Text("Sign in to continue your journey.")
                        .foregroundColor(.secondary)
                }.padding(.top, 16)

                VStack(spacing: 12) {
                    SGField("Email address", text: $email, keyboard: .emailAddress, caps: false)
                    SGSecureField("Password", text: $password)
                }

                if !errorMsg.isEmpty {
                    Text(errorMsg).font(.system(size: 14)).foregroundColor(.red)
                        .padding(12).background(Color.red.opacity(0.08)).cornerRadius(10)
                }

                SGButton(title: "Sign In", isLoading: isLoading, disabled: email.isEmpty || password.isEmpty) {
                    isLoading = true; errorMsg = ""
                    Task {
                        let ok = await auth.login(email: email, password: password)
                        await MainActor.run {
                            isLoading = false
                            if !ok { errorMsg = auth.error ?? "Something went wrong" }
                        }
                    }
                }
            }
            .padding(.horizontal, 24).padding(.bottom, 32)
        }
        .navigationTitle("").navigationBarTitleDisplayMode(.inline)
    }
}

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
                        .fill(i <= step ? Color.gold : Color.gold.opacity(0.2))
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
                    await auth.refreshUser()
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

// MARK: - Post Onboarding Transition
struct PostOnboardingView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var showMeetPartner = false

    var body: some View {
        if showMeetPartner {
            MeetPartnerView()
                .environmentObject(auth)
        } else {
            TransitionWebView(onContinue: {
                withAnimation { showMeetPartner = true }
            })
        }
    }
}

struct TransitionWebView: View {
    var onContinue: () -> Void

    var body: some View {
        TransitionWebViewRepresentable(onContinue: onContinue)
            .ignoresSafeArea()
    }
}

struct TransitionWebViewRepresentable: UIViewRepresentable {
    var onContinue: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onContinue: onContinue) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.default()
        config.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.bounces = false

        guard let url = URL(string: "https://spirit-guide-ai-production.up.railway.app/transition") else { return webView }
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate {
        var onContinue: () -> Void
        init(onContinue: @escaping () -> Void) { self.onContinue = onContinue }

        func webView(_ webView: WKWebView,
                     decidePolicyFor action: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = action.request.url,
               url.path == "/meet-prayer-partner" {
                decisionHandler(.cancel)
                DispatchQueue.main.async { self.onContinue() }
                return
            }
            decisionHandler(.allow)
        }
    }
}

struct MeetPartnerView: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        MeetPartnerWebViewRepresentable(onStart: {
            Task { await auth.refreshUser() }
        })
        .ignoresSafeArea()
    }
}

struct MeetPartnerWebViewRepresentable: UIViewRepresentable {
    var onStart: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onStart: onStart) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.default()
        config.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.bounces = false

        guard let url = URL(string: "https://spirit-guide-ai-production.up.railway.app/meet-prayer-partner") else { return webView }
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate {
        var onStart: () -> Void
        init(onStart: @escaping () -> Void) { self.onStart = onStart }

        func webView(_ webView: WKWebView,
                     decidePolicyFor action: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = action.request.url,
               url.path.hasPrefix("/chat") {
                decisionHandler(.cancel)
                DispatchQueue.main.async { self.onStart() }
                return
            }
            decisionHandler(.allow)
        }
    }
}
struct MainTabView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .environmentObject(auth)
                .tabItem { Label("Home", systemImage: "house") }.tag(0)
            ChatListView()
                .environmentObject(auth)
                .tabItem { Label("Chat", systemImage: "plus.circle") }.tag(1)
            BibleView()
                .tabItem { Label("Word", systemImage: "book") }.tag(2)
            ProfileView()
                .environmentObject(auth)
                .tabItem { Label("Profile", systemImage: "person") }.tag(3)
        }
        .accentColor(Color.brand)
    }
}

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

    var struggle: String? {
        guard let s = persona?.primaryStruggle else { return nil }
        return STRUGGLE_DISPLAY[s] ?? s
    }

    var tasks: [(id: String, title: String, subtitle: String, duration: String)] {[
        ("soul-checkin", "Soul Check-In", "A personalized reflection based on your journey", "2m"),
        ("gods-message", "God's Message", devotional?.scriptureReference ?? "Today's verse", "1m"),
        ("devotional-prayer", "Daily Devotional & Prayer", devotional?.title ?? "Finding Peace in the Present", "5m"),
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
                                Image(systemName: "flame.fill").font(.system(size: 12)).foregroundColor(Color.gold)
                                Text("\(streak) day streak").font(.system(size: 13, weight: .semibold)).foregroundColor(Color.gold)
                            }
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Color.gold.opacity(0.15)).cornerRadius(20)
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
                                RoundedRectangle(cornerRadius: 3).fill(Color.gold)
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
                                if task.id == "soul-checkin" { navigateToChat = true }
                                else { navigateToDevotional = true }
                            }
                        }
                    }

                    // Verse card
                    if let d = devotional, let ref = d.scriptureReference {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 6) {
                                Image(systemName: "book.fill").font(.system(size: 11)).foregroundColor(Color.gold)
                                Text("VERSE OF THE DAY").font(.system(size: 11, weight: .semibold)).foregroundColor(Color.gold)
                            }
                            if let text = d.scriptureText {
                                Text("\u{201C}\(text)\u{201D}")
                                    .font(.custom("Georgia", size: 16)).italic().lineSpacing(3)
                            }
                            Text(ref).font(.system(size: 13, weight: .medium)).foregroundColor(Color.gold)
                        }
                        .padding(16).background(Color(.secondarySystemBackground)).cornerRadius(16)
                    }
                }
                .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 32)
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToChat) { NativeChatView(conversationId: nil) }
            .navigationDestination(isPresented: $navigateToDevotional) { DevotionalView() }
            .sheet(isPresented: $showNotifications) { NotificationsView() }
        }
        .task { await loadData() }
    }

    func loadData() async {
        if let gr = try? await APIService.shared.request(path: "/api/devotional/greeting") as GreetingResponse {
            greeting = gr.data
        }
        if let dr = try? await APIService.shared.request(path: "/api/devotional/today") as DevotionalResponse {
            devotional = dr.data
            if let c = dr.completedTaskIds { completedTaskIds = Set(c) }
        }
        if let p = try? await APIService.shared.request(path: "/api/persona") as Persona { persona = p }
        if let n = try? await APIService.shared.request(path: "/api/notifications") as NotificationsResponse {
            unreadCount = n.unreadCount
        }
        if let jr = try? await APIService.shared.request(path: "/api/devotional/journey") as JourneyResponse {
            completedDays = jr.data?.compactMap { $0.completedAt }.map { String($0.prefix(10)) } ?? []
        }
    }
}

// MARK: - Week Calendar
struct WeekCalendarView: View {
    let completedDays: [String]
    let joinedAt: String?

    var days: [(letter: String, date: Int, isToday: Bool, isComplete: Bool, isFuture: Bool)] {
        let cal = Calendar.current
        let today = Date()
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        let joinDate = joinedAt.flatMap { fmt.date(from: String($0.prefix(10))) }

        // Get Monday of current week
        var comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        comps.weekday = 2 // Monday
        let weekStart = cal.date(from: comps) ?? today

        let dayLetters = ["M","T","W","T","F","S","S"]

        return (0..<7).map { i in
            let date = cal.date(byAdding: .day, value: i, to: weekStart)!
            let key = fmt.string(from: date)
            let isToday = cal.isDateInToday(date)
            let isFuture = date > today && !isToday
            let isBeforeJoin = joinDate.map { date < $0 } ?? false
            return (
                letter: dayLetters[i],
                date: cal.component(.day, from: date),
                isToday: isToday,
                isComplete: completedDays.contains(key) && !isBeforeJoin,
                isFuture: isFuture || isBeforeJoin
            )
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                VStack(spacing: 6) {
                    Text(day.letter)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(day.isFuture ? Color(.systemGray4) : .secondary)

                    ZStack {
                        Circle()
                            .fill(
                                day.isComplete ? Color.brand.opacity(0.15) :
                                day.isToday ? Color.gold : Color.clear
                            )
                            .frame(width: 36, height: 36)

                        if day.isComplete {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color.brand)
                        } else {
                            Text("\(day.date)")
                                .font(.system(size: 14, weight: day.isToday ? .semibold : .regular))
                                .foregroundColor(
                                    day.isFuture ? Color(.systemGray4) :
                                    day.isToday ? .white : .primary
                                )
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct TaskCard: View {
    let task: (id: String, title: String, subtitle: String, duration: String)
    let isCompleted: Bool
    let action: () -> Void

    var body: some View {
        Button(action: { if !isCompleted { action() } }) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(isCompleted ? Color.gold : Color(.systemGray4), lineWidth: 2)
                        .background(RoundedRectangle(cornerRadius: 8).fill(isCompleted ? Color.gold : Color.clear))
                        .frame(width: 32, height: 32)
                    if isCompleted {
                        Image(systemName: "checkmark").font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                    } else {
                        Text(task.duration).font(.system(size: 9, weight: .semibold)).foregroundColor(.secondary)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title).font(.system(size: 15, weight: .semibold))
                        .strikethrough(isCompleted).foregroundColor(isCompleted ? .secondary : .primary)
                    Text(task.subtitle).font(.system(size: 12)).foregroundColor(.secondary).lineLimit(1)
                }
                Spacer()
                if !isCompleted {
                    Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(.secondary)
                }
            }
            .padding(14)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(14)
            .opacity(isCompleted ? 0.7 : 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Devotional View (WebView)
struct DevotionalView: View {
    var body: some View {
        SGWebView(path: "/devotional")
            .ignoresSafeArea(edges: .bottom)
            .navigationBarTitleDisplayMode(.inline)
    }
}

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
                                .background(Color.gold).cornerRadius(12)
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
    @State private var messages: [Message] = []
    @State private var input = ""
    @State private var isStreaming = false
    @State private var streamingText = ""
    @State private var activeConvId: Int?
    @State private var isRecording = false
    @State private var isTranscribing = false
    @State private var recorder: AVAudioRecorder?
    @State private var audioURL: URL?
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { MessageBubble(message: $0).id($0.id) }
                        if !streamingText.isEmpty {
                            MessageBubble(message: Message(id: -1, role: "assistant", content: streamingText, createdAt: ""))
                                .id("streaming")
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

            Divider()

            HStack(spacing: 10) {
                TextField("Share what's on your heart...", text: $input, axis: .vertical)
                    .lineLimit(1...5)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(Color(.secondarySystemBackground)).cornerRadius(20)
                    .focused($focused)

                // Mic button
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

                // Send button
                Button(action: send) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(input.isEmpty || isStreaming ? Color.secondary : Color.gold)
                        .clipShape(Circle())
                }
                .disabled(input.isEmpty || isStreaming)
            }
            .padding(.horizontal, 12).padding(.vertical, 8).padding(.bottom, 4)
        }
        .navigationTitle("Soul Care").navigationBarTitleDisplayMode(.inline)
        .task { await setup() }
    }

    func handleMic() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
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
        recorder?.stop()
        recorder = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false)

        guard let url = audioURL else { return }
        isTranscribing = true

        Task {
            do {
                let data = try Data(contentsOf: url)
                let base64 = data.base64EncodedString()
                struct TranscribeResponse: Codable { let transcript: String }
                let response: TranscribeResponse = try await APIService.shared.request(
                    path: "/api/voice/transcribe",
                    method: "POST",
                    body: ["audio": base64, "format": "mp4"]
                )
                await MainActor.run {
                    if !response.transcript.isEmpty {
                        input = response.transcript
                    }
                    isTranscribing = false
                }
            } catch {
                await MainActor.run { isTranscribing = false }
            }
        }
    }

    func setup() async {
        if let id = conversationId {
            activeConvId = id
            if let r = try? await APIService.shared.request(path: "/api/conversations/\(id)/messages") as MessagesResponse {
                messages = r.messages
            }
        } else {
            if let r = try? await APIService.shared.request(path: "/api/conversations", method: "POST", body: ["title": "New Conversation", "channel": "general"]) as CreateConversationResponse {
                activeConvId = r.id
            }
        }
    }

    func send() {
        guard let convId = activeConvId, !input.isEmpty, !isStreaming else { return }
        let content = input; input = ""
        messages.append(Message(id: Int.random(in: 100000...999999), role: "user", content: content, createdAt: ""))
        isStreaming = true; streamingText = ""
        Task {
            do {
                for try await chunk in APIService.shared.streamChat(conversationId: convId, content: content) {
                    await MainActor.run { streamingText += chunk }
                }
                await MainActor.run {
                    if !streamingText.isEmpty {
                        messages.append(Message(id: Int.random(in: 100000...999999), role: "assistant", content: streamingText, createdAt: ""))
                        streamingText = ""
                    }
                    isStreaming = false
                }
            } catch {
                await MainActor.run { isStreaming = false }
            }
        }
    }
}

struct MessageBubble: View {
    let message: Message
    var body: some View {
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
    }
}

// MARK: - Bible (WebView)
struct BibleView: View {
    @State private var navigateToChat = false
    @State private var chatPath = ""

    var body: some View {
        NavigationStack {
            BibleWebViewRepresentable(onChatNavigate: { path in
                chatPath = path
                navigateToChat = true
            })
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("Word")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $navigateToChat) {
                NativeChatView(conversationId: nil)
            }
        }
    }
}

struct BibleWebViewRepresentable: UIViewRepresentable {
    var onChatNavigate: (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onChatNavigate: onChatNavigate) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.default()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        config.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.bounces = true

        guard let url = URL(string: "https://spirit-guide-ai-production.up.railway.app/bible?nativeApp=1") else { return webView }
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate {
        var onChatNavigate: (String) -> Void
        init(onChatNavigate: @escaping (String) -> Void) { self.onChatNavigate = onChatNavigate }

        func webView(_ webView: WKWebView,
                     decidePolicyFor action: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = action.request.url,
               url.path.hasPrefix("/chat") {
                decisionHandler(.cancel)
                DispatchQueue.main.async { self.onChatNavigate(url.path) }
                return
            }
            decisionHandler(.allow)
        }
    }
}

// MARK: - Profile
struct ProfileView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var persona: FullPersona?
    @State private var stats: UserStats?
    @State private var showEditJourney = false

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
                VStack(spacing: 16) {

                    // Avatar + name
                    HStack(spacing: 14) {
                        ZStack {
                            Circle().fill(Color.brand.opacity(0.15)).frame(width: 60, height: 60)
                            Text(auth.user?.initials ?? "?")
                                .font(.system(size: 22, weight: .semibold)).foregroundColor(Color.brand)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(auth.user?.name ?? "").font(.system(size: 17, weight: .semibold))
                            Text(auth.user?.email ?? "").font(.system(size: 13)).foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(16).background(Color(.secondarySystemBackground)).cornerRadius(16)

                    // Stats row
                    if let s = stats {
                        HStack(spacing: 0) {
                            StatCell(value: "\(s.conversationCount)", label: "Conversations")
                            Divider().frame(height: 40)
                            StatCell(value: "\(s.currentStreak)", label: "Day streak")
                            Divider().frame(height: 40)
                            StatCell(value: "\(s.longestStreak)", label: "Best streak")
                        }
                        .padding(.vertical, 14)
                        .background(Color(.secondarySystemBackground)).cornerRadius(16)
                    }

                    // Companion card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("YOUR COMPANION").font(.system(size: 11, weight: .medium)).foregroundColor(.secondary)
                            Spacer()
                        }
                        Text(relationalDescription)
                            .font(.system(size: 14)).foregroundColor(.primary).lineSpacing(3)
                    }
                    .padding(16).background(Color(.secondarySystemBackground)).cornerRadius(16)

                    // Journey card
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text("YOUR JOURNEY").font(.system(size: 11, weight: .medium)).foregroundColor(.secondary)
                            Spacer()
                            Button("Edit") { showEditJourney = true }
                                .font(.system(size: 13, weight: .medium)).foregroundColor(Color.gold)
                        }.padding(.bottom, 8)

                        VStack(alignment: .leading, spacing: 0) {
                            if let arch = archetype {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("ARCHETYPE").font(.system(size: 10, weight: .medium)).foregroundColor(.secondary)
                                    Text(arch.name).font(.system(size: 15, weight: .semibold))
                                    Text(arch.description).font(.system(size: 13)).foregroundColor(.secondary)
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
                                            .background(Color.gold.opacity(0.15))
                                            .foregroundColor(Color.gold).cornerRadius(20)
                                    }
                                }.padding(14)
                            }
                        }
                        .background(Color(.secondarySystemBackground)).cornerRadius(16)
                    }

                    // Log out
                    Button(action: { Task { await auth.logout() } }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Log out")
                        }
                        .font(.system(size: 15, weight: .medium)).foregroundColor(.red)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(Color(.secondarySystemBackground)).cornerRadius(16)
                    }

                    Button(action: deleteAccount) {
                        Text("Delete account and all data")
                            .font(.system(size: 12)).foregroundColor(.secondary.opacity(0.5))
                    }
                    .padding(.top, 4).padding(.bottom, 20)
                }
                .padding(.horizontal, 20).padding(.top, 16)
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
        persona = try? await APIService.shared.request(path: "/api/persona")
        stats = try? await APIService.shared.request(path: "/api/user/stats")
    }

    func deleteAccount() {
        Task {
            _ = try? await APIService.shared.request(path: "/api/auth/account", method: "DELETE", body: [:]) as AuthResponse
            await auth.logout()
        }
    }
}

struct StatCell: View {
    let value: String; let label: String
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 22, weight: .bold)).foregroundColor(Color.gold)
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

// MARK: - Notifications
struct NotificationsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var notifications: [AppNotification] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if notifications.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bell.slash").font(.system(size: 40)).foregroundColor(.secondary)
                        Text("Nothing yet").foregroundColor(.secondary)
                    }.frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(notifications) { n in
                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                Circle().fill(Color.brand.opacity(0.1)).frame(width: 36, height: 36)
                                Image(systemName: "sparkles").font(.system(size: 14)).foregroundColor(Color.brand)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(n.title).font(.system(size: 14, weight: .semibold))
                                Text(n.body).font(.system(size: 13)).foregroundColor(.secondary)
                            }
                            Spacer()
                            if n.isUnread { Circle().fill(Color.brand).frame(width: 7, height: 7) }
                        }
                        .padding(.vertical, 4)
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Notifications").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Done") { dismiss() } }
            }
        }
        .task {
            if let r = try? await APIService.shared.request(path: "/api/notifications") as NotificationsResponse {
                notifications = r.notifications
            }
            isLoading = false
        }
    }
}

// MARK: - Shared UI Components
struct SGField: View {
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var caps: Bool = true

    init(_ placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default, caps: Bool = true) {
        self.placeholder = placeholder
        self._text = text
        self.keyboard = keyboard
        self.caps = caps
    }

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(keyboard)
            .autocapitalization(caps ? .words : .none)
            .autocorrectionDisabled()
            .padding(.horizontal, 14).frame(height: 52)
            .background(Color(.secondarySystemBackground)).cornerRadius(14)
    }
}

struct SGSecureField: View {
    let placeholder: String
    @Binding var text: String
    @State private var show = false

    init(_ placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }

    var body: some View {
        HStack {
            if show { TextField(placeholder, text: $text).autocapitalization(.none) }
            else { SecureField(placeholder, text: $text) }
            Button(action: { show.toggle() }) {
                Image(systemName: show ? "eye.slash" : "eye").foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 14).frame(height: 52)
        .background(Color(.secondarySystemBackground)).cornerRadius(14)
    }
}

struct SGButton: View {
    let title: String
    var isLoading: Bool = false
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if isLoading { ProgressView().tint(.white) }
            else {
                Text(title).font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white).frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity).frame(height: 54)
        .background(disabled || isLoading ? Color.gold.opacity(0.4) : Color.gold)
        .cornerRadius(14)
        .disabled(disabled || isLoading)
    }
}

// MARK: - WebView
struct SGWebView: UIViewRepresentable {
    let path: String
    var onNavigate: ((String) -> Void)?

    init(path: String, onNavigate: ((String) -> Void)? = nil) {
        self.path = path
        self.onNavigate = onNavigate
    }

    func makeCoordinator() -> Coordinator { Coordinator(onNavigate: onNavigate) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.default()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        config.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.bounces = true

        guard let url = URL(string: "https://spirit-guide-ai-production.up.railway.app\(path)?nativeApp=1") else { return webView }
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate {
        var onNavigate: ((String) -> Void)?
        init(onNavigate: ((String) -> Void)?) { self.onNavigate = onNavigate }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if let path = webView.url?.path { onNavigate?(path) }
        }
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("WebView error: \(error.localizedDescription)")
        }
    }
}
