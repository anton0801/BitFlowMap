import SwiftUI

// MARK: - Analytics View
struct AnalyticsView: View {
    @EnvironmentObject var scenarioStore: ScenarioStore
    @EnvironmentObject var analyticsStore: AnalyticsStore
    @State private var appeared = false
    @State private var selectedHistoryRecord: DecisionRecord? = nil

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient.bfmBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        Text("Analytics")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(.bfmTextPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)

                        // Pattern badge
                        BFMCard {
                            HStack(spacing: 14) {
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 28))
                                    .foregroundStyle(LinearGradient.bfmCyanGlow)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Your Pattern")
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundColor(.bfmTextSecondary)
                                    Text(analyticsStore.behaviorPattern)
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(.bfmTextPrimary)
                                }
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 20)
                        .opacity(appeared ? 1 : 0)

                        // Stats grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            AnalyticCard(
                                value: "\(Int(analyticsStore.decisionSuccessRate * 100))%",
                                label: "Success Rate",
                                icon: "checkmark.seal.fill",
                                color: .bfmGreen
                            )
                            AnalyticCard(
                                value: String(format: "%.1f", analyticsStore.avgSatisfaction),
                                label: "Avg Satisfaction",
                                icon: "star.fill",
                                color: .bfmGold
                            )
                            AnalyticCard(
                                value: "\(scenarioStore.scenarios.count)",
                                label: "Total Scenarios",
                                icon: "square.stack.3d.up.fill",
                                color: .bfmCyan
                            )
                            AnalyticCard(
                                value: "\(scenarioStore.decisionHistory.count)",
                                label: "Decisions Made",
                                icon: "arrow.triangle.branch",
                                color: .bfmPurpleLight
                            )
                        }
                        .padding(.horizontal, 20)

                        // Weekly activity
                        BFMCard {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Weekly Activity")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(.bfmTextPrimary)

                                HStack(alignment: .bottom, spacing: 8) {
                                    let days = ["M", "T", "W", "T", "F", "S", "S"]
                                    let maxVal = analyticsStore.weeklyActivity.max() ?? 1
                                    ForEach(0..<7, id: \.self) { i in
                                        VStack(spacing: 4) {
                                            Capsule()
                                                .fill(i == 6 ? LinearGradient.bfmCyanGlow : LinearGradient(colors: [Color.bfmSurface], startPoint: .top, endPoint: .bottom))
                                                .frame(
                                                    width: 28,
                                                    height: appeared ? CGFloat(analyticsStore.weeklyActivity[i]) / CGFloat(maxVal) * 80 : 4
                                                )
                                                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(i) * 0.05), value: appeared)
                                            Text(days[i])
                                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                                .foregroundColor(.bfmTextTertiary)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, 20)

                        // Category breakdown
                        if !analyticsStore.categoryBreakdown.isEmpty {
                            BFMCard {
                                VStack(alignment: .leading, spacing: 14) {
                                    Text("By Category")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundColor(.bfmTextPrimary)

                                    let total = analyticsStore.categoryBreakdown.values.reduce(0, +)
                                    ForEach(Array(analyticsStore.categoryBreakdown.keys), id: \.self) { cat in
                                        let count = analyticsStore.categoryBreakdown[cat] ?? 0
                                        let pct = total > 0 ? Double(count) / Double(total) : 0

                                        HStack(spacing: 12) {
                                            Image(systemName: cat.icon)
                                                .font(.system(size: 14))
                                                .foregroundColor(cat.color)
                                                .frame(width: 20)
                                            Text(cat.displayName)
                                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                                .foregroundColor(.bfmTextSecondary)
                                                .frame(width: 90, alignment: .leading)

                                            GeometryReader { geo in
                                                ZStack(alignment: .leading) {
                                                    Capsule().fill(Color.bfmSurface).frame(height: 8)
                                                    Capsule()
                                                        .fill(cat.color.opacity(0.8))
                                                        .frame(width: appeared ? geo.size.width * pct : 0, height: 8)
                                                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: appeared)
                                                }
                                            }
                                            .frame(height: 8)

                                            Text("\(count)")
                                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                                .foregroundColor(.bfmTextSecondary)
                                                .frame(width: 24)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        // Decision History
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Decision History", count: scenarioStore.decisionHistory.count)
                                .padding(.horizontal, 20)

                            if scenarioStore.decisionHistory.isEmpty {
                                Text("No decisions recorded yet.")
                                    .font(.system(size: 14, weight: .regular, design: .rounded))
                                    .foregroundColor(.bfmTextTertiary)
                                    .padding(.horizontal, 20)
                            } else {
                                ForEach(scenarioStore.decisionHistory) { record in
                                    DecisionHistoryDetailRow(
                                        record: record,
                                        onUpdate: { updated in scenarioStore.updateDecisionRecord(updated) }
                                    )
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
        .onAppear {
            analyticsStore.recalculate(scenarios: scenarioStore.scenarios, history: scenarioStore.decisionHistory)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) { appeared = true }
        }
    }
}

struct AnalyticCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        BFMCard(padding: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                Text(value)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundColor(.bfmTextPrimary)
                Text(label)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.bfmTextSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct DecisionHistoryDetailRow: View {
    @State private var record: DecisionRecord
    let onUpdate: (DecisionRecord) -> Void
    @State private var expanded = false

    init(record: DecisionRecord, onUpdate: @escaping (DecisionRecord) -> Void) {
        _record = State(initialValue: record)
        self.onUpdate = onUpdate
    }

    var body: some View {
        BFMCard(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(record.scenarioTitle)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.bfmTextPrimary)
                        Text("→ \(record.chosenVariant)")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(.bfmTextSecondary)
                    }
                    Spacer()
                    TagChip(text: record.outcome.displayName, color: record.outcome.color)
                    Button(action: { withAnimation { expanded.toggle() } }) {
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.bfmTextTertiary)
                    }
                }

                if expanded {
                    Divider().background(Color.bfmTextTertiary.opacity(0.3))

                    // Outcome picker
                    HStack(spacing: 8) {
                        Text("Outcome:")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.bfmTextSecondary)
                        ForEach([DecisionOutcome.pending, .success, .partial, .failure], id: \.rawValue) { outcome in
                            Button(outcome.displayName) {
                                record.outcome = outcome
                                onUpdate(record)
                            }
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(record.outcome == outcome ? .bfmDeepNavy : .bfmTextSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(record.outcome == outcome ? outcome.color : Color.bfmSurface)
                            .cornerRadius(8)
                        }
                    }

                    // Satisfaction stars
                    HStack(spacing: 8) {
                        Text("Rating:")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.bfmTextSecondary)
                        ForEach(1...5, id: \.self) { star in
                            Button(action: {
                                record.satisfactionScore = star
                                onUpdate(record)
                            }) {
                                Image(systemName: star <= record.satisfactionScore ? "star.fill" : "star")
                                    .font(.system(size: 18))
                                    .foregroundColor(.bfmGold)
                            }
                        }
                    }

                    Text(record.date, style: .date)
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundColor(.bfmTextTertiary)
                }
            }
        }
    }
}

