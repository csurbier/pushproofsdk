import PushproofCore
import UserNotifications

/// Service de la Notification Service Extension (SPEC §2).
///
/// iOS réveille la NSE à la réception d'une notification `mutable-content: 1`,
/// **avant** affichage, y compris app fermée (~30 s). On y poste l'accusé puis on
/// laisse passer la notification via `contentHandler`.
///
/// Intégration : dans la cible NSE de l'app, faites hériter votre
/// `NotificationService` de cette classe (rien d'autre à écrire), OU appelez
/// `PushproofNotificationService.handle(...)` depuis votre `didReceive`.
///
/// L'App Group est lu depuis la clé `PushproofAppGroup` de l'Info.plist de la NSE,
/// avec repli sur `group.<bundleId de l'app>`.
open class PushproofNotificationService: UNNotificationServiceExtension {

    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttempt: UNMutableNotificationContent?

    /// App Group partagé avec l'app. Surchargez si besoin.
    open var appGroup: String? {
        if let g = Bundle.main.object(forInfoDictionaryKey: "PushproofAppGroup") as? String {
            return g
        }
        // Repli : <BUNDLE_ID>.nse → group.<BUNDLE_ID>
        if let bundleId = Bundle.main.bundleIdentifier {
            let appId = bundleId.hasSuffix(".nse") ? String(bundleId.dropLast(4)) : bundleId
            return "group.\(appId)"
        }
        return nil
    }

    open override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        self.bestAttempt = request.content.mutableCopy() as? UNMutableNotificationContent

        Self.handle(userInfo: request.content.userInfo, appGroup: appGroup) { [weak self] in
            self?.finish()
        }
    }

    open override func serviceExtensionTimeWillExpire() {
        // iOS va tuer la NSE : on rend ce qu'on a (l'accusé est best-effort).
        finish()
    }

    private func finish() {
        guard let handler = contentHandler, let content = bestAttempt else { return }
        contentHandler = nil
        handler(content)
    }

    /// Cœur réutilisable : extrait notif_id/user_id, poste l'accusé, met en file.
    /// Appelable directement si vous ne sous-classez pas.
    public static func handle(
        userInfo: [AnyHashable: Any],
        appGroup: String?,
        completion: @escaping () -> Void
    ) {
        let (notifId, userId) = ReceiptSender.extractIds(from: userInfo)
        guard
            let notifId = notifId,
            let config = SharedStore.loadConfig(appGroup: appGroup)
        else {
            completion() // pas de notif_id ou pas configuré : on n'altère rien
            return
        }

        let device = SharedStore.installId(appGroup: appGroup)
        let receivedAt = Date()

        ReceiptSender.send(
            notifId: notifId, userId: userId, platform: "ios",
            config: config, device: device, receivedAt: receivedAt
        ) { ok in
            // En cas d'échec réseau, on met en file pour renvoi par l'app.
            if !ok {
                let pending = PendingReceipt(
                    notifId: notifId, userId: userId, platform: "ios",
                    receivedAt: ISO8601DateFormatter().string(from: receivedAt),
                    delivered: true
                )
                SharedStore.appendPending(pending, appGroup: appGroup)
            }
            completion()
        }
    }
}
