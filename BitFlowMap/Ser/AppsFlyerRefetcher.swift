import Foundation

final class AppsFlyerRefetcher: AttributionRefetcher {
    
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 90
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        self.session = URLSession(configuration: config)
    }
    
    func refetch(deviceID: String) async throws -> [String: Any] {
        var components = URLComponents(string: "https://gcdsdk.appsflyer.com/install_data/v4.0/id\(BitFlowParams.appNumber)")
        components?.queryItems = [
            URLQueryItem(name: "devkey", value: BitFlowParams.trackerKey),
            URLQueryItem(name: "device_id", value: deviceID)
        ]
        
        guard let requestURL = components?.url else {
            throw BitFlowError.decodingIssue
        }
        
        var request = URLRequest(url: requestURL)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await session.data(for: request)
        
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw BitFlowError.transportFailure
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw BitFlowError.decodingIssue
        }
        
        return json
    }
}
