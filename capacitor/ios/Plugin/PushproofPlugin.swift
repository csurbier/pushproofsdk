import Capacitor
import Foundation
import PushproofCore

/// Pont Capacitor ↔ SDK natif iOS (SPEC §3). AUCUNE logique métier ici : on relaie
/// les appels vers `Pushproof` (PushproofCore). La capture réelle de livraison se
/// fait dans la cible NSE (processus distinct), pas dans ce plugin.
@objc(PushproofPlugin)
public class PushproofPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "PushproofPlugin"
    public let jsName = "Pushproof"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "configure", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "identify", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "clearIdentity", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "recordDelivery", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getPendingReceipts", returnType: CAPPluginReturnPromise),
    ]

    @objc func configure(_ call: CAPPluginCall) {
        guard
            let ingestUrl = call.getString("ingestUrl"),
            let ingestKey = call.getString("ingestKey")
        else {
            call.reject("ingestUrl et ingestKey sont requis")
            return
        }
        Pushproof.shared.configure(
            ingestUrl: ingestUrl,
            ingestKey: ingestKey,
            appGroup: call.getString("appGroup")
        )
        call.resolve()
    }

    @objc func identify(_ call: CAPPluginCall) {
        guard let userId = call.getString("userId") else {
            call.reject("userId requis")
            return
        }
        Pushproof.shared.identify(userId: userId)
        call.resolve()
    }

    @objc func clearIdentity(_ call: CAPPluginCall) {
        Pushproof.shared.clearIdentity()
        call.resolve()
    }

    @objc func recordDelivery(_ call: CAPPluginCall) {
        guard let notifId = call.getString("notifId") else {
            call.reject("notifId requis")
            return
        }
        Pushproof.shared.sendReceipt(
            notifId: notifId,
            userId: call.getString("userId"),
            campaign: call.getString("campaign")
        ) { ok in
            call.resolve(["accepted": ok])
        }
    }

    @objc func getPendingReceipts(_ call: CAPPluginCall) {
        let receipts = Pushproof.shared.pendingReceipts().map { r in
            return [
                "notifId": r.notifId,
                "userId": r.userId as Any,
                "platform": r.platform,
                "receivedAt": r.receivedAt,
                "delivered": r.delivered,
            ]
        }
        Pushproof.shared.clearPendingReceipts()
        call.resolve(["receipts": receipts])
    }
}
