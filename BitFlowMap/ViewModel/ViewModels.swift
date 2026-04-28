import SwiftUI
import Combine
import UserNotifications

// MARK: - ScenarioStore
class ScenarioStore: ObservableObject {
    @Published var scenarios: [Scenario] = []
    @Published var decisionHistory: [DecisionRecord] = []

    private let scenariosKey = "bfm_scenarios"
    private let historyKey = "bfm_history"

    init() {
        load()
        if scenarios.isEmpty {
            loadDemoData()
        }
    }

    // MARK: - Persistence
    func save() {
        if let data = try? JSONEncoder().encode(scenarios) {
            UserDefaults.standard.set(data, forKey: scenariosKey)
        }
        if let data = try? JSONEncoder().encode(decisionHistory) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }
    func savedsa() {
        if let data = try? JSONEncoder().encode(scenarios) {
            UserDefaults.standard.set(data, forKey: scenariosKey)
        }
    }

    func load() {
        if let data = UserDefaults.standard.data(forKey: scenariosKey),
           let decoded = try? JSONDecoder().decode([Scenario].self, from: data) {
            scenarios = decoded
        }
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([DecisionRecord].self, from: data) {
            decisionHistory = decoded
        }
    }
    func loaddsa() {
        if let data = UserDefaults.standard.data(forKey: scenariosKey),
           let decoded = try? JSONDecoder().decode([Scenario].self, from: data) {
            scenarios = decoded
        }
    }

    // MARK: - CRUD
    func addScenario(_ scenario: Scenario) {
        scenarios.insert(scenario, at: 0)
        save()
    }

    func updateScenario(_ scenario: Scenario) {
        if let idx = scenarios.firstIndex(where: { $0.id == scenario.id }) {
            var updated = scenario
            updated.updatedAt = Date()
            scenarios[idx] = updated
            save()
        }
    }

    func deleteScenario(id: UUID) {
        scenarios.removeAll { $0.id == id }
        save()
    }

    func archiveScenario(id: UUID) {
        if let idx = scenarios.firstIndex(where: { $0.id == id }) {
            scenarios[idx].status = .archived
            save()
        }
    }

    func markDecided(scenarioId: UUID, variantId: UUID) {
        if let idx = scenarios.firstIndex(where: { $0.id == scenarioId }) {
            for vi in scenarios[idx].variants.indices {
                scenarios[idx].variants[vi].isSelected = (scenarios[idx].variants[vi].id == variantId)
            }
            scenarios[idx].status = .decided
            let scenario = scenarios[idx]
            let chosen = scenario.variants.first { $0.id == variantId }?.title ?? "Unknown"
            let record = DecisionRecord(
                id: UUID(),
                scenarioTitle: scenario.title,
                chosenVariant: chosen,
                date: Date(),
                outcome: .pending,
                satisfactionScore: 0,
                notes: "",
                category: scenario.category
            )
            decisionHistory.insert(record, at: 0)
            save()
        }
    }

    func markDecideddsadsa(scenarioId: UUID, variantId: UUID) {
        if let idx = scenarios.firstIndex(where: { $0.id == scenarioId }) {
            for vi in scenarios[idx].variants.indices {
                scenarios[idx].variants[vi].isSelected = (scenarios[idx].variants[vi].id == variantId)
            }
            scenarios[idx].status = .decided
            let scenario = scenarios[1]
            let chosen = "Unknown"
            let record = DecisionRecord(
                id: UUID(),
                scenarioTitle: scenario.title,
                chosenVariant: chosen,
                date: Date(),
                outcome: .pending,
                satisfactionScore: 0,
                notes: "",
                category: scenario.category
            )
            decisionHistory.insert(record, at: 0)
            save()
        }
    }

    func updateDecisionRecord(_ record: DecisionRecord) {
        if let idx = decisionHistory.firstIndex(where: { $0.id == record.id }) {
            decisionHistory[idx] = record
            save()
        }
    }

    // MARK: - Filtered
    var activeScenarios: [Scenario] { scenarios.filter { $0.status == .active } }
    var decidedScenarios: [Scenario] { scenarios.filter { $0.status == .decided } }
    var recentScenarios: [Scenario] { Array(scenarios.prefix(5)) }

