package dev.pushproof

import android.content.Context
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import java.util.concurrent.Executors

/**
 * Envoi d'un accusé vers l'endpoint d'ingestion (POST /v1/receipts).
 * HttpURLConnection pour ne dépendre d'aucune lib réseau côté client.
 */
object ReceiptSender {

    private val executor = Executors.newSingleThreadExecutor()

    /** Lit notif_id / user_id dans les données du message (clé de corrélation). */
    fun extractIds(data: Map<String, String>): Pair<String?, String?> {
        val notifId = data["notif_id"] ?: data["notifId"]
        val userId = data["user_id"] ?: data["userId"]
        return notifId to userId
    }

    fun send(
        context: Context,
        notifId: String,
        userId: String?,
        config: PushproofCore.Config,
        onResult: ((Boolean) -> Unit)? = null,
    ) {
        val device = PushproofCore.installId(context)
        executor.execute {
            val ok = runCatching { doPost(notifId, userId, device, config) }.getOrDefault(false)
            onResult?.invoke(ok)
        }
    }

    private fun doPost(
        notifId: String,
        userId: String?,
        device: String,
        config: PushproofCore.Config,
    ): Boolean {
        val body = JSONObject().apply {
            put("notifId", notifId)
            put("device", device)
            put("platform", "android")
            put("receivedAt", iso8601(Date()))
            if (!userId.isNullOrEmpty()) put("userId", userId)
        }.toString()

        val conn = (URL(config.ingestUrl).openConnection() as HttpURLConnection).apply {
            requestMethod = "POST"
            connectTimeout = 8000
            readTimeout = 8000
            doOutput = true
            setRequestProperty("Content-Type", "application/json")
            setRequestProperty("X-Ingest-Key", config.ingestKey)
        }
        return try {
            conn.outputStream.use { it.write(body.toByteArray()) }
            conn.responseCode in 200..299
        } finally {
            conn.disconnect()
        }
    }

    private fun iso8601(date: Date): String =
        SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US)
            .apply { timeZone = TimeZone.getTimeZone("UTC") }
            .format(date)
}
