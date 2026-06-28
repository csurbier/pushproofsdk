import Foundation

/// Envoi d'un accusé vers l'endpoint d'ingestion (POST /v1/receipts).
/// Code partagé entre l'app (PushproofCore) et la NSE (PushproofNSE).
public enum ReceiptSender {

    /// Construit et envoie le POST. `completion` est appelé quand la requête se
    /// termine (ou expire) — la NSE doit attendre avant d'appeler son contentHandler.
    public static func send(
        notifId: String,
        userId: String?,
        platform: String,
        config: PushproofConfig,
        device: String,
        receivedAt: Date = Date(),
        session: URLSession = .shared,
        completion: @escaping (Bool) -> Void
    ) {
        guard let url = URL(string: config.ingestUrl) else {
            completion(false)
            return
        }

        var body: [String: Any] = [
            "notifId": notifId,
            "device": device,
            "platform": platform,
            "receivedAt": ISO8601DateFormatter().string(from: receivedAt),
        ]
        if let userId = userId, !userId.isEmpty {
            body["userId"] = userId
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.ingestKey, forHTTPHeaderField: "X-Ingest-Key")
        request.timeoutInterval = 12
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        session.dataTask(with: request) { _, response, error in
            let ok = error == nil
                && (response as? HTTPURLResponse).map { (200..<300).contains($0.statusCode) } ?? false
            completion(ok)
        }.resume()
    }

    /// Extrait `notif_id` / `user_id` du payload reçu (clé de corrélation, SPEC §2).
    /// Le SDK ne génère JAMAIS le notif_id : il le lit dans la notification.
    public static func extractIds(from userInfo: [AnyHashable: Any]) -> (notifId: String?, userId: String?) {
        // Le backend émetteur peut placer notif_id au niveau racine (data-only)
        // ou dans un sous-dictionnaire applicatif. On gère les deux.
        func find(_ keys: [String], in dict: [AnyHashable: Any]) -> String? {
            for k in keys { if let v = dict[k] as? String { return v } }
            return nil
        }
        let notifId = find(["notif_id", "notifId"], in: userInfo)
        let userId = find(["user_id", "userId"], in: userInfo)
        return (notifId, userId)
    }
}
