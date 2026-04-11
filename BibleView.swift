import SwiftUI
import WebKit
import AVFoundation

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
        webView.overrideUserInterfaceStyle = .unspecified

        guard let url = URL(string: "https://spirit-guide-ai-production.up.railway.app/bible?nativeApp=1") else { return webView }
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let isDark = UITraitCollection.current.userInterfaceStyle == .dark
        webView.evaluateJavaScript("""
            document.documentElement.classList.toggle('dark', \(isDark));
            document.documentElement.classList.toggle('light', \(!isDark));
        """)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var onChatNavigate: (String) -> Void
        init(onChatNavigate: @escaping (String) -> Void) { self.onChatNavigate = onChatNavigate }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let isDark = UITraitCollection.current.userInterfaceStyle == .dark
            webView.evaluateJavaScript("""
                document.documentElement.classList.toggle('dark', \(isDark));
                document.documentElement.classList.toggle('light', \(!isDark));
            """)
        }

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

