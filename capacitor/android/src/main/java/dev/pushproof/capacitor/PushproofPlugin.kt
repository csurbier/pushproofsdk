package dev.pushproof.capacitor

import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import dev.pushproof.PushproofCore

/**
 * Pont Capacitor ↔ SDK natif Android. Relaie vers PushproofCore. La capture de
 * livraison se fait dans PushproofMessagingService (cœur natif), pas ici.
 */
@CapacitorPlugin(name = "Pushproof")
class PushproofPlugin : Plugin() {

    @PluginMethod
    fun configure(call: PluginCall) {
        val ingestUrl = call.getString("ingestUrl")
        val ingestKey = call.getString("ingestKey")
        if (ingestUrl == null || ingestKey == null) {
            call.reject("ingestUrl et ingestKey sont requis")
            return
        }
        PushproofCore.configure(context, ingestUrl, ingestKey)
        call.resolve()
    }

    @PluginMethod
    fun recordDelivery(call: PluginCall) {
        val notifId = call.getString("notifId")
        if (notifId == null) {
            call.reject("notifId requis")
            return
        }
        val config = PushproofCore.config(context)
        if (config == null) {
            call.reject("configure() doit être appelé d'abord")
            return
        }
        dev.pushproof.ReceiptSender.send(context, notifId, call.getString("userId"), config) { ok ->
            call.resolve(JSObject().put("accepted", ok))
        }
    }

    @PluginMethod
    fun getPendingReceipts(call: PluginCall) {
        // Android poste l'accusé directement depuis le service ; pas de file App Group.
        call.resolve(JSObject().put("receipts", org.json.JSONArray()))
    }
}