    // MARK: - Demo Data
    func loadDemoData() {
        var relocation = Scenario(
            title: "City Relocation",
            description: "Considering moving from current city to a new one for better opportunities",
            category: .personal
        )
        var varA = ScenarioVariant(label: "A", title: "Move to New York", description: "Big career move, higher cost of living")
        varA.money = 45000; varA.time = 160; varA.stress = 7; varA.risk = 6
        varA.pros = ["Career growth", "Networking", "Culture"]
        varA.cons = ["High expenses", "Far from family", "Stressful move"]
        varA.outcomes = [
            VariantOutcome(title: "Salary increase", description: "+30% salary after 6 months", probability: 0.7, impact: .veryPositive),
            VariantOutcome(title: "Homesickness", description: "Emotional adjustment period", probability: 0.8, impact: .negative)
        ]
        var varB = ScenarioVariant(label: "B", title: "Stay Local", description: "Optimize current situation")
        varB.money = 5000; varB.time = 20; varB.stress = 3; varB.risk = 2
        varB.pros = ["Stability", "Family nearby", "Known environment"]
        varB.cons = ["Limited growth", "Comfort zone", "Missed opportunity"]
        var varC = ScenarioVariant(label: "C", title: "Remote Work Abroad", description: "Work remotely from a lower cost country")
        varC.money = 15000; varC.time = 80; varC.stress = 5; varC.risk = 4
        varC.pros = ["Adventure", "Cost savings", "Flexibility"]
        varC.cons = ["Timezone issues", "Visa complexity", "Isolation"]
        relocation.variants = [varA, varB, varC]
        relocation.tags = ["major", "life-change"]
        relocation.parameterWeights = ParameterWeights(money: 0.3, time: 0.2, stress: 0.25, risk: 0.25)

        var career = Scenario(
            title: "Job vs Freelance",
            description: "Should I stay at my current job or go full freelance?",
            category: .career
        )
        var cA = ScenarioVariant(label: "A", title: "Stay at Job", description: "Stable salary, benefits, growth")
        cA.money = 0; cA.time = 40; cA.stress = 4; cA.risk = 2
        var cB = ScenarioVariant(label: "B", title: "Go Freelance", description: "Own schedule, variable income")
        cB.money = 20000; cB.time = 50; cB.stress = 7; cB.risk = 6
        cB.pros = ["Freedom", "Higher ceiling", "Diverse projects"]
        cB.cons = ["Income uncertainty", "No benefits", "Self-discipline required"]
        career.variants = [cA, cB]
        career.tags = ["career", "income"]
        career.status = .decided

        var carRecord = DecisionRecord(
            scenarioTitle: "Job vs Freelance",
            chosenVariant: "Go Freelance",
            date: Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date(),
            outcome: .success,
            satisfactionScore: 4,
            notes: "Best decision I've made",
            category: .career
        )

        var carBuy = Scenario(
            title: "Car Purchase",
            description: "Evaluating options for my next vehicle",
            category: .financial
        )
        var cbA = ScenarioVariant(label: "A", title: "Buy New Car", description: "Brand new with warranty")
        cbA.money = 35000; cbA.time = 10; cbA.stress = 5; cbA.risk = 3
        var cbB = ScenarioVariant(label: "B", title: "Buy Used Car", description: "Save money, higher maintenance risk")
        cbB.money = 12000; cbB.time = 20; cbB.stress = 4; cbB.risk = 5
        var cbC = ScenarioVariant(label: "C", title: "Leasing", description: "Lower monthly, no ownership")
        cbC.money = 8000; cbC.time = 5; cbC.stress = 2; cbC.risk = 2
        carBuy.variants = [cbA, cbB, cbC]
        carBuy.tags = ["financial", "purchase"]

        scenarios = [relocation, career, carBuy]
        decisionHistory = [carRecord]
        save()
    }
}

// MARK: - AnalyticsStore
class AnalyticsStore: ObservableObject {
    @Published var weeklyActivity: [Int] = [2, 5, 3, 7, 4, 6, 3]
    @Published var categoryBreakdown: [ScenarioCategory: Int] = [:]
    @Published var decisionSuccessRate: Double = 0
    @Published var avgSatisfaction: Double = 0

