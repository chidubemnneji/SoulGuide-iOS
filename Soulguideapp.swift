import SwiftUI

@main
struct SoulGuideApp: App {
    @StateObject private var auth = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .task { await auth.checkSession() }
        }
    }
}

struct RootView: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        Group {
            if auth.isLoading {
                SplashView()
            } else if !auth.isAuthenticated {
                WelcomeView()
            } else if !auth.isOnboarded {
                NativeOnboardingView(onComplete: {})
                    .environmentObject(auth)
            } else {
                MainTabView()
                    .environmentObject(auth)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: auth.isAuthenticated)
        .animation(.easeInOut(duration: 0.35), value: auth.isOnboarded)
    }
}
