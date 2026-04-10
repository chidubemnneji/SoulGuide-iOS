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
    @State private var showTransition = false

    var body: some View {
        Group {
            if auth.isLoading {
                SplashView()
            } else if !auth.isAuthenticated {
                WelcomeView()
            } else if showTransition {
                // Show transition screens after onboarding, before entering main app
                PostOnboardingView(onComplete: {
                    showTransition = false
                })
                .environmentObject(auth)
            } else if !auth.isOnboarded {
                NativeOnboardingView(onComplete: {
                    showTransition = true
                })
                .environmentObject(auth)
            } else {
                MainTabView()
                    .environmentObject(auth)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: auth.isAuthenticated)
        .animation(.easeInOut(duration: 0.35), value: auth.isOnboarded)
        .animation(.easeInOut(duration: 0.35), value: showTransition)
    }
}
