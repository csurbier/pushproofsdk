import Foundation

/// API in-app du SDK natif iOS (SPEC §3). Utilisée directement (natif pur) ou
/// via le wrapper Capacitor. Ne contient AUCUNE logique de framework.
public final class Pushproof {

    public static let shared = Pushproof()
    private init() {}

    private var config: PushproofConfig?

    /// Enregistre l'endpoint et la clé. Persiste dans l'App Group pour que la
    /// NSE (processus distinct) y ait accès.
    public func configure(ingestUrl: String, ingestKey: String, appGroup: String? = nil) {
        let cfg = PushproofConfig(ingestUrl: ingestUrl, ingestKey: ingestKey, appGroup: appGroup)
        self.config = cfg
        SharedStore.saveConfig(cfg)
        _ = SharedStore.installId(appGroup: appGroup) // garantit l'installId dès la config
    }

    /// Identifiant d'installation utilisé comme `device` (hashé côté serveur).
    public var deviceId: String {
        SharedStore.installId(appGroup: config?.appGroup)
    }

    /// Associe l'appareil à un utilisateur (suivi par utilisateur Pro). À appeler
    /// **au login**. Mono-compte : le dernier `identify` gagne. Persisté dans
    /// l'App Group pour que la NSE l'attache aux accusés, même en envoi **batch**
    /// (où le payload partagé ne peut pas porter un user_id par destinataire).
    /// `userId` doit être un identifiant **opaque** (jamais email/téléphone) ; il
    /// est hashé côté serveur.
    public func identify(userId: String) {
        SharedStore.saveUserId(userId, appGroup: config?.appGroup)
    }

    /// Dissocie l'appareil de l'utilisateur. À appeler **au logout**.
    public func clearIdentity() {
        SharedStore.clearUserId(appGroup: config?.appGroup)
    }

    /// Envoie un accusé depuis l'app (cas in-app / mode dégradé). En pratique,
    /// la réception réelle est captée par la NSE ; cette méthode sert aux tests
    /// et au renvoi des accusés mis en file.
    public func sendReceipt(notifId: String, userId: String? = nil, campaign: String? = nil, completion: ((Bool) -> Void)? = nil) {
        guard let cfg = config else { completion?(false); return }
        ReceiptSender.send(
            notifId: notifId, userId: userId, platform: "ios",
            config: cfg, device: deviceId, campaign: campaign
        ) { ok in completion?(ok) }
    }

    /// Accusés mis en file par la NSE et pas encore confirmés (lecture App Group).
    public func pendingReceipts() -> [PendingReceipt] {
        SharedStore.loadPending(appGroup: config?.appGroup)
    }

    public func clearPendingReceipts() {
        SharedStore.clearPending(appGroup: config?.appGroup)
    }
}
