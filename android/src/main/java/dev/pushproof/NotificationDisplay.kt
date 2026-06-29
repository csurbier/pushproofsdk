package dev.pushproof

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat

/**
 * Affiche une notification système à partir d'un message FCM **data-only**
 * (title/body dans le bloc `data`). Nécessaire car les messages data-only ne
 * passent pas par la barre système automatiquement.
 */
object NotificationDisplay {

    private const val CHANNEL_ID = "pushproof_default"
    private const val CHANNEL_NAME = "Push notifications"

    fun showIfEnabled(context: Context, data: Map<String, String>) {
        if (!PushproofCore.displayNotification(context)) return
        val title = extractTitle(data) ?: return
        val body = extractBody(data) ?: return
        if (!canPost(context)) return

        val appContext = context.applicationContext
        ensureChannel(appContext)

        val notifId = data["notif_id"] ?: data["notifId"]
        val notificationId = notifId?.hashCode() ?: (title + body).hashCode()

        val builder = NotificationCompat.Builder(appContext, CHANNEL_ID)
            .setSmallIcon(resolveSmallIcon(appContext))
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(launchPendingIntent(appContext))

        NotificationManagerCompat.from(appContext).notify(notificationId, builder.build())
    }

    private fun extractTitle(data: Map<String, String>): String? =
        data["title"]
            ?: data["gcm.notification.title"]
            ?: data["notification_title"]
            ?.takeIf { it.isNotBlank() }

    private fun extractBody(data: Map<String, String>): String? =
        data["body"]
            ?: data["gcm.notification.body"]
            ?: data["notification_body"]
            ?: data["message"]
            ?.takeIf { it.isNotBlank() }

    private fun canPost(context: Context): Boolean {
        if (!NotificationManagerCompat.from(context).areNotificationsEnabled()) return false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            return ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.POST_NOTIFICATIONS,
            ) == PackageManager.PERMISSION_GRANTED
        }
        return true
    }

    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            CHANNEL_NAME,
            NotificationManager.IMPORTANCE_DEFAULT,
        )
        manager.createNotificationChannel(channel)
    }

    private fun resolveSmallIcon(context: Context): Int {
        val icon = context.applicationInfo.icon
        return if (icon != 0) icon else android.R.drawable.ic_dialog_info
    }

    private fun launchPendingIntent(context: Context): PendingIntent? {
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?: return null
        launch.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
        return PendingIntent.getActivity(context, 0, launch, flags)
    }
}
