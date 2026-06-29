package dev.pushproof

import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

/**
 * Capture de la réception Android (SPEC §2). Surcharge `onMessageReceived`, appelé
 * à la réception d'un message. **Recommandation** : envoyer des messages
 * data-only depuis le backend pour garantir le passage par ce service même app
 * en arrière-plan.
 *
 * Deux modes d'intégration :
 *  1. L'app n'a pas son propre service → déclarer directement celui-ci dans le
 *     manifest (voir doc).
 *  2. L'app a déjà un FirebaseMessagingService → appeler
 *     `PushproofMessagingService.handle(this, message)` depuis son onMessageReceived.
 */
open class PushproofMessagingService : FirebaseMessagingService() {

    override fun onMessageReceived(message: RemoteMessage) {
        handle(this, message)
    }

    companion object {
        /** Cœur réutilisable, appelable depuis le service existant de l'app. */
        @JvmStatic
        fun handle(service: FirebaseMessagingService, message: RemoteMessage) {
            val (notifId, userId, campaign) = ReceiptSender.extractIds(message.data)
            if (notifId == null) return
            val config = PushproofCore.config(service.applicationContext) ?: return
            val ctx = service.applicationContext

            if (AppForeground.isInForeground()) {
                // Premier plan : popup in-app via Capacitor ; pas de notification système.
                val forwarded = CapacitorPushForwarder.forward(message)
                if (!forwarded && PushproofCore.displayNotification(ctx)) {
                    NotificationDisplay.show(ctx, message.data)
                }
            } else {
                // Arrière-plan / app fermée : barre système.
                NotificationDisplay.showIfEnabled(ctx, message.data)
            }

            ReceiptSender.send(ctx, notifId, userId, config, campaign)
        }
    }
}
