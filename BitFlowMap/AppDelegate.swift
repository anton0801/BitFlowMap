import UIKit
import FirebaseCore
import FirebaseMessaging
import AppTrackingTransparency
import UserNotifications
import AppsFlyerLib

// MARK: - Application Delegate

final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private let dataMerger = DataMerger()
    private let pushExtractor = PushExtractor()
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        // Wire up dataMerger callbacks через self (AppDelegate реализует RemoteDataReceiver)
        dataMerger.onAttributionMerged = { [weak self] data in
            self?.receiveAttributionData(data)
        }
        dataMerger.onDeeplinksMerged = { [weak self] data in
            self?.receiveDeeplinkData(data)
        }
        
        // BootstrapInitializer
        bootstrap()
        
        // PushPayloadProcessor
        if let remote = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            processPush(remote)
        }
        
        // Lifecycle observation
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onActivation),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    @objc private func onActivation() {
        startAppsFlyer()
    }
    
    private func startAppsFlyer() {
        if #available(iOS 14, *) {
            AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
            
            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.async {
                    AppsFlyerLib.shared().start()
                    UserDefaults.standard.set(status.rawValue, forKey: "att_status")
                }
            }
        } else {
            AppsFlyerLib.shared().start()
        }
    }
}

// MARK: - BootstrapInitializer Conformance

extension AppDelegate: BootstrapInitializer {
    func bootstrap() {
        // Firebase
        FirebaseApp.configure()
        
        // Messaging
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        UIApplication.shared.registerForRemoteNotifications()
        
        // AppsFlyer
        let sdk = AppsFlyerLib.shared()
        sdk.appsFlyerDevKey = BitFlowParams.trackerKey
        sdk.appleAppID = BitFlowParams.appNumber
        sdk.delegate = self
        sdk.deepLinkDelegate = self
        sdk.isDebug = false
    }
}

// MARK: - RemoteDataReceiver Conformance

extension AppDelegate: RemoteDataReceiver {
    func receiveAttributionData(_ data: [AnyHashable: Any]) {
        NotificationCenter.default.post(
            name: .init("ConversionDataReceived"),
            object: nil,
            userInfo: ["conversionData": data]
        )
    }
    
    func receiveDeeplinkData(_ data: [AnyHashable: Any]) {
        NotificationCenter.default.post(
            name: .init("deeplink_values"),
            object: nil,
            userInfo: ["deeplinksData": data]
        )
    }
}

// MARK: - PushPayloadProcessor Conformance

extension AppDelegate: PushPayloadProcessor {
    func processPush(_ payload: [AnyHashable: Any]) {
        pushExtractor.extract(payload)
    }
}

// MARK: - Messaging Delegate

extension AppDelegate: MessagingDelegate {
    func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        messaging.token { token, err in
            guard err == nil, let t = token else { return }
            
            UserDefaults.standard.set(t, forKey: StorageSlot.fcm)
            UserDefaults.standard.set(t, forKey: StorageSlot.push)
            UserDefaults(suiteName: BitFlowParams.suiteGroup)?.set(t, forKey: "shared_fcm")
        }
    }
}

// MARK: - Notification Delegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        processPush(notification.request.content.userInfo)
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        processPush(response.notification.request.content.userInfo)
        completionHandler()
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        processPush(userInfo)
        completionHandler(.newData)
    }
}

// MARK: - AppsFlyer Delegate

extension AppDelegate: AppsFlyerLibDelegate, DeepLinkDelegate {
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        dataMerger.acceptAttribution(data)
    }
    
    func onConversionDataFail(_ error: Error) {
        let errorData: [AnyHashable: Any] = [
            "error": true,
            "error_desc": error.localizedDescription
        ]
        dataMerger.acceptAttribution(errorData)
    }
    
    func didResolveDeepLink(_ result: DeepLinkResult) {
        guard case .found = result.status,
              let link = result.deepLink else { return }
        
        dataMerger.acceptDeeplinks(link.clickEvent)
    }
}

// MARK: - DataMerger (helper #1)

final class DataMerger: NSObject {
    var onAttributionMerged: (([AnyHashable: Any]) -> Void)?
    var onDeeplinksMerged: (([AnyHashable: Any]) -> Void)?
    
    private var attributionBuffer: [AnyHashable: Any] = [:]
    private var deeplinksBuffer: [AnyHashable: Any] = [:]
    private var mergeTimer: Timer?
    
    func acceptAttribution(_ data: [AnyHashable: Any]) {
        attributionBuffer = data
        scheduleMerge()
        
        if !deeplinksBuffer.isEmpty {
            performMerge()
        }
    }
    
    func acceptDeeplinks(_ data: [AnyHashable: Any]) {
        guard !UserDefaults.standard.bool(forKey: StorageSlot.started) else { return }
        
        deeplinksBuffer = data
        onDeeplinksMerged?(data)
        mergeTimer?.invalidate()
        
        if !attributionBuffer.isEmpty {
            performMerge()
        }
    }
    
    private func scheduleMerge() {
        mergeTimer?.invalidate()
        mergeTimer = Timer.scheduledTimer(
            withTimeInterval: 2.5,
            repeats: false
        ) { [weak self] _ in
            self?.performMerge()
        }
    }
    
    private func performMerge() {
        var merged = attributionBuffer
        
        for (k, v) in deeplinksBuffer {
            let prefixed = "deep_\(k)"
            if merged[prefixed] == nil {
                merged[prefixed] = v
            }
        }
        
        onAttributionMerged?(merged)
    }
}

// MARK: - PushExtractor (helper #2)

final class PushExtractor: NSObject {
    
    func extract(_ payload: [AnyHashable: Any]) {
        guard let url = scanForURL(payload) else { return }
        
        UserDefaults.standard.set(url, forKey: StorageSlot.pushURL)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            NotificationCenter.default.post(
                name: .init("LoadTempURL"),
                object: nil,
                userInfo: ["temp_url": url]
            )
        }
    }
    
    private func scanForURL(_ payload: [AnyHashable: Any]) -> String? {
        if let direct = payload["url"] as? String {
            return direct
        }
        
        if let nested = payload["data"] as? [String: Any],
           let url = nested["url"] as? String {
            return url
        }
        
        if let aps = payload["aps"] as? [String: Any],
           let nested = aps["data"] as? [String: Any],
           let url = nested["url"] as? String {
            return url
        }
        
        if let custom = payload["custom"] as? [String: Any],
           let url = custom["target_url"] as? String {
            return url
        }
        
        return nil
    }
}
