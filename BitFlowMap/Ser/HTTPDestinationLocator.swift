import FirebaseCore
import FirebaseMessaging
import WebKit
import AppsFlyerLib
import Foundation

final class HTTPDestinationLocator: DestinationLocator {
    
    private let session: URLSession
    private let backoffs: [Double] = [40.0, 80.0, 160.0]
    
    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 90
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        self.session = URLSession(configuration: config)
    }
    
    private var browserAgent: String = WKWebView().value(forKey: "userAgent") as? String ?? ""
    
    func locate(context: [String: Any]) async throws -> String {
        guard let endpoint = URL(string: BitFlowParams.backendURL) else {
            throw BitFlowError.decodingIssue
        }
        
        var payload: [String: Any] = context
        payload["os"] = "iOS"
        payload["af_id"] = AppsFlyerLib.shared().getAppsFlyerUID()
        payload["bundle_id"] = Bundle.main.bundleIdentifier ?? ""
        payload["firebase_project_id"] = FirebaseApp.app()?.options.gcmSenderID
        payload["store_id"] = "id\(BitFlowParams.appNumber)"
        payload["push_token"] = UserDefaults.standard.string(forKey: StorageSlot.push)
            ?? Messaging.messaging().fcmToken
        payload["locale"] = Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(browserAgent, forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        var lastError: Error?
        
        for (idx, delay) in backoffs.enumerated() {
            do {
                return try await singleAttempt(request: request)
            } catch BitFlowError.endpointDeclined {
                throw BitFlowError.endpointDeclined
            } catch BitFlowError.rateLimited {
                let waitTime = delay * Double(idx + 1)
                try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
                continue
            } catch {
                lastError = error
                if idx < backoffs.count - 1 {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? BitFlowError.transportFailure
    }
    
    private func singleAttempt(request: URLRequest) async throws -> String {
        let (data, response) = try await session.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw BitFlowError.transportFailure
        }
        
        if http.statusCode == 404 {
            throw BitFlowError.endpointDeclined
        }
        
        if http.statusCode == 429 {
            throw BitFlowError.rateLimited
        }
        
        guard (200...299).contains(http.statusCode) else {
            throw BitFlowError.transportFailure
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw BitFlowError.decodingIssue
        }
        
        guard let ok = json["ok"] as? Bool else {
            throw BitFlowError.decodingIssue
        }
        
        if !ok {
            throw BitFlowError.endpointDeclined
        }
        
        guard let url = json["url"] as? String else {
            throw BitFlowError.decodingIssue
        }
        
        return url
    }
}
