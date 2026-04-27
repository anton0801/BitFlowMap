import Foundation
import Combine

protocol IntegrityChecker {
    func examine() async throws
}

protocol AttributionRefetcher {
    func refetch(deviceID: String) async throws -> [String: Any]
}

protocol DestinationLocator {
    func locate(context: [String: Any]) async throws -> String
}

protocol ConsentBroker {
    func solicit() -> Future<Bool, Never>
    func enable()
}

protocol BitFlowObserver: AnyObject {
    func observe(_ event: BitFlowEvent)
}

protocol StorageLayer {
    func saveInputs(_ data: [String: String])
    func savePaths(_ data: [String: String])
    func saveDestination(link: String, mode: String)
    func saveAcknowledgement(_ ack: AcknowledgementRecord)
    func recordStartup()
    func loadBundle() -> PersistedBundle
}
