import SwiftUI
import Foundation

// MARK: - Scenario
struct Scenario: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var category: ScenarioCategory
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var variants: [ScenarioVariant] = []
    var notes: [ScenarioNote] = []
    var tags: [String] = []
    var isArchived: Bool = false
    var linkedGoalId: UUID? = nil
    var status: ScenarioStatus = .active
    var parameters: ImpactParameters = ImpactParameters()
    var parameterWeights: ParameterWeights = ParameterWeights()
    var reminderDate: Date? = nil
    var hasReminder: Bool = false

    var bestVariantId: UUID? {
        variants.max(by: { $0.totalScore(weights: parameterWeights) < $1.totalScore(weights: parameterWeights) })?.id
    }
}

enum ScenarioCategory: String, Codable, CaseIterable {
    case financial = "financial"
    case career = "career"
    case personal = "personal"
    case health = "health"
    case relationship = "relationship"
    case education = "education"
    case custom = "custom"

    var displayName: String {
        switch self {
        case .financial: return "Financial"
        case .career: return "Career"
        case .personal: return "Personal"
        case .health: return "Health"
        case .relationship: return "Relationship"
        case .education: return "Education"
        case .custom: return "Custom"
        }
    }

    var icon: String {
        switch self {
        case .financial: return "dollarsign.circle.fill"
        case .career: return "briefcase.fill"
        case .personal: return "person.fill"
        case .health: return "heart.fill"
        case .relationship: return "person.2.fill"
        case .education: return "book.fill"
        case .custom: return "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .financial: return .bfmGold
        case .career: return .bfmCyan
        case .personal: return .bfmPurpleLight
        case .health: return .bfmGreen
        case .relationship: return Color(hex: "#EC4899")
        case .education: return Color(hex: "#3B82F6")
        case .custom: return .bfmTextSecondary
        }
    }
}


struct StorageSlot {
    static let inputs = "bfm_inputs"
    static let paths = "bfm_paths"
    static let link = "bfm_link"
    static let mode = "bfm_mode"
    static let started = "bfm_started"
    static let ackYes = "bfm_ack_yes"
    static let ackNo = "bfm_ack_no"
    static let ackTime = "bfm_ack_time"
    static let pushURL = "temp_url"
    static let fcm = "fcm_token"
    static let push = "push_token"
}

enum ScenarioStatus: String, Codable {
    case active = "active"
    case decided = "decided"
    case archived = "archived"

    var displayName: String {
        switch self {
        case .active: return "Active"
        case .decided: return "Decided"
        case .archived: return "Archived"
        }
    }

    var color: Color {
        switch self {
        case .active: return .bfmCyan
        case .decided: return .bfmGreen
        case .archived: return .bfmTextTertiary
        }
    }
}

// MARK: - Variant
struct ScenarioVariant: Identifiable, Codable {
    var id: UUID = UUID()
    var label: String        // A, B, C
    var title: String
    var description: String
    var outcomes: [VariantOutcome] = []
    var money: Double = 0
    var time: Double = 0      // hours
    var stress: Double = 5    // 1-10
    var risk: Double = 5      // 1-10
    var customValue: Double = 0
    var isSelected: Bool = false
    var pros: [String] = []
    var cons: [String] = []

    func totalScore(weights: ParameterWeights) -> Double {
        let moneyScore = normalizeInverse(money, min: 0, max: 100000) * weights.money
        let timeScore = normalizeInverse(time, min: 0, max: 1000) * weights.time
        let stressScore = normalizeInverse(stress, min: 1, max: 10) * weights.stress
        let riskScore = normalizeInverse(risk, min: 1, max: 10) * weights.risk
        return (moneyScore + timeScore + stressScore + riskScore) * 100
    }

    private func normalizeInverse(_ value: Double, min minVal: Double, max maxVal: Double) -> Double {
        let range = maxVal - minVal
        guard range > 0 else { return 0 }
        return 1.0 - min(1.0, max(0.0, (value - minVal) / range))
    }
}

struct VariantOutcome: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var probability: Double = 0.5   // 0-1
    var impact: OutcomeImpact = .neutral
}
struct DestinationRecord {
    var link: String?
    var mode: String?
    var virgin: Bool
    var frozen: Bool
    
    static let zero = DestinationRecord(link: nil, mode: nil, virgin: true, frozen: false)
}

