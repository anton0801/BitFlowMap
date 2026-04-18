import SwiftUI

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var scenarioStore: ScenarioStore
    @EnvironmentObject var analyticsStore: AnalyticsStore
    @State private var selectedTab: Int = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tag(0)
                ScenarioListView()
                    .tag(1)
                CalculatorsView()
                    .tag(2)
                AnalyticsView()
                    .tag(3)
                SettingsView()
                    .tag(4)
            }
            .onChange(of: selectedTab) { _ in
                analyticsStore.recalculate(scenarios: scenarioStore.scenarios, history: scenarioStore.decisionHistory)
            }

            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int

    let tabs: [(icon: String, label: String)] = [
        ("house.fill", "Home"),
        ("arrow.triangle.branch", "Scenarios"),
        ("function", "Calculate"),
        ("chart.bar.fill", "Analytics"),
        ("gearshape.fill", "Settings")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { i in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = i
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tabs[i].icon)
                            .font(.system(size: selectedTab == i ? 22 : 20, weight: .medium))
                            .foregroundColor(selectedTab == i ? .bfmCyan : .bfmTextTertiary)
                            .scaleEffect(selectedTab == i ? 1.1 : 1.0)

                        Text(tabs[i].label)
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundColor(selectedTab == i ? .bfmCyan : .bfmTextTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                    .padding(.bottom, 4)
                }
            }
        }
        .padding(.bottom, 20)
        .background(
            Rectangle()
                .fill(Color.bfmMidnight)
                .overlay(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.bfmCyan.opacity(0.15), Color.clear],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .frame(height: 1),
                    alignment: .top
                )
        )
        .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: -5)
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var scenarioStore: ScenarioStore
    @EnvironmentObject var analyticsStore: AnalyticsStore
    @State private var appeared = false
    @State private var showCreateScenario = false

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient.bfmBackground.ignoresSafeArea()
                GlowCircle(color: .bfmCyan, size: 300, opacity: 0.05).offset(x: 120, y: -80)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Hello, \(appState.userName) 👋")
                                    .font(.system(size: 24, weight: .black, design: .rounded))
                                    .foregroundColor(.bfmTextPrimary)
                                Text("What will you decide today?")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.bfmTextSecondary)
                            }
                            Spacer()
                            if appState.isDemoAccount {
                                TagChip(text: "DEMO", color: .bfmGold)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                        // Stats Row
                        HStack(spacing: 12) {
                            StatCard(
                                value: "\(scenarioStore.activeScenarios.count)",
                                label: "Active",
                                icon: "circle.fill",
                                color: .bfmCyan
                            )
                            StatCard(
                                value: "\(scenarioStore.decidedScenarios.count)",
                                label: "Decided",
                                icon: "checkmark.circle.fill",
                                color: .bfmGreen
                            )
                            StatCard(
                                value: "\(scenarioStore.scenarios.count)",
                                label: "Total",
                                icon: "square.stack.fill",
                                color: .bfmPurpleLight
                            )
                        }
                        .padding(.horizontal, 20)

                        // Quick Start
                        BFMCard {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Quick Start")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(.bfmTextSecondary)
                                    .textCase(.uppercase)
                                    .tracking(1)

                                Button(action: { showCreateScenario = true }) {
                                    HStack(spacing: 14) {
                                        ZStack {
                                            Circle()
                                                .fill(LinearGradient.bfmCyanGlow)
                                                .frame(width: 44, height: 44)
                                            Image(systemName: "plus")
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(.bfmDeepNavy)
                                        }
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text("New Scenario")
                                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                                .foregroundColor(.bfmTextPrimary)
                                            Text("Start mapping a decision")
                                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                                .foregroundColor(.bfmTextSecondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(.bfmTextTertiary)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .scaleEffect(appeared ? 1 : 0.95)
                        .opacity(appeared ? 1 : 0)

                        // Active Scenarios
                        if !scenarioStore.activeScenarios.isEmpty {
                            VStack(alignment: .leading, spacing: 14) {
                                SectionHeader(title: "Active Scenarios", count: scenarioStore.activeScenarios.count)
                                    .padding(.horizontal, 20)

                                ForEach(scenarioStore.activeScenarios.prefix(3)) { scenario in
                                    NavigationLink(destination: ScenarioDetailView(scenario: scenario)) {
                                        ScenarioRowCard(scenario: scenario)
                                    }
                                    .padding(.horizontal, 20)
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // Recent Decisions
                        if !scenarioStore.decisionHistory.isEmpty {
                            VStack(alignment: .leading, spacing: 14) {
                                SectionHeader(title: "Recent Decisions", count: scenarioStore.decisionHistory.count)
                                    .padding(.horizontal, 20)

                                ForEach(scenarioStore.decisionHistory.prefix(3)) { record in
                                    DecisionHistoryRow(record: record)
                                        .padding(.horizontal, 20)
                                }
                            }
                        }

                        Spacer().frame(height: 80)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showCreateScenario) {
            CreateScenarioView()
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) {
                appeared = true
            }
            analyticsStore.recalculate(scenarios: scenarioStore.scenarios, history: scenarioStore.decisionHistory)
        }
    }
}

// MARK: - Components

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        BFMCard(padding: 14, cornerRadius: 16) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                Text(value)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(.bfmTextPrimary)
                Text(label)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.bfmTextSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct SectionHeader: View {
    let title: String
    var count: Int = 0

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(.bfmTextPrimary)
            Spacer()
            if count > 0 {
                Text("\(count)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.bfmTextTertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.bfmSurface)
                    .cornerRadius(8)
            }
        }
    }
}

struct ScenarioRowCard: View {
    let scenario: Scenario

    var body: some View {
        BFMCard(padding: 16, cornerRadius: 18) {
            HStack(spacing: 14) {
                // Category icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(scenario.category.color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: scenario.category.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(scenario.category.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(scenario.title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.bfmTextPrimary)
                        .lineLimit(1)
                    Text("\(scenario.variants.count) variant\(scenario.variants.count != 1 ? "s" : "") · \(scenario.category.displayName)")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.bfmTextSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    TagChip(text: scenario.status.displayName, color: scenario.status.color)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.bfmTextTertiary)
                }
            }
        }
    }
}

struct DecisionHistoryRow: View {
    let record: DecisionRecord

    var body: some View {
        BFMCard(padding: 14, cornerRadius: 16) {
            HStack(spacing: 12) {
                Circle()
                    .fill(record.outcome.color.opacity(0.2))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: record.outcome == .pending ? "clock.fill" : record.outcome == .success ? "checkmark" : "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(record.outcome.color)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(record.scenarioTitle)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.bfmTextPrimary)
                        .lineLimit(1)
                    Text("Chose: \(record.chosenVariant)")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.bfmTextSecondary)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    TagChip(text: record.outcome.displayName, color: record.outcome.color)
                    Text(record.date, style: .date)
                        .font(.system(size: 10, weight: .regular, design: .rounded))
                        .foregroundColor(.bfmTextTertiary)
                }
            }
        }
    }
}
