import SwiftUI
import WebKit
import AVFoundation

// MARK: - Post Onboarding Transition
struct PostOnboardingView: View {
    @EnvironmentObject var auth: AuthViewModel
    var onComplete: () -> Void = {}
    @State private var showMeetPartner = false
    @State private var showFirstChat = false

    var body: some View {
        NavigationStack {
            ZStack {
                if showFirstChat {
                    NativeChatView(conversationId: nil, openingMode: "first_chat")
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") {
                                    Task {
                                        await auth.refreshUser()
                                        await MainActor.run { onComplete() }
                                    }
                                }
                                .foregroundColor(Color.accent)
                            }
                        }
                } else if showMeetPartner {
                    MeetPartnerWebViewRepresentable(onStart: {
                        withAnimation { showFirstChat = true }
                    })
                    .ignoresSafeArea()
                    .navigationBarHidden(true)
                } else {
                    TransitionWebViewRepresentable(onContinue: {
                        withAnimation { showMeetPartner = true }
                    })
                    .ignoresSafeArea()
                    .navigationBarHidden(true)
                }
            }
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
    var onStart: () -> Void

    var body: some View {
        MeetPartnerWebViewRepresentable(onStart: onStart)
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