// MARK: - Goals View
struct GoalsView: View {
    @EnvironmentObject var goalsStore: GoalsStore
    @EnvironmentObject var scenarioStore: ScenarioStore
    @State private var showCreate = false
    @State private var appeared = false

    var body: some View {
        ZStack {
            LinearGradient.bfmBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Text("Goals")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.bfmTextPrimary)
                    Spacer()
                    Button(action: { showCreate = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(LinearGradient.bfmCyanGlow)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                if goalsStore.goals.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "target")
                            .font(.system(size: 44))
                            .foregroundColor(.bfmTextTertiary)
                        Text("No goals yet")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.bfmTextSecondary)
                        Button("Add First Goal") { showCreate = true }
                            .buttonStyle(BFMPrimaryButton())
                            .frame(maxWidth: 220)
                    }
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(goalsStore.goals) { goal in
                                GoalCard(goal: goal)
                                    .padding(.horizontal, 20)
                            }
                            Spacer().frame(height: 80)
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
        .sheet(isPresented: $showCreate) {
            CreateGoalSheet()
        }
    }
}

struct GoalCard: View {
    @EnvironmentObject var goalsStore: GoalsStore
    @State var goal: Goal
    @State private var editingProgress = false

    var body: some View {
        BFMCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: goal.category.icon)
                        .font(.system(size: 16))
                        .foregroundColor(goal.category.color)
                    Text(goal.title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.bfmTextPrimary)
                    Spacer()
                    if goal.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.bfmGreen)
                    }
                    Button(action: {
                        goalsStore.deleteGoal(id: goal.id)
                    }) {
                        Image(systemName: "trash").font(.system(size: 12)).foregroundColor(.bfmRed.opacity(0.5))
                    }
                }

                if !goal.description.isEmpty {
                    Text(goal.description)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.bfmTextSecondary)
                        .lineLimit(2)
                }

                // Progress bar
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Progress")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.bfmTextTertiary)
                        Spacer()
                        Text("\(Int(goal.progress * 100))%")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.bfmCyan)
                    }
                    Slider(value: Binding(
                        get: { goal.progress },
                        set: { val in
                            goal.progress = val
                            goalsStore.updateProgress(id: goal.id, progress: val)
                        }
                    ), in: 0...1, step: 0.05)
                    .accentColor(.bfmCyan)
                }

                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 11))
                        .foregroundColor(.bfmTextTertiary)
                    Text(goal.targetDate, style: .date)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.bfmTextTertiary)
                    Spacer()
                    TagChip(text: goal.category.displayName, color: goal.category.color)
                }
            }
        }
    }
}

