import SwiftUI

@main
struct BitFlowMapApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            SplashView()
        }
    }
}

struct RootView: View {
    
    @StateObject private var appState = AppState()
    @StateObject private var scenarioStore = ScenarioStore()
    @StateObject private var analyticsStore = AnalyticsStore()
    @StateObject private var goalsStore = GoalsStore()
    @StateObject private var notificationsManager = NotificationsManager()

    var body: some View {
        Group {
            if !appState.hasCompletedOnboarding {
                OnboardingContainerView()
            } else if !appState.isLoggedIn {
                AuthView()
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.4), value: appState.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.4), value: appState.isLoggedIn)
        .environmentObject(appState)
        .environmentObject(scenarioStore)
        .environmentObject(analyticsStore)
        .environmentObject(goalsStore)
        .environmentObject(notificationsManager)
        .preferredColorScheme(appState.colorScheme)
    }
}