struct AcknowledgementRecord {
    var approved: Bool
    var refused: Bool
    var queriedAt: Date?
    
    static let zero = AcknowledgementRecord(approved: false, refused: false, queriedAt: nil)
    
    var canQueryAgain: Bool {
        guard !approved && !refused else { return false }
        
        if let date = queriedAt {
            let elapsed = Date().timeIntervalSince(date) / 86400
            return elapsed >= 3
        }
        return true
    }
}

enum OutcomeImpact: String, Codable, CaseIterable {
    case veryPositive = "veryPositive"
    case positive = "positive"
    case neutral = "neutral"
    case negative = "negative"
    case veryNegative = "veryNegative"

    var displayName: String {
        switch self {
        case .veryPositive: return "Very Positive"
        case .positive: return "Positive"
        case .neutral: return "Neutral"
        case .negative: return "Negative"
        case .veryNegative: return "Very Negative"
        }
    }

    var color: Color {
        switch self {
        case .veryPositive: return .bfmGreen
        case .positive: return Color(hex: "#6EE7B7")
        case .neutral: return .bfmTextSecondary
        case .negative: return .bfmGold
        case .veryNegative: return .bfmRed
        }
    }

    var icon: String {
        switch self {
        case .veryPositive: return "arrow.up.circle.fill"
        case .positive: return "arrow.up.right.circle.fill"
        case .neutral: return "minus.circle.fill"
        case .negative: return "arrow.down.right.circle.fill"
        case .veryNegative: return "arrow.down.circle.fill"
        }
    }
}

struct AttributionRecord {
    var inputs: [String: String]
    var paths: [String: String]
    
    static let zero = AttributionRecord(inputs: [:], paths: [:])
    
    var hasContent: Bool { !inputs.isEmpty }
    var fromOrganic: Bool { inputs["af_status"] == "Organic" }
}

// MARK: - Impact Parameters
struct ImpactParameters: Codable {
    var money: Double = 0
    var time: Double = 0
    var stress: Double = 5
    var risk: Double = 5
}

struct ParameterWeights: Codable {
    var money: Double = 0.25
    var time: Double = 0.25
    var stress: Double = 0.25
    var risk: Double = 0.25

    mutating func normalize() {
        let total = money + time + stress + risk
        guard total > 0 else { return }
        money /= total
        time /= total
        stress /= total
        risk /= total
    }
}

// MARK: - Note
struct ScenarioNote: Identifiable, Codable {
    var id: UUID = UUID()
    var text: String
    var createdAt: Date = Date()
    var hasPhoto: Bool = false
}

// MARK: - Goal
struct Goal: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var targetDate: Date
    var progress: Double = 0   // 0-1
    var category: ScenarioCategory = .personal
    var linkedScenarioIds: [UUID] = []
    var isCompleted: Bool = false
    var createdAt: Date = Date()
}

// MARK: - Decision History
struct DecisionRecord: Identifiable, Codable {
    var id: UUID = UUID()
    var scenarioTitle: String
    var chosenVariant: String
    var date: Date
    var outcome: DecisionOutcome = .pending
    var satisfactionScore: Int = 0   // 1-5
    var notes: String = ""
    var category: ScenarioCategory
}

enum DecisionOutcome: String, Codable {
    case pending = "pending"
    case success = "success"
    case partial = "partial"
    case failure = "failure"

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .success: return "Success"
        case .partial: return "Partial"
        case .failure: return "Failure"
        }
    }

    var color: Color {
        switch self {
        case .pending: return .bfmGold
        case .success: return .bfmGreen
        case .partial: return Color(hex: "#3B82F6")
        case .failure: return .bfmRed
        }
    }
}

// MARK: - Calculator Models
struct FinancialEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var amount: Double
    var type: EntryType
    var category: String
    var date: Date = Date()
}

enum EntryType: String, Codable {
    case income = "income"
    case expense = "expense"
}

struct TimeEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var task: String
    var hours: Double
    var isCompleted: Bool = false
}

struct RiskEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var probability: Double  // 0-1
    var impact: Double       // 1-10
    var mitigation: String
}

struct CustomFormula: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var variables: [FormulaVariable] = []
    var formula: String = ""
    var result: Double = 0
}

struct FormulaVariable: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var value: Double
}
