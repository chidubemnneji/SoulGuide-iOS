import SwiftUI
import WebKit
import AVFoundation

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
