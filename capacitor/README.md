# @pushproof/capacitor

Capacitor wrapper for [Pushproof](https://pushproof.dev) — device-level push delivery
confirmation on iOS (NSE) and Android (FCM data-only).

## Quick start

```bash
npm install @pushproof/capacitor@1.3.3
npx cap sync ios android
```

```ts
import { Pushproof } from '@pushproof/capacitor';

await Pushproof.configure({
  ingestUrl: 'https://api.pushproof.dev/v1/receipts',
  ingestKey: 'pk_ingest_…',
  appGroup: 'group.com.example.app',
});
```

Get your ingest key from the [dashboard](https://app.pushproof.dev).

## Full integration guide

**Canonical documentation** (Capacitor app, sending backend, API reference):

- **French:** [pushproof.dev/docs](https://pushproof.dev/docs/)
- **English:** [pushproof.dev/en/docs](https://pushproof.dev/en/docs/)

Covers Capacitor 8 + SPM, iOS NSE setup, Android data-only payloads, `mutable-content`
for iOS, `POST /v1/sent`, foreground `recordDelivery()`, tap listeners, and troubleshooting.

## iOS NSE assistant

```bash
npx pushproof-install-nse
```

Checks prerequisites and prints the Xcode steps. Details: [pushproof.dev/docs/#ios-nse](https://pushproof.dev/docs/#ios-nse).

## API surface

| Method | Description |
|--------|-------------|
| `configure(config)` | Required — ingest URL, key, App Group, `displayNotification` (Android). |
| `identify({ userId })` | Tag device with user (Pro). |
| `clearIdentity()` | Clear user tag on logout. |
| `recordDelivery({ notifId, campaign?, userId? })` | Foreground capture (iOS). Idempotent. |
| `getPendingReceipts()` | Flush NSE-queued receipts (iOS). |

Types: [`src/definitions.ts`](src/definitions.ts).

## Pure native (without Capacitor)

- **iOS:** Swift Package `https://github.com/csurbier/pushproofsdk` — products `PushproofCore` + `PushproofNSE`.
- **Android:** JitPack `com.github.csurbier:pushproofsdk:1.3.3`.

Same protocol and endpoints — see the [integration guide](https://pushproof.dev/docs/#natif).

## License

MIT.
