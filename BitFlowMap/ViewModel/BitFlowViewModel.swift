import Foundation
import Combine

@MainActor
final class BitFlowViewModel: ObservableObject {
    
    @Published var navigateToMain = false {
        didSet {
            if navigateToMain {
                deadlineTask?.cancel()
                uiLocked = true
            }
        }
    }
    
    @Published var navigateToWeb = false {
        didSet {
            if navigateToWeb {
                deadlineTask?.cancel()
                uiLocked = true
            }
        }
    }
    
    @Published var showPermissionPrompt = false
    @Published var showOfflineView = false
    
    private let machine: FlowMachine
    private let bridge: ObserverBridge
    
    private var deadlineTask: Task<Void, Never>?
    
    private var uiLocked: Bool = false
    
    init() {
        let storage = LayeredStorage()
        let integrity = SupabaseIntegrity()
        let refetcher = AppsFlyerRefetcher()
        let locator = HTTPDestinationLocator()
        let consentBroker = CombineConsentBroker()
        
        self.machine = FlowMachine(
            storage: storage,
            integrity: integrity,
            refetcher: refetcher,
            locator: locator,
            consentBroker: consentBroker
        )
        
        self.bridge = ObserverBridge()
        
        // Подписка на события машины
        bridge.handler = { [weak self] event in
            Task { @MainActor in
                self?.handleEvent(event)
            }
        }
        machine.subject.subscribe(bridge)
    }
    
    deinit {
        deadlineTask?.cancel()
        machine.subject.unsubscribe(bridge)
    }
    
    func boot() {
        Task {
            machine.warmUp()
            armDeadline()
        }
    }
    
    func feedAttribution(_ data: [String: Any]) {
        Task {
            machine.storeInputs(data)
            await machine.runMachine()
        }
    }
    
    func feedDeeplinks(_ data: [String: Any]) {
        Task {
            machine.storePaths(data)
        }
    }
    
    func grantConsent() {
        Task {
            await machine.acceptConsent()
            
            showPermissionPrompt = false
            navigateToWeb = true
        }
    }
    
    func skipConsent() {
        Task {
            machine.refuseConsent()
            
            showPermissionPrompt = false
            navigateToWeb = true
        }
    }
    
    func networkConnectivityChanged(_ connected: Bool) {
        showOfflineView = !connected
        machine.reportNetworkChange(connected)
    }
    
    private func handleEvent(_ event: BitFlowEvent) {
        switch event {
        case .networkUp:
            showOfflineView = false
            return
        case .networkDown:
            showOfflineView = true
            return
        default:
            break
        }
        
        guard !uiLocked else {
            return
        }
        
        switch event {
        case .consentRequested:
            showPermissionPrompt = true
            
        case .destinationResolved:
            navigateToWeb = true
            
        case .deadlineExpired:
            navigateToMain = true
            
        case .stateChanged(let state):
            if case .failed = state {
                navigateToMain = true
            }
            
        default:
            break
        }
    }
    
    private func armDeadline() {
        deadlineTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            
            guard let self = self else { return }
            self.machine.reportTimeout()
        }
    }
}

final class ObserverBridge: BitFlowObserver {
    var handler: ((BitFlowEvent) -> Void)?
    
    func observe(_ event: BitFlowEvent) {
        handler?(event)
    }
}
