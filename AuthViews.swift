import SwiftUI
import WebKit
import AVFoundation

// MARK: - Welcome
struct WelcomeView: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                // Logo + wordmark
                HStack(spacing: 10) {
                    FlameLogo(size: 44)
                    (Text("Soul").foregroundColor(Color.brand) + Text("Guide").foregroundColor(Color.gold))
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

