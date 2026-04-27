import Foundation

enum MachineState: Equatable {
    case idle
    case loading
    case validating
    case resolving
    case awaitingConsent
    case ready(url: String)
    case failed(reason: FailureReason)
    
    static func == (lhs: MachineState, rhs: MachineState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.loading, .loading): return true
        case (.validating, .validating): return true
        case (.resolving, .resolving): return true
        case (.awaitingConsent, .awaitingConsent): return true
        case (.ready(let l), .ready(let r)): return l == r
        case (.failed, .failed): return true
        default: return false
        }
    }
}

enum FailureReason {
    case validationDenied
    case endpointMissing
    case noNetwork
    case deadlineHit
}


// MARK: - Snapshot

struct PersistedBundle {
    let inputs: [String: String]
    let paths: [String: String]
    let link: String?
    let mode: String?
    let virgin: Bool
    let approved: Bool
    let refused: Bool
    let queriedAt: Date?
}

// MARK: - Observer Events (Subject → Observer)

enum BitFlowEvent {
    case stateChanged(MachineState)
    case attributionLoaded
    case destinationResolved(String)
    case consentRequested
    case consentGranted
    case consentRefused
    case networkUp
    case networkDown
    case deadlineExpired
}

// MARK: - Errors (typed)

enum BitFlowError: LocalizedError {
    case noAttribution
    case validationFailed
    case endpointDeclined  // 404 или ok:false
    case decodingIssue
    case transportFailure
    case rateLimited
    case timeoutReached
    
    var errorDescription: String? {
        switch self {
        case .noAttribution: return "Attribution data unavailable"
        case .validationFailed: return "Validation rejected"
        case .endpointDeclined: return "Endpoint declined request"
        case .decodingIssue: return "Decoding failed"
        case .transportFailure: return "Network transport failed"
        case .rateLimited: return "Rate limit exceeded"
        case .timeoutReached: return "Operation timed out"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .endpointDeclined: return "Server permanently declined; do not retry"
        case .rateLimited: return "Apply exponential backoff"
        case .transportFailure: return "Check connection and retry"
        default: return nil
        }
    }
}

// MARK: - Constants

struct BitFlowParams {
    static let appNumber = "6762513288"
    static let trackerKey = "Lc2PLXsvoM9AD3BWX8ppJC"
    static let suiteGroup = "group.bitflowmap.shared"
    static let cookieBin = "bitflowmap_crumbs"
    static let backendURL = "https://bitfllowmap.com/config.php"
    static let trace = "🗺️ [BitFlowMap]"
}
