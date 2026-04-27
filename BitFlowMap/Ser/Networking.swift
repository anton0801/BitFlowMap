import Foundation
import Supabase
import AppsFlyerLib
import FirebaseCore
import FirebaseMessaging
import WebKit
import UIKit
import UserNotifications
import Combine

final class SupabaseIntegrity: IntegrityChecker {
    
    private let client: SupabaseClient
    
    init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: "https://obhjkxoubgmivdrsltjz.supabase.co")!,
            supabaseKey: "sb_publishable_allWZ3xYf33zToyKH93Lzg_Uqc5gNL0"
        )
    }
    
    func examine() async throws {
        do {
            let rows: [IntegrityRow] = try await client
                .from("validation")
                .select()
                .limit(1)
                .execute()
                .value
            
            guard let row = rows.first else {
                throw BitFlowError.validationFailed
            }
            
            if !row.isValid {
                throw BitFlowError.validationFailed
            }
        } catch let error as BitFlowError {
            throw error
        } catch {
            print("\(BitFlowParams.trace) Integrity examine failed: \(error)")
            throw BitFlowError.validationFailed
        }
    }
}

struct IntegrityRow: Codable {
    let id: Int?
    let isValid: Bool
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case isValid = "is_valid"
        case createdAt = "created_at"
    }
}

final class CombineConsentBroker: ConsentBroker {
    
    func solicit() -> Future<Bool, Never> {
        return Future { promise in
            UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            ) { granted, _ in
                DispatchQueue.main.async {
                    promise(.success(granted))
                }
            }
        }
    }
    
    func enable() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}
