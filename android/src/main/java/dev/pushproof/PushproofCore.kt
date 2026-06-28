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
    private const val KEY_INSTALL_ID = "installId"

    data class Config(val ingestUrl: String, val ingestKey: String)

    fun configure(context: Context, ingestUrl: String, ingestKey: String) {
        context.applicationContext
            .getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_INGEST_URL, ingestUrl)
            .putString(KEY_INGEST_KEY, ingestKey)
            .apply()
        installId(context) // garantit l'installId dès la configuration
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
}
