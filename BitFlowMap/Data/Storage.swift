import Foundation

final class LayeredStorage: StorageLayer {
    
    // Слой 1: shared (для widget/extension)
    private let sharedLayer: UserDefaults
    
    // Слой 2: private (только для main app)
    private let privateLayer: UserDefaults
    
    init() {
        self.sharedLayer = UserDefaults(suiteName: BitFlowParams.suiteGroup)!
        self.privateLayer = UserDefaults.standard
    }
    
    // MARK: - Save
    
    func saveInputs(_ data: [String: String]) {
        guard let serialized = serialize(data) else { return }
        // Inputs пишутся в private layer (sensitive attribution)
        privateLayer.set(serialized, forKey: StorageSlot.inputs)
    }
    
    func savePaths(_ data: [String: String]) {
        guard let serialized = serialize(data) else { return }
        let cipher = obfuscate(serialized)
        // Paths — в shared layer (deeplinks могут быть нужны другим компонентам)
        sharedLayer.set(cipher, forKey: StorageSlot.paths)
    }
    
    func saveDestination(link: String, mode: String) {
        // URL дублируется в оба слоя — нужен и main, и WebView (через UserDefaults.standard)
        sharedLayer.set(link, forKey: StorageSlot.link)
        privateLayer.set(link, forKey: StorageSlot.link)
        
        sharedLayer.set(mode, forKey: StorageSlot.mode)
    }
    
    func saveAcknowledgement(_ ack: AcknowledgementRecord) {
        sharedLayer.set(ack.approved, forKey: StorageSlot.ackYes)
        sharedLayer.set(ack.refused, forKey: StorageSlot.ackNo)
        
        if let when = ack.queriedAt {
            let ms = when.timeIntervalSince1970 * 1000
            sharedLayer.set(ms, forKey: StorageSlot.ackTime)
        }
    }
    
    func recordStartup() {
        sharedLayer.set(true, forKey: StorageSlot.started)
    }
    
    // MARK: - Load
    
    func loadBundle() -> PersistedBundle {
        let inputsRaw = privateLayer.string(forKey: StorageSlot.inputs) ?? ""
        let inputs = deserialize(inputsRaw) ?? [:]
        
        let pathsCipher = sharedLayer.string(forKey: StorageSlot.paths) ?? ""
        let pathsRaw = deobfuscate(pathsCipher) ?? ""
        let paths = deserialize(pathsRaw) ?? [:]
        
        let link = sharedLayer.string(forKey: StorageSlot.link)
        let mode = sharedLayer.string(forKey: StorageSlot.mode)
        let started = sharedLayer.bool(forKey: StorageSlot.started)
        
        let approved = sharedLayer.bool(forKey: StorageSlot.ackYes)
        let refused = sharedLayer.bool(forKey: StorageSlot.ackNo)
        let timeMs = sharedLayer.double(forKey: StorageSlot.ackTime)
        let queriedAt = timeMs > 0 ? Date(timeIntervalSince1970: timeMs / 1000) : nil
        
        return PersistedBundle(
            inputs: inputs,
            paths: paths,
            link: link,
            mode: mode,
            virgin: !started,
            approved: approved,
            refused: refused,
            queriedAt: queriedAt
        )
    }
    
    // MARK: - Serialization
    
    private func serialize(_ dict: [String: String]) -> String? {
        let anyDict = dict.mapValues { $0 as Any }
        guard let data = try? JSONSerialization.data(withJSONObject: anyDict),
              let text = String(data: data, encoding: .utf8) else {
            return nil
        }
        return text
    }
    
    private func deserialize(_ text: String) -> [String: String]? {
        guard let data = text.data(using: .utf8),
              let anyDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return anyDict.mapValues { "\($0)" }
    }
    
    // MARK: - Obfuscation
    
    private func obfuscate(_ input: String) -> String {
        let b64 = Data(input.utf8).base64EncodedString()
        return b64
            .replacingOccurrences(of: "=", with: "!")
            .replacingOccurrences(of: "+", with: "_")
    }
    
    private func deobfuscate(_ input: String) -> String? {
        let b64 = input
            .replacingOccurrences(of: "!", with: "=")
            .replacingOccurrences(of: "_", with: "+")
        
        guard let data = Data(base64Encoded: b64),
              let text = String(data: data, encoding: .utf8) else {
            return nil
        }
        return text
    }
}
