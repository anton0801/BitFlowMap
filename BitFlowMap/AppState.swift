import SwiftUI
import Combine

class AppState: ObservableObject {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("themeMode") var themeMode: ThemeMode = .system
    @AppStorage("userName") var userName: String = ""
    @AppStorage("userEmail") var userEmail: String = ""
    @AppStorage("isDemoAccount") var isDemoAccount: Bool = false

    @Published var showDeleteAccountAlert: Bool = false

    var colorScheme: ColorScheme? {
        switch themeMode {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }

    init() {
    }

    func loginAsDemo() {
        userName = "Demo User"
        userEmail = "demo@bitflowmap.app"
        isDemoAccount = true
        isLoggedIn = true
    }

    func login(email: String, password: String) -> Bool {
        guard !email.isEmpty, !password.isEmpty else { return false }
        userName = email.components(separatedBy: "@").first?.capitalized ?? "User"
        userEmail = email
        isDemoAccount = false
        isLoggedIn = true
        return true
    }

    func register(name: String, email: String, password: String) -> Bool {
        guard !name.isEmpty, !email.isEmpty, password.count >= 6 else { return false }
        userName = name
        userEmail = email
        isDemoAccount = false
        isLoggedIn = true
        return true
    }

    func logout() {
        isLoggedIn = false
        userName = ""
        userEmail = ""
        isDemoAccount = false
    }

    func deleteAccount() {
        logout()
        hasCompletedOnboarding = false
    }
}

enum ThemeMode: String, CaseIterable, Codable {
    case light = "light"
    case dark = "dark"
    case system = "system"

    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }

    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }
}
