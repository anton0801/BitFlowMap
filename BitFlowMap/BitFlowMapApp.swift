import SwiftUI

@main
struct BitFlowMapApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var scenarioStore = ScenarioStore()
    @StateObject private var analyticsStore = AnalyticsStore()
    @StateObject private var goalsStore = GoalsStore()
    @StateObject private var notificationsManager = NotificationsManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(scenarioStore)
                .environmentObject(analyticsStore)
                .environmentObject(goalsStore)
                .environmentObject(notificationsManager)
                .preferredColorScheme(appState.colorScheme)
        }
    }
}

// MARK: - Root View
struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.isShowingSplash {
                SplashView()
            } else if !appState.hasCompletedOnboarding {
                OnboardingContainerView()
            } else if !appState.isLoggedIn {
                AuthView()
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.4), value: appState.isShowingSplash)
        .animation(.easeInOut(duration: 0.4), value: appState.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.4), value: appState.isLoggedIn)
    }
}
