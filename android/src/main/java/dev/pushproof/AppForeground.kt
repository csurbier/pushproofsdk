package dev.pushproof

import androidx.lifecycle.Lifecycle
import androidx.lifecycle.ProcessLifecycleOwner

/** Détecte si l'app est au premier plan (processus visible pour l'utilisateur). */
object AppForeground {

    fun isInForeground(): Boolean = try {
        ProcessLifecycleOwner.get().lifecycle.currentState
            .isAtLeast(Lifecycle.State.STARTED)
    } catch (_: IllegalStateException) {
        false
    }
}
