import Foundation

/// Stockage partagé entre l'app et la NSE via App Group (SPEC §3).
///
/// La NSE est un processus distinct : elle n'a accès ni au runtime de l'app ni à
/// sa configuration en mémoire. L'App Group (UserDefaults partagé) est le seul
/// canal pour lui transmettre l'endpoint, la clé d'ingestion et l'identifiant
/// d'installation, et pour remonter les accusés mis en file.
public struct PushproofConfig: Codable, Equatable {
    public let ingestUrl: String
    public let ingestKey: String
    public let appGroup: String?

    public init(ingestUrl: String, ingestKey: String, appGroup: String?) {
        self.ingestUrl = ingestUrl
        self.ingestKey = ingestKey
        self.appGroup = appGroup
    }
}

/// Un accusé mis en file localement (utile en mode dégradé réseau).
public struct PendingReceipt: Codable, Equatable {
    public let notifId: String
    public let userId: String?
    public let platform: String
    public let campaign: String?
    public let receivedAt: String
    public let delivered: Bool

    public init(notifId: String, userId: String?, platform: String, campaign: String? = nil, receivedAt: String, delivered: Bool) {
        self.notifId = notifId
        self.userId = userId
        self.platform = platform
        self.campaign = campaign
        self.receivedAt = receivedAt
        self.delivered = delivered
    }
}

public enum SharedStore {
    private static let configKey = "pushproof.config"
    private static let installIdKey = "pushproof.installId"
    private static let pendingKey = "pushproof.pending"

    /// UserDefaults de l'App Group si configuré, sinon standard (app seule).
    static func defaults(appGroup: String?) -> UserDefaults {
        if let group = appGroup, let d = UserDefaults(suiteName: group) {
            return d
        }
        return .standard
    }

    static func saveConfig(_ config: PushproofConfig) {
        let d = defaults(appGroup: config.appGroup)
        if let data = try? JSONEncoder().encode(config) {
            d.set(data, forKey: configKey)
        }
    }

    /// La NSE relit la config sans connaître l'App Group à l'avance : elle tente
    /// d'abord son propre suite (passé par Info.plist) puis le standard.
    public static func loadConfig(appGroup: String?) -> PushproofConfig? {
        let d = defaults(appGroup: appGroup)
        guard let data = d.data(forKey: configKey) else { return nil }
        return try? JSONDecoder().decode(PushproofConfig.self, from: data)
    }

    /// Identifiant d'installation stable (UUID), généré une fois. Sert de `device`
    /// pour la déduplication serveur `(notif_id, device_hash)` — il est hashé à
    /// l'ingestion, ce n'est pas une donnée identifiante.
    public static func installId(appGroup: String?) -> String {
        let d = defaults(appGroup: appGroup)
        if let existing = d.string(forKey: installIdKey) { return existing }
        let id = UUID().uuidString
        d.set(id, forKey: installIdKey)
        return id
    }

    public static func appendPending(_ receipt: PendingReceipt, appGroup: String?) {
        let d = defaults(appGroup: appGroup)
        var list = loadPending(appGroup: appGroup)
        list.append(receipt)
        // borne raisonnable pour ne pas grossir indéfiniment
        if list.count > 200 { list.removeFirst(list.count - 200) }
        if let data = try? JSONEncoder().encode(list) {
            d.set(data, forKey: pendingKey)
        }
    }

    static func loadPending(appGroup: String?) -> [PendingReceipt] {
        let d = defaults(appGroup: appGroup)
        guard let data = d.data(forKey: pendingKey) else { return [] }
        return (try? JSONDecoder().decode([PendingReceipt].self, from: data)) ?? []
    }

    static func clearPending(appGroup: String?) {
        defaults(appGroup: appGroup).removeObject(forKey: pendingKey)
    }
}
