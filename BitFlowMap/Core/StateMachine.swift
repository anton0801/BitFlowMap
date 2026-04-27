import Foundation
import AppsFlyerLib
import Combine

final class EventSubject {
    
    private var observers: [WeakObserver] = []
    private let lock = NSLock()
    
    func subscribe(_ observer: BitFlowObserver) {
        lock.lock()
        defer { lock.unlock() }
        
        observers.append(WeakObserver(value: observer))
        observers = observers.filter { $0.value != nil }
    }
    
    func unsubscribe(_ observer: BitFlowObserver) {
        lock.lock()
        defer { lock.unlock() }
        
        observers.removeAll { $0.value === observer || $0.value == nil }
    }
    
    func broadcast(_ event: BitFlowEvent) {
        lock.lock()
        let snapshot = observers.compactMap { $0.value }
        lock.unlock()
        
        for observer in snapshot {
            observer.observe(event)
        }
    }
}

private struct WeakObserver {
    weak var value: BitFlowObserver?
}

final class FlowMachine {
    
    let subject = EventSubject()
    
    private(set) var currentState: MachineState = .idle {
        didSet {
            if oldValue != currentState {
                subject.broadcast(.stateChanged(currentState))
            }
        }
    }
    
    private var attributionRecord: AttributionRecord = .zero
    private var destinationRecord: DestinationRecord = .zero
    private var acknowledgementRecord: AcknowledgementRecord = .zero
    
    private var organicFetchDone: Bool = false
    
    private var sequenceCompleted: Bool = false
    
    private let storage: StorageLayer
    private let integrity: IntegrityChecker
    private let refetcher: AttributionRefetcher
    private let locator: DestinationLocator
    private let consentBroker: ConsentBroker
    
    init(
        storage: StorageLayer,
        integrity: IntegrityChecker,
        refetcher: AttributionRefetcher,
        locator: DestinationLocator,
        consentBroker: ConsentBroker
    ) {
        self.storage = storage
        self.integrity = integrity
        self.refetcher = refetcher
        self.locator = locator
        self.consentBroker = consentBroker
    }
    
    func warmUp() {
        let bundle = storage.loadBundle()
        
        attributionRecord.inputs = bundle.inputs
        attributionRecord.paths = bundle.paths
        
        destinationRecord.link = bundle.link
        destinationRecord.mode = bundle.mode
        destinationRecord.virgin = bundle.virgin
        
        acknowledgementRecord.approved = bundle.approved
        acknowledgementRecord.refused = bundle.refused
        acknowledgementRecord.queriedAt = bundle.queriedAt
    }
    
    func storeInputs(_ data: [String: Any]) {
        let mapped = data.mapValues { "\($0)" }
        attributionRecord.inputs = mapped
        storage.saveInputs(mapped)
        subject.broadcast(.attributionLoaded)
    }
    
    func storePaths(_ data: [String: Any]) {
        let mapped = data.mapValues { "\($0)" }
        attributionRecord.paths = mapped
        storage.savePaths(mapped)
    }
    
    func runMachine() async {
        guard !sequenceCompleted else { return }
        
        if let tempURL = UserDefaults.standard.string(forKey: StorageSlot.pushURL),
           !tempURL.isEmpty {
            await commitDestination(url: tempURL)
            return
        }
        
        guard attributionRecord.hasContent else {
            return
        }
        
        currentState = .validating
        
        do {
            try await integrity.examine()
        } catch {
            await transitionToFailure(.validationDenied)
            return
        }
        
        if attributionRecord.fromOrganic && destinationRecord.virgin && !organicFetchDone {
            organicFetchDone = true
            await performOrganicRefetch()
        }
        
        currentState = .resolving
        
        do {
            let url = try await locator.locate(context: attributionRecord.inputs.mapValues { $0 as Any })
            await commitDestination(url: url)
        } catch BitFlowError.endpointDeclined {
            await transitionToFailure(.endpointMissing)
        } catch {
            await transitionToFailure(.endpointMissing)
        }
    }
    
    func acceptConsent() async {
        var localAck = acknowledgementRecord
        
        let granted = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            var cancellable: AnyCancellable?
            cancellable = consentBroker.solicit().sink { value in
                cancellable?.cancel()
                continuation.resume(returning: value)
            }
        }
        
        if granted {
            localAck.approved = true
            localAck.refused = false
            localAck.queriedAt = Date()
            consentBroker.enable()
            subject.broadcast(.consentGranted)
        } else {
            localAck.approved = false
            localAck.refused = true
            localAck.queriedAt = Date()
            subject.broadcast(.consentRefused)
        }
        
        acknowledgementRecord = localAck
        storage.saveAcknowledgement(localAck)
    }
    
    func refuseConsent() {
        acknowledgementRecord.queriedAt = Date()
        storage.saveAcknowledgement(acknowledgementRecord)
        subject.broadcast(.consentRefused)
    }
    
    func reportTimeout() {
        guard !sequenceCompleted else {
            return
        }
        
        sequenceCompleted = true
        currentState = .failed(reason: .deadlineHit)
        subject.broadcast(.deadlineExpired)
    }
    
    func reportNetworkChange(_ connected: Bool) {
        subject.broadcast(connected ? .networkUp : .networkDown)
    }
    
    private func performOrganicRefetch() async {
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        
        guard !destinationRecord.frozen else { return }
        
        let deviceID = AppsFlyerLib.shared().getAppsFlyerUID()
        
        do {
            var fetched = try await refetcher.refetch(deviceID: deviceID)
            
            for (k, v) in attributionRecord.paths {
                if fetched[k] == nil {
                    fetched[k] = v
                }
            }
            
            let mapped = fetched.mapValues { "\($0)" }
            attributionRecord.inputs = mapped
            storage.saveInputs(mapped)
        } catch {
        }
    }
    
    private func commitDestination(url: String) async {
        let needsConsent = acknowledgementRecord.canQueryAgain
        
        destinationRecord.link = url
        destinationRecord.mode = "Active"
        destinationRecord.virgin = false
        destinationRecord.frozen = true
        
        storage.saveDestination(link: url, mode: "Active")
        storage.recordStartup()
        
        UserDefaults.standard.removeObject(forKey: StorageSlot.pushURL)
        
        sequenceCompleted = true
        
        if needsConsent {
            currentState = .awaitingConsent
            subject.broadcast(.consentRequested)
        } else {
            currentState = .ready(url: url)
            subject.broadcast(.destinationResolved(url))
        }
    }
    
    private func transitionToFailure(_ reason: FailureReason) async {
        sequenceCompleted = true
        currentState = .failed(reason: reason)
    }
}
