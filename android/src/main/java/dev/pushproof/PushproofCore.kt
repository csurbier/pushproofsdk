package dev.pushproof

import android.content.Context
import java.util.UUID

/**
 * API in-app du SDK natif Android (SPEC §3). Stocke la configuration et
 * l'identifiant d'installation dans les SharedPreferences. Aucune logique de
 * framework : le wrapper Capacitor ne fait que relayer ces appels.
 */
object PushproofCore {

    private const val PREFS = "pushproof"
    private const val KEY_INGEST_URL = "ingestUrl"
    private const val KEY_INGEST_KEY = "ingestKey"
    private const val KEY_DISPLAY_NOTIFICATION = "displayNotification"
    private const val KEY_INSTALL_ID = "installId"
    private const val KEY_USER_ID = "userId"

    data class Config(val ingestUrl: String, val ingestKey: String)

    fun configure(
        context: Context,
        ingestUrl: String,
        ingestKey: String,
        displayNotification: Boolean = true,
    ) {
        context.applicationContext
            .getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_INGEST_URL, ingestUrl)
            .putString(KEY_INGEST_KEY, ingestKey)
            .putBoolean(KEY_DISPLAY_NOTIFICATION, displayNotification)
            .apply()
        installId(context) // garantit l'installId dès la configuration
    }

    /** Affiche une notification système pour les messages FCM data-only (défaut : true). */
    fun displayNotification(context: Context): Boolean {
        val p = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        return p.getBoolean(KEY_DISPLAY_NOTIFICATION, true)
    }

    fun config(context: Context): Config? {
        val p = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val url = p.getString(KEY_INGEST_URL, null) ?: return null
        val key = p.getString(KEY_INGEST_KEY, null) ?: return null
        return Config(url, key)
    }

    /**
     * Identifiant d'installation stable (UUID), généré une fois. Sert de `device`
     * pour la déduplication serveur `(notif_id, device_hash)` — hashé à l'ingestion.
     */
    fun installId(context: Context): String {
        val p = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        p.getString(KEY_INSTALL_ID, null)?.let { return it }
        val id = UUID.randomUUID().toString()
        p.edit().putString(KEY_INSTALL_ID, id).apply()
        return id
    }

    /**
     * Associe l'appareil à un utilisateur (suivi par utilisateur Pro). À appeler
     * au login. Mono-compte : le dernier `identify` gagne. Attaché aux accusés —
     * seule voie possible en envoi **batch** (payload partagé). `userId` doit être
     * un identifiant **opaque** (jamais email/téléphone) ; hashé côté serveur.
     */
    fun identify(context: Context, userId: String) {
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putString(KEY_USER_ID, userId).apply()
    }

    /** Dissocie l'appareil de l'utilisateur. À appeler au logout. */
    fun clearIdentity(context: Context) {
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().remove(KEY_USER_ID).apply()
    }

    fun userId(context: Context): String? {
        val v = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY_USER_ID, null)
        return if (v.isNullOrEmpty()) null else v
    }
}
