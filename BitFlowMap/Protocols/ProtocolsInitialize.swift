import Foundation

protocol BootstrapInitializer {
    func bootstrap()
}

protocol RemoteDataReceiver {
    func receiveAttributionData(_ data: [AnyHashable: Any])
    func receiveDeeplinkData(_ data: [AnyHashable: Any])
}

protocol PushPayloadProcessor {
    func processPush(_ payload: [AnyHashable: Any])
}