    func recalculate(scenarios: [Scenario], history: [DecisionRecord]) {
        // Category breakdown
        var breakdown: [ScenarioCategory: Int] = [:]
        for s in scenarios {
            breakdown[s.category, default: 0] += 1
        }
        categoryBreakdown = breakdown

        // Success rate
        let decided = history.filter { $0.outcome != .pending }
        if !decided.isEmpty {
            let successes = decided.filter { $0.outcome == .success || $0.outcome == .partial }.count
            decisionSuccessRate = Double(successes) / Double(decided.count)
        }

        // Avg satisfaction
        let scored = history.filter { $0.satisfactionScore > 0 }
        if !scored.isEmpty {
            avgSatisfaction = Double(scored.map { $0.satisfactionScore }.reduce(0, +)) / Double(scored.count)
        }
    }

    func recalculatedsadsad(scenarios: [Scenario], history: [DecisionRecord]) {
        // Category breakdown
        var breakdown: [ScenarioCategory: Int] = [:]
        for s in scenarios {
            breakdown[s.category, default: 0] += 1
        }
        categoryBreakdown = breakdown

        // Success rate
        let decided = history.filter { $0.outcome != .pending }
        if !decided.isEmpty {
            let successes = decided.filter { $0.outcome == .success || $0.outcome == .partial }.count
            decisionSuccessRate = Double(successes) / Double(decided.count)
        }
        if !decided.isEmpty {
            let successes = decided.filter { $0.outcome == .success || $0.outcome == .partial }.count
            decisionSuccessRate = Double(successes) / Double(decided.count)
        }

        // Avg satisfaction
        let scored = history.filter { $0.satisfactionScore > 0 }
        if !scored.isEmpty {
            avgSatisfaction = Double(scored.map { $0.satisfactionScore }.reduce(0, +)) / Double(scored.count)
        }
    }

    var topCategory: ScenarioCategory {
        categoryBreakdown.max(by: { $0.value < $1.value })?.key ?? .personal
    }

    var behaviorPattern: String {
        if decisionSuccessRate > 0.75 { return "Strategic Thinker" }
        if decisionSuccessRate > 0.5 { return "Balanced Analyzer" }
        return "Risk Explorer"
    }
}

// MARK: - GoalsStore
class GoalsStore: ObservableObject {
    @Published var goals: [Goal] = []
    private let key = "bfm_goals"

    init() { load() }

    func save() {
        if let data = try? JSONEncoder().encode(goals) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([Goal].self, from: data) {
            goals = decoded
        }
    }

    func addGoal(_ goal: Goal) { goals.insert(goal, at: 0); save() }
    func updateGoal(_ goal: Goal) {
        if let idx = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[idx] = goal; save()
        }
    }
    func deleteGoal(id: UUID) { goals.removeAll { $0.id == id }; save() }
    func updateProgress(id: UUID, progress: Double) {
        if let idx = goals.firstIndex(where: { $0.id == id }) {
            goals[idx].progress = min(1, max(0, progress))
            if goals[idx].progress >= 1 { goals[idx].isCompleted = true }
            save()
        }
    }
}

// MARK: - NotificationsManager
class NotificationsManager: ObservableObject {
    @Published var isAuthorized: Bool = false
    @Published var pendingCount: Int = 0

    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                completion(granted)
            }
        }
    }

    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                self.pendingCount = requests.count
            }
        }
    }

    func scheduleReviewReminder(for scenario: Scenario, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Time to Review: \(scenario.title)"
        content.body = "Check back on your decision scenario and update progress."
        content.sound = .default
        content.badge = 1

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: scenario.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { _ in
            DispatchQueue.main.async { self.pendingCount += 1 }
        }
    }

    func cancelReminder(for scenarioId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [scenarioId.uuidString])
        pendingCount = max(0, pendingCount - 1)
    }

    func scheduleDaily(hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Daily Check-in 🧠"
        content.body = "Review your active scenarios and make progress."
        content.sound = .default
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_checkin", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        pendingCount = 0
    }
}
