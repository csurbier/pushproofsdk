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
| **API reference** | [app.pushproof.dev/docs](https://app.pushproof.dev/docs) |

> This repo is the **open-source SDK** (runs on the device). 
> Sign up on [Pushproof](https://app.pushproof.dev/) for the managed backend: ingestion, delivery-rate metrics, retention, and dashboard. 
> Ingest endpoint: `api.pushproof.dev/v1/receipts`.

## Repository structure

```
Package.swift  +  Sources/   Swift Package "Pushproof" (iOS) : repo root (required by SPM)
  Sources/PushproofCore/       In-app API, App Group, receipt posting
  Sources/PushproofNSE/        NotificationService (imported by the NSE target)
android/                       Kotlin library (dev.pushproof) (required by JitPack)
capacitor/                     @pushproof/capacitor (npm) : wrapper for Capacitor
INSTALL-iOS-NSE.md             Official NSE setup guide (iOS only)
```

## Installation

### iOS (Swift Package)

`File → Add Package Dependencies…` → `https://github.com/csurbier/pushproofsdk`
(version **1.2.0** — pin the `1.2.0` git tag), then link **PushproofCore** (app)
and **PushproofNSE** (NSE target). See
[INSTALL-iOS-NSE.md](INSTALL-iOS-NSE.md).

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
implementation 'com.github.csurbier:pushproofsdk:1.2.0'
```

> **Capacitor users don't need this** — the native core is bundled inside
> `@pushproof/capacitor`.

### Capacitor

```bash
npm install @pushproof/capacitor@1.2.0
npx cap sync
```

Full integration guide: [capacitor/README.md](capacitor/README.md).

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