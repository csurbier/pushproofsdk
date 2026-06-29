// AUTO-GÉNÉRÉ par scripts/sync-native-android.js — NE PAS ÉDITER.
// Source de vérité : android/src/main/java/dev/pushproof/ (racine du repo).

package dev.pushproof

import com.google.firebase.messaging.RemoteMessage
import java.lang.reflect.Method

/**
 * Relaie un message FCM data-only vers `@capacitor/push-notifications` pour
 * déclencher `pushNotificationReceived` (popup in-app) quand l'app est au premier plan.
 * Utilise la réflexion pour ne pas dépendre compile-time de Capacitor.
 */
object CapacitorPushForwarder {

    private val sendRemoteMessage: Method? by lazy {
        try {
            Class.forName("com.capacitorjs.plugins.pushnotifications.PushNotificationsPlugin")
                .getMethod("sendRemoteMessage", RemoteMessage::class.java)
        } catch (_: Exception) {
            null
        }
    }

    /** @return `true` si le plugin Capacitor Push Notifications est présent. */
    fun forward(message: RemoteMessage): Boolean {
        val method = sendRemoteMessage ?: return false
        return try {
            method.invoke(null, message)
            true
        } catch (_: Exception) {
            false
        }
    }
}