struct CreateGoalSheet: View {
    @EnvironmentObject var goalsStore: GoalsStore
    @Environment(\.presentationMode) var presentationMode
    @State private var title = ""
    @State private var description = ""
    @State private var category: ScenarioCategory = .personal
    @State private var targetDate = Date().addingTimeInterval(30 * 24 * 3600)

    var body: some View {
        ZStack {
            LinearGradient.bfmBackground.ignoresSafeArea()
            VStack(spacing: 20) {
                Text("New Goal")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.bfmTextPrimary)
                    .padding(.top, 24)

                BFMTextField(placeholder: "Goal title", text: $title, icon: "target")
                    .padding(.horizontal, 20)
                BFMTextField(placeholder: "Description (optional)", text: $description, icon: "doc.text")
                    .padding(.horizontal, 20)

                Picker("Category", selection: $category) {
                    ForEach(ScenarioCategory.allCases, id: \.self) { cat in
                        Text(cat.displayName).tag(cat)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal, 20)

                DatePicker("Target Date", selection: $targetDate, displayedComponents: .date)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.bfmTextPrimary)
                    .padding(.horizontal, 20)

                Button("Create Goal") {
                    guard !title.isEmpty else { return }
                    let goal = Goal(title: title, description: description, targetDate: targetDate, category: category)
                    goalsStore.addGoal(goal)
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(BFMPrimaryButton())
                .padding(.horizontal, 20)

                Spacer()
            }
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var notificationsManager: NotificationsManager
    @EnvironmentObject var scenarioStore: ScenarioStore
    @EnvironmentObject var goalsStore: GoalsStore

    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = false
    @AppStorage("dailyReminderEnabled") private var dailyReminderEnabled: Bool = false
    @AppStorage("dailyReminderHour") private var dailyReminderHour: Int = 9
    @AppStorage("showScoreOnCards") private var showScoreOnCards: Bool = true
    @AppStorage("defaultCategory") private var defaultCategoryRaw: String = "personal"
    @State private var showDeleteAlert = false
    @State private var showLogoutAlert = false
    @State private var showClearDataAlert = false
    @State private var notificationSuccess = ""

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient.bfmBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        Text("Settings")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(.bfmTextPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)

                        // Profile section
                        NavigationLink(destination: ProfileView()) {
                            BFMCard(padding: 16) {
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(LinearGradient.bfmCyanGlow)
                                            .frame(width: 52, height: 52)
                                        Text(String(appState.userName.prefix(1)).uppercased())
                                            .font(.system(size: 22, weight: .black, design: .rounded))
                                            .foregroundColor(.bfmDeepNavy)
                                    }
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(appState.userName)
                                            .font(.system(size: 16, weight: .bold, design: .rounded))
                                            .foregroundColor(.bfmTextPrimary)
                                        Text(appState.userEmail)
                                            .font(.system(size: 13, weight: .regular, design: .rounded))
                                            .foregroundColor(.bfmTextSecondary)
                                        if appState.isDemoAccount {
                                            TagChip(text: "Demo Account", color: .bfmGold)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.bfmTextTertiary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)

                        // Appearance
                        SettingsGroup(title: "Appearance") {
                            VStack(spacing: 0) {
                                ForEach(ThemeMode.allCases, id: \.self) { mode in
                                    Button(action: {
                                        withAnimation {
                                            appState.themeMode = mode
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: mode.icon)
                                                .font(.system(size: 16))
                                                .foregroundColor(.bfmCyan)
                                                .frame(width: 28)
                                            Text(mode.displayName)
                                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                                .foregroundColor(.bfmTextPrimary)
                                            Spacer()
                                            if appState.themeMode == mode {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.bfmCyan)
                                            }
                                        }
                                        .padding(.vertical, 12)
                                    }
                                    if mode != .system {
                                        Divider().background(Color.bfmTextTertiary.opacity(0.3))
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // Display
                        SettingsGroup(title: "Display") {
                            SettingsToggle(
                                icon: "chart.bar.fill",
                                label: "Show Scores on Cards",
                                isOn: $showScoreOnCards
                            )
                        }
                        .padding(.horizontal, 20)

                        // Notifications
                        SettingsGroup(title: "Notifications") {
                            VStack(spacing: 0) {
                                SettingsToggle(
                                    icon: "bell.fill",
                                    label: "Enable Notifications",
                                    isOn: Binding(
                                        get: { notificationsEnabled },
                                        set: { val in
                                            if val {
                                                notificationsManager.requestPermission { granted in
                                                    notificationsEnabled = granted
                                                    if !granted {
                                                        notificationSuccess = "Please enable notifications in Settings app."
                                                    }
                                                }
                                            } else {
                                                notificationsEnabled = false
                                                notificationsManager.cancelAllNotifications()
                                            }
                                        }
                                    )
                                )

                                if notificationsEnabled {
                                    Divider().background(Color.bfmTextTertiary.opacity(0.3))
                                    SettingsToggle(
                                        icon: "alarm.fill",
                                        label: "Daily Check-in",
                                        isOn: Binding(
                                            get: { dailyReminderEnabled },
                                            set: { val in
                                                dailyReminderEnabled = val
                                                if val {
                                                    notificationsManager.scheduleDaily(hour: dailyReminderHour, minute: 0)
                                                } else {
                                                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_checkin"])
                                                }
                                            }
                                        )
                                    )

                                    if dailyReminderEnabled {
                                        Divider().background(Color.bfmTextTertiary.opacity(0.3))
                                        HStack {
                                            Image(systemName: "clock.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(.bfmCyan)
                                                .frame(width: 28)
                                            Text("Reminder Hour")
                                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                                .foregroundColor(.bfmTextPrimary)
                                            Spacer()
                                            Picker("Hour", selection: Binding(
                                                get: { dailyReminderHour },
                                                set: { val in
                                                    dailyReminderHour = val
                                                    notificationsManager.scheduleDaily(hour: val, minute: 0)
                                                }
                                            )) {
                                                ForEach([6,7,8,9,10,12,18,20,21], id: \.self) { h in
                                                    Text("\(h):00").tag(h)
                                                }
                                            }
                                            .pickerStyle(.menu)
                                            .foregroundColor(.bfmCyan)
                                        }
                                        .padding(.vertical, 10)
                                    }
                                }

                                if !notificationSuccess.isEmpty {
                                    Text(notificationSuccess)
                                        .font(.system(size: 12, weight: .regular, design: .rounded))
                                        .foregroundColor(.bfmGold)
                                        .padding(.top, 6)
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // Goals shortcut
                        SettingsGroup(title: "Goals") {
                            NavigationLink(destination: GoalsView()) {
                                HStack {
                                    Image(systemName: "target")
                                        .font(.system(size: 16))
                                        .foregroundColor(.bfmGreen)
                                        .frame(width: 28)
                                    Text("Manage Goals")
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .foregroundColor(.bfmTextPrimary)
                                    Spacer()
                                    Text("\(goalsStore.goals.count)")
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .foregroundColor(.bfmTextTertiary)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundColor(.bfmTextTertiary)
                                }
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)

                        // Data management
                        SettingsGroup(title: "Data") {
                            Button(action: { showClearDataAlert = true }) {
                                HStack {
                                    Image(systemName: "trash.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.bfmGold)
                                        .frame(width: 28)
                                    Text("Clear All Data")
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .foregroundColor(.bfmGold)
                                    Spacer()
                                }
                                .padding(.vertical, 12)
                            }
                        }
                        .padding(.horizontal, 20)

                        // Account actions
                        SettingsGroup(title: "Account") {
                            VStack(spacing: 0) {
                                Button(action: { showLogoutAlert = true }) {
                                    HStack {
                                        Image(systemName: "arrow.right.square.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.bfmTextSecondary)
                                            .frame(width: 28)
                                        Text("Log Out")
                                            .font(.system(size: 15, weight: .medium, design: .rounded))
                                            .foregroundColor(.bfmTextPrimary)
                                        Spacer()
                                    }
                                    .padding(.vertical, 12)
                                }
                                Divider().background(Color.bfmTextTertiary.opacity(0.3))
                                Button(action: { showDeleteAlert = true }) {
                                    HStack {
                                        Image(systemName: "person.crop.circle.badge.minus")
                                            .font(.system(size: 14))
                                            .foregroundColor(.bfmRed)
                                            .frame(width: 28)
                                        Text("Delete Account")
                                            .font(.system(size: 15, weight: .medium, design: .rounded))
                                            .foregroundColor(.bfmRed)
                                        Spacer()
                                    }
                                    .padding(.vertical, 12)
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        Text("Bit Flow Map v1.0.0")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(.bfmTextTertiary)
                            .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .alert("Log Out", isPresented: $showLogoutAlert) {
                Button("Log Out", role: .destructive) { appState.logout() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to log out?")
            }
            .alert("Delete Account", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) { appState.deleteAccount() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete your account and all data. This cannot be undone.")
            }
            .alert("Clear All Data", isPresented: $showClearDataAlert) {
                Button("Clear", role: .destructive) {
                    scenarioStore.scenarios = []
                    scenarioStore.decisionHistory = []
                    scenarioStore.save()
                    goalsStore.goals = []
                    goalsStore.save()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will delete all scenarios, decisions, and goals.")
            }
        }
    }
}

struct SettingsGroup<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.bfmTextTertiary)
                .tracking(1.5)
                .padding(.leading, 4)

            BFMCard(padding: 16) {
                content
            }
        }
    }
}

struct SettingsToggle: View {
    let icon: String
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.bfmCyan)
                .frame(width: 28)
            Text(label)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.bfmTextPrimary)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.bfmCyan)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var scenarioStore: ScenarioStore
    @EnvironmentObject var analyticsStore: AnalyticsStore
    @State private var editingName = false
    @State private var newName = ""

    var body: some View {
        ZStack {
            LinearGradient.bfmBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Avatar
                    ZStack {
                        GlowCircle(color: .bfmCyan, size: 160, opacity: 0.12)
                        Circle()
                            .fill(LinearGradient.bfmCyanGlow)
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text(String(appState.userName.prefix(1)).uppercased())
                                    .font(.system(size: 40, weight: .black, design: .rounded))
                                    .foregroundColor(.bfmDeepNavy)
                            )
                    }
                    .padding(.top, 20)

                    // Name + edit
                    if editingName {
                        HStack(spacing: 10) {
                            BFMTextField(placeholder: "Your name", text: $newName, icon: "person")
                            Button("Save") {
                                if !newName.isEmpty {
                                    appState.userName = newName
                                }
                                editingName = false
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.bfmCyan)
                        }
                        .padding(.horizontal, 40)
                    } else {
                        HStack(spacing: 8) {
                            Text(appState.userName)
                                .font(.system(size: 22, weight: .black, design: .rounded))
                                .foregroundColor(.bfmTextPrimary)
                            Button(action: { newName = appState.userName; editingName = true }) {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.bfmCyan.opacity(0.7))
                            }
                        }
                    }

                    Text(appState.userEmail)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.bfmTextSecondary)

                    if appState.isDemoAccount {
                        TagChip(text: "Demo Account", color: .bfmGold)
                    }

                    // Stats
                    HStack(spacing: 12) {
                        ProfileStat(value: "\(scenarioStore.scenarios.count)", label: "Scenarios", color: .bfmCyan)
                        ProfileStat(value: "\(scenarioStore.decisionHistory.count)", label: "Decisions", color: .bfmGreen)
                        ProfileStat(value: "\(Int(analyticsStore.decisionSuccessRate * 100))%", label: "Success", color: .bfmGold)
                    }
                    .padding(.horizontal, 20)

                    // Pattern
                    BFMCard {
                        HStack(spacing: 14) {
                            Image(systemName: "brain")
                                .font(.system(size: 24))
                                .foregroundStyle(LinearGradient.bfmCyanGlow)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Decision Style")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundColor(.bfmTextSecondary)
                                Text(analyticsStore.behaviorPattern)
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .foregroundColor(.bfmTextPrimary)
                            }
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 60)
                }
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            analyticsStore.recalculate(scenarios: scenarioStore.scenarios, history: scenarioStore.decisionHistory)
        }
    }
}

struct ProfileStat: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        BFMCard(padding: 14) {
            VStack(spacing: 6) {
                Text(value)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(color)
                Text(label)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.bfmTextSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Reminders in ScenarioDetail (shown within scenario)
extension ScenarioDetailView {
    // Called from detail view for reminder management
}

struct ReminderSettingsView: View {
    @EnvironmentObject var notificationsManager: NotificationsManager
    var scenario: Scenario
    @State private var reminderDate = Date().addingTimeInterval(86400 * 7)
    @State private var hasReminder: Bool
    @Environment(\.presentationMode) var presentationMode

    init(scenario: Scenario) {
        self.scenario = scenario
        _hasReminder = State(initialValue: scenario.hasReminder)
    }

    var body: some View {
        ZStack {
            LinearGradient.bfmBackground.ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Set Reminder")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.bfmTextPrimary)
                    .padding(.top, 24)

                SettingsToggle(icon: "bell.fill", label: "Enable Reminder", isOn: $hasReminder)
                    .padding(.horizontal, 20)

                if hasReminder {
                    DatePicker("Reminder Date", selection: $reminderDate, displayedComponents: [.date, .hourAndMinute])
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.bfmTextPrimary)
                        .padding(.horizontal, 20)

                    Button("Schedule Reminder") {
                        notificationsManager.requestPermission { granted in
                            if granted {
                                notificationsManager.scheduleReviewReminder(for: scenario, date: reminderDate)
                            }
                        }
                        presentationMode.wrappedValue.dismiss()
                    }
                    .buttonStyle(BFMPrimaryButton())
                    .padding(.horizontal, 20)
                } else {
                    Button("Cancel Reminder") {
                        notificationsManager.cancelReminder(for: scenario.id)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .buttonStyle(BFMSecondaryButton())
                    .padding(.horizontal, 20)
                }

                Spacer()
            }
        }
    }
}
