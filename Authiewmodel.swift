import SwiftUI
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = true
    @Published var error: String?

    var isAuthenticated: Bool { user != nil }
    var isOnboarded: Bool { user?.isOnboarded == true }

    func checkSession() async {
        do {
            let r: AuthResponse = try await APIService.shared.request(path: "/api/auth/me")
            if r.success { user = r.user }
        } catch {}
        isLoading = false
    }

    func signup(name: String, email: String, password: String) async -> Bool {
        do {
            let r: AuthResponse = try await APIService.shared.request(
                path: "/api/auth/signup", method: "POST",
                body: ["name": name, "email": email, "password": password]
            )
            if r.success { user = r.user; return true }
            error = r.error ?? "Signup failed"
        } catch { self.error = error.localizedDescription }
        return false
    }

    func login(email: String, password: String) async -> Bool {
        do {
            let r: AuthResponse = try await APIService.shared.request(
                path: "/api/auth/login", method: "POST",
                body: ["email": email, "password": password]
            )
            if r.success { user = r.user; return true }
            error = r.error ?? "Login failed"
        } catch { self.error = error.localizedDescription }
        return false
    }

    func logout() async {
        _ = try? await APIService.shared.request(path: "/api/auth/logout", method: "POST", body: [:]) as AuthResponse
        user = nil
    }

    func refreshUser() async {
        do {
            let r: AuthResponse = try await APIService.shared.request(path: "/api/auth/me")
            if r.success { user = r.user }
        } catch {}
    }
}
