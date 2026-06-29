# Pushproof SDK

Open-source (MIT) native SDK for **[Pushproof](https://pushproof.dev/en/)** — device-level
**push notification delivery confirmation** on iOS (NSE) and Android
(FirebaseMessagingService), plus the **Capacitor** wrapper.

Core-first architecture: the core is native and reusable; ecosystem wrappers are thin
bridges only.

| | |
|---|---|
| **Website** | [pushproof.dev](https://pushproof.dev/en/) |
| **Product docs** | [pushproof.dev/en/docs](https://pushproof.dev/en/docs/) |
| **Dashboard** | [app.pushproof.dev](https://app.pushproof.dev) |
| **API reference** | [pushproof.dev/docs/#partie-api](https://pushproof.dev/docs/#partie-api) |

> This repo is the **open-source SDK** (runs on the device). 
> Sign up on [Pushproof](https://app.pushproof.dev/) for the managed backend: ingestion, delivery-rate metrics, retention, and dashboard. 
> Ingest endpoint: `api.pushproof.dev/v1/receipts`.

## What it does

- **iOS** — a Notification Service Extension (NSE) captures the delivery **before display**, even
  app-closed/background. Foreground deliveries are captured in-app via `recordDelivery()`. Receipts
  the NSE queued while offline are replayed via `getPendingReceipts()`.
- **Android** — a `FirebaseMessagingService` captures **data-only** messages. The SDK also, when
  `displayNotification` is on (default), **shows** the notification (data-only pushes don't display by
  themselves) and **forwards** it to your Capacitor push listeners (foreground → `pushNotificationReceived`,
  tap → `pushNotificationActionPerformed`).
- **Per-user tracking (Pro)** — `identify({ userId })` tags the device, so "did this user receive it?"
  works **even for batch/multicast sends** (where a shared payload can't carry a per-user id).
- **Campaign attribution** — reads `campaign` from the push payload and relays it on the receipt, so
  delivered lines up with `POST /v1/sent` per campaign.
- **Non-blocking & resilient** — sends run off the main thread with bounded timeouts; a slow/unreachable
  backend never blocks the app. iOS rate is a **lower bound** (iOS may suspend the NSE).

## API at a glance (Capacitor wrapper)

| Method | Description |
|--------|-------------|
| `configure({ ingestUrl, ingestKey, appGroup?, displayNotification? })` | **Required**, at startup. `appGroup` = iOS App Group (app ↔ NSE). `displayNotification` = Android data-only display (default `true`). |
| `identify({ userId })` / `clearIdentity()` | Per-user tracking — call at login / logout. Mono-account. |
| `recordDelivery({ notifId, campaign?, userId? })` | Foreground capture (iOS). Idempotent (server dedups). |
| `getPendingReceipts()` | Replay receipts the NSE queued during degraded network (iOS). |

Native APIs mirror these: Swift `Pushproof.shared.*` (`PushproofCore`) and Kotlin `dev.pushproof.PushproofCore` /
`PushproofMessagingService`. **Full integration guide:** [pushproof.dev/docs](https://pushproof.dev/docs/).

## Repository structure

```
Package.swift  +  Sources/   Swift Package "Pushproof" (iOS) : repo root (required by SPM)
  Sources/PushproofCore/       In-app API, App Group, receipt posting
  Sources/PushproofNSE/        NotificationService (imported by the NSE target)
android/                       Kotlin library (dev.pushproof) — required by JitPack
  PushproofMessagingService    FCM data-only capture (override or delegate)
  NotificationDisplay          shows data-only notifications (displayNotification)
  CapacitorPushForwarder       forwards data-only pushes to Capacitor listeners
capacitor/                     @pushproof/capacitor (npm) : wrapper for Capacitor
INSTALL-iOS-NSE.md             Official NSE setup guide (iOS only)
```

## Installation

### iOS (Swift Package)

`File → Add Package Dependencies…` → `https://github.com/csurbier/pushproofsdk`
(version **1.3.3** — pin the `1.3.3` git tag), then link **PushproofCore** (app)
and **PushproofNSE** (NSE target). See
[pushproof.dev/docs/#ios-nse](https://pushproof.dev/docs/#ios-nse) or [INSTALL-iOS-NSE.md](INSTALL-iOS-NSE.md).

### Android (Gradle)

Published via [JitPack](https://jitpack.io). Add the repository (in
`settings.gradle` › `dependencyResolutionManagement`, or the root `build.gradle`):

```gradle
repositories {
    maven { url 'https://jitpack.io' }
}
```

then the dependency:

```gradle
implementation 'com.github.csurbier:pushproofsdk:1.3.3'
```

> **Capacitor users don't need this** — the native core is bundled inside
> `@pushproof/capacitor`.

### Capacitor

```bash
npm install @pushproof/capacitor@1.3.3
npx cap sync
```

Full integration guide: [pushproof.dev/docs](https://pushproof.dev/docs/) (see also [capacitor/README.md](capacitor/README.md)).

## Open source vs. managed backend

The SDK code here is **free and inspectable** (it runs on the device). The
[Pushproof](https://pushproof.dev/en/) SaaS provides the **managed backend**:
scalable ingestion, delivery-rate computation, data retention, and the
[dashboard](https://app.pushproof.dev). Create a project there to obtain your
`pk_ingest_…` key.

> **iOS**: the measured rate is a **lower bound** (iOS may suspend the NSE).


## License

MIT — see [LICENSE](LICENSE).

## Contact

[Contact us](mailto:contact@pushproof.dev) for support or to request a feature.