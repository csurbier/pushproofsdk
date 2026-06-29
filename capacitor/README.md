# @pushproof/capacitor

**Real delivery confirmation** for your push notifications, at the device level
(iOS NSE + Android FCM). Keep your existing FCM/APNs sending stack; the plugin
reports a "this notification arrived" receipt to the Pushproof backend, which
computes the delivery rate and displays it in the [dashboard](https://app.pushproof.dev).

---

## Prerequisites

- A **Capacitor** app (Ionic/Angular, etc.) already set up to receive push
  notifications via FCM (Android) and APNs (iOS) — including **push token
  registration** handled by your own stack (`@capacitor/push-notifications`,
  Firebase SDK, native code, etc.). Pushproof does not manage permissions or
  device tokens.
- An **ingest key** (`pk_ingest_…`) generated from the Pushproof dashboard.
  It is *public* (write-only): safe to embed in the app.

## Installation

```bash
npm install @pushproof/capacitor@1.2.0
npx cap sync
```

## 1. Configure (TypeScript)

At app startup — this is **all Pushproof needs** to capture deliveries and post
receipts to `api.pushproof.dev`:

```ts
import { Pushproof } from '@pushproof/capacitor';

await Pushproof.configure({
  ingestUrl: 'https://api.pushproof.dev/v1/receipts',
  ingestKey: 'pk_ingest_…',           // public key from the dashboard
  appGroup:  'group.com.example.app', // iOS only (see iOS setup)
});
```

Pushproof identifies each installation with an **anonymous `installId`** (generated
locally, sent as `device` in receipts). It does **not** use the FCM/APNs push token —
you continue to register and forward tokens to **your sending backend** as you
already do today.

## 2. Sending side (your backend) — required

For Pushproof to correlate "sent" and "delivered", your sending backend must,
**for every push**:

- generate a `notif_id` (UUID) and **inject it into the payload**;
- **iOS**: send a **real alert notification with `"mutable-content": 1`**. This
  is what wakes the NSE. ⚠️ A **silent / data-only** push (content-available,
  no alert) does **not** trigger the NSE on iOS.
- **Android**: send a **data-only** message (no `notification` block). This
  ensures `onMessageReceived`, including when the app is in the background. A
  *notification message* in the background goes to the system tray **without**
  calling the service.
- *(optional)* inject a `campaign` label to attribute the **delivered** receipt
  to a campaign. Use the **same label** you pass to `POST /v1/sent`, so delivered
  and sent line up per campaign in the dashboard. Without it, deliveries are
  recorded with an empty campaign and won't join your `/v1/sent` declarations.
- *(optional, Pro — single-recipient only)* inject an opaque `user_id` for
  per-user tracking. ⚠️ This only works for **one-to-one** sends. For **batch /
  multicast** sends the payload is shared by all recipients and **cannot** carry a
  per-user id — use device-side `identify()` instead (see next section).

Example FCM payload (data-only):

```json
{
  "message": {
    "token": "<device_token>",
    "apns": { "payload": { "aps": { "mutable-content": 1 } } },
    "data": {
      "notif_id": "8f14e45f-ceea-467d-9a3b-2c1d4f5e6a7b",
      "campaign": "promo_2026_06",
      "user_id":  "usr_4f3a9c",
      "title": "…", "body": "…"
    }
  }
}
```

The SDK reads `notif_id`, `campaign` and `user_id` from the payload and relays them
on the receipt — it never invents them. Also declare your sends via `POST /v1/sent`
(with the same `campaign`) to get a true *rate* (delivered / sent). See the
[API reference](https://app.pushproof.dev/docs).

## 2b. Per-user tracking (Pro) — device-side identity

To answer *"did **this user** receive this notification?"* with **batch sends**,
tag the user **on the device**, not in the payload. The app knows who is logged in;
the SDK attaches that `userId` to every receipt — the only thing that survives a
shared multicast payload.

```ts
import { Pushproof } from '@pushproof/capacitor';

// on login
await Pushproof.identify({ userId: 'usr_4f3a9c' });

// on logout
await Pushproof.clearIdentity();
```

- **Mono-account**: one user per device; the last `identify()` wins (call it again
  on account switch). `clearIdentity()` on logout.
- On iOS the identity is stored in the **App Group** so the NSE attaches it even
  when the app is closed.
- `userId` must be an **opaque** id (never email/phone) — it is hashed server-side.
- A `user_id` in the payload (single-recipient sends) still works and **overrides**
  the device identity for that push.

## 3. iOS setup (NSE target)

iOS capture happens in a **Notification Service Extension** — a separate Xcode
target (the NSE does not run in the webview and is not reachable from any
bridge). Assisted setup:

```bash
npx pushproof-install-nse
```

The script checks prerequisites and prints the steps. Full details:
[INSTALL-iOS-NSE.md](../INSTALL-iOS-NSE.md). In short:

1. Create a **Notification Service Extension** target named `PushproofNSE`.
2. Its `NotificationService.swift` reduces to:
   ```swift
   import PushproofNSE
   class NotificationService: PushproofNotificationService {}
   ```
3. Enable **App Groups** (same group `group.<BUNDLE_ID>`) on the app **and** the NSE.
4. Add `PushproofAppGroup = group.<BUNDLE_ID>` to the NSE Info.plist.

## 4. Android setup

Two cases:

**A. You do not have your own `FirebaseMessagingService`** → declare Pushproof's
in `android/app/src/main/AndroidManifest.xml`:

```xml
<service
    android:name="dev.pushproof.PushproofMessagingService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>
```

**B. You already have an FCM service** → call the Pushproof core from your
`onMessageReceived` (do not add two services):

```kotlin
import dev.pushproof.PushproofMessagingService

override fun onMessageReceived(message: RemoteMessage) {
    PushproofMessagingService.handle(this, message)
    // … your existing logic …
}
```

> Send **data-only** messages: Android does not always invoke
> `onMessageReceived` for *notification messages* in the background.

## App states (important)

The capture path depends on the platform **and** app state:

| State | iOS | Android |
|-------|-----|---------|
| **Closed / background** | NSE (reliable, captures) | `onMessageReceived` (data-only) |
| **Foreground (open)** | NSE **may be bypassed** → call `recordDelivery()` | `onMessageReceived` runs → captured |

In other words, on **iOS with the app open**, iOS often delivers the notification
directly to the app without going through the NSE. To avoid gaps, call
`recordDelivery()` from your **foreground receive listener**. If the NSE *also*
captured it, the backend **deduplicates** on `(notif_id, device)` — never double-counts.

```ts
import { PushNotifications } from '@capacitor/push-notifications';
import { Pushproof } from '@pushproof/capacitor';

// App in foreground: capture delivery in-app (especially iOS)
PushNotifications.addListener('pushNotificationReceived', (notif) => {
  const notifId = notif.data?.notif_id;
  if (notifId) {
    // userId not needed here: identify() already tags the device
    Pushproof.recordDelivery({ notifId, campaign: notif.data?.campaign });
  }
});
```

> On Android, `recordDelivery()` is unnecessary (the service already captures in
> foreground) but harmless — calling it on both platforms is safe.

## API

| Method | Description |
|--------|-------------|
| `configure(config)` | **Required.** Registers `ingestUrl`, `ingestKey`, `appGroup`. |
| `identify({ userId })` | Tags the device with a user (Pro). Call at login. Mono-account. |
| `clearIdentity()` | Removes the device↔user link. Call at logout. |
| `recordDelivery({ notifId, campaign?, userId? })` | Captures a delivery in-app (iOS foreground). Idempotent. |
| `getPendingReceipts()` | Receipts queued by the NSE during degraded network (iOS). |

Full types in [`src/definitions.ts`](src/definitions.ts).

## Pure native (without Capacitor)

The native SDK can also be used directly, without a wrapper — same protocol, same
endpoints:

- **iOS**: add the `Pushproof` Swift Package (`https://github.com/csurbier/pushproofsdk`).
- **Android**: via [JitPack](https://jitpack.io) — add `maven { url 'https://jitpack.io' }`,
  then `implementation 'com.github.csurbier:pushproofsdk:1.2.0'`.

> When using `@pushproof/capacitor`, the Android core is already bundled in the
> plugin — you don't add the JitPack dependency.

## Limitations

- **iOS = lower bound**: the NSE may be skipped by iOS (memory/battery) or killed
  before the network call completes. Never promise 100% delivery.
- The NSE target must exist in **every** app (Apple constraint, independent of
  framework). Commit the `ios/` folder or re-run `install-nse` after
  `cap add ios`.

## License

MIT. The SDK and wrapper are open-source; only the managed backend (ingestion,
metrics, dashboard) is the paid offering.
