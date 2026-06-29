# iOS NSE target setup — official guide

iOS delivery confirmation relies on a **Notification Service Extension (NSE)**:
a separate Xcode target that iOS wakes when a notification with
`mutable-content: 1` arrives, **before** it is displayed, including when the app
is closed.

> This guide is the **official, supported path**. We do not force-patch your
> `.xcodeproj` (a fragile format across Xcode versions). The
> `npx pushproof-install-nse` script is a best-effort assistant that checks
> prerequisites and reminds you of these steps.

Throughout this guide, `<BUNDLE_ID>` is **your app's** bundle id (e.g.
`com.example.myapp`). The NSE target and App Group are derived from it. Pushproof
does not own any bundle id here: the NSE is compiled in your project and signed
with **your** Apple certificate.

---

## 1. Create the NSE target

In Xcode:

1. **File → New → Target…**
2. Choose **Notification Service Extension**.
3. **Product Name**: `PushproofNotificationExtension`.
4. Enable the scheme if Xcode offers to do so.

Xcode generates a `NotificationService.swift` file in the
`PushproofNotificationExtension/` folder.

> ⚠️ **Do NOT name the target `PushproofNSE`.** That is the name of the SDK's
> Swift Package **product** — a target with the same name shadows it, so
> `import PushproofNSE` would import your *own* (empty) target and you'd get
> *"Cannot find type PushproofNotificationService"*. Any name other than
> `PushproofNSE` / `PushproofCore` works; we use `PushproofNotificationExtension`.

## 2. Add the `Pushproof` Swift Package

1. **File → Add Package Dependencies…**
2. Repository URL: `https://github.com/csurbier/pushproofsdk`
   (`Package.swift` is at the repo root). Pin version **1.3.0** (git tag `1.3.0`).
3. Link the products (General → Frameworks, Libraries, and Embedded Content):
   - **PushproofCore** → **App** target.
   - **PushproofNSE** (the *package product*, not a target) → **PushproofNotificationExtension** target.

> Tip: if you see *"File is part of module PushproofNSE"*, the target itself is
> still named `PushproofNSE` — rename it (or set its **PRODUCT_MODULE_NAME** to
> something else, e.g. `PushproofNotificationExt`).

## 3. Replace the generated code

Replace the entire contents of `PushproofNotificationExtension/NotificationService.swift` with:

```swift
import PushproofNSE

class NotificationService: PushproofNotificationService {}
```

That's it: the base class posts the receipt and then passes the notification through.

## 4. Enable App Groups (app **and** NSE)

The App Group is the only channel between the app and the NSE (separate processes).
It carries the endpoint, ingest key, and installation identifier.

For **each** target (App and PushproofNotificationExtension):

1. **Signing & Capabilities → + Capability → App Groups**.
2. Add **the same** group: `group.<BUNDLE_ID>`.

## 5. Declare the App Group to the NSE (required)

The NSE reads the App Group name from its own Info.plist. In the
**PushproofNotificationExtension target Info.plist**, add:

| Key | Type | Value |
|-----|------|--------|
| `PushproofAppGroup` | String | `group.<BUNDLE_ID>` |

> This key is **required** with a custom target name. (Only when the target's
> bundle id ends in `.nse` does the SDK fall back to deriving the group from it —
> not the case here, so set the key explicitly.)

*(Without this key, the NSE falls back to `group.<BUNDLE_ID>` derived from its own
bundle id `<BUNDLE_ID>.nse` , which works in the standard case.)*

## 6. Configure the main app with the same App Group

The NSE runs in a **separate process**. It reads the ingest URL, ingest key, and
device id from the **App Group** — but only the **main app** can write that
config (via `configure()`). The `appGroup` value must match steps 4 and 5 exactly.

### Capacitor (`@pushproof/capacitor`)

Call `configure()` from your TypeScript/JavaScript at app startup (see
[capacitor/README.md](capacitor/README.md) for the full integration guide):

```ts
import { Pushproof } from '@pushproof/capacitor';

await Pushproof.configure({
  ingestUrl: 'https://api.pushproof.dev/v1/receipts',
  ingestKey: 'pk_ingest_…',
  appGroup:  'group.<BUNDLE_ID>',
});
```

The Capacitor plugin forwards this call to the native `PushproofCore` SDK, which
persists the config into the App Group for the NSE.

### Native Swift (no Capacitor)

Call `Pushproof.shared.configure()` early in your app lifecycle (e.g. in
`AppDelegate.application(_:didFinishLaunchingWithOptions:)`):

```swift
import PushproofCore

Pushproof.shared.configure(
    ingestUrl: "https://api.pushproof.dev/v1/receipts",
    ingestKey: "pk_ingest_…",
    appGroup:  "group.<BUNDLE_ID>"
)
```

Your app target must link **PushproofCore** (step 2). There is no JS/TS layer in
this case: you use the Swift API directly.

## 7. Verify delivery capture

Your backend must send a **real alert notification with
`"mutable-content": 1`** (otherwise iOS will not wake the NSE). ⚠️ A **silent /
data-only** push does **not** trigger the NSE on iOS (data-only is the Android
recommendation). Inject `notif_id` into the payload (and optionally `campaign` to
attribute the delivery, and `user_id` on Pro plans).

## 8. Commit the `ios/` folder

The NSE target lives in your iOS project. **Commit `ios/`**, or re-run the
assistant after each `npx cap add ios` (which regenerates the project).

---

## Test on a real device

The **simulator does not receive APNs pushes**: test on a physical iPhone.
Success criteria: app **closed**, sending a push with `mutable-content: 1`
triggers a visible POST on the backend (and the receipt appears in the dashboard),
subject to known NSE limitations.

> **App in foreground**: iOS may deliver the notification directly to the app
> without going through the NSE. That case is captured **in-app** via
> `Pushproof.recordDelivery()` from your receive listener (see
> [capacitor/README.md — App states](capacitor/README.md#app-states-important)).
> The backend deduplicates, so capturing from both paths never double-counts.

## Troubleshooting

| Symptom | Likely cause |
|----------|----------------|
| No receipts | Missing `mutable-content: 1`, or a **silent** push (no alert) — the NSE only wakes for a real notification. |
| Receipts **only** when app is open | NSE not firing in background: check the NSE target, Swift Package linkage, App Group, and `mutable-content: 1`. (In foreground, `recordDelivery()` captures.) |
| Occasional misses when app is closed | iOS skipped the NSE under memory/battery pressure — expected lower bound, not a bug. |
| NSE crash | `Pushproof` Swift Package not linked to the NSE target, or mismatched App Group. |
| Config not found on NSE side | Missing `PushproofAppGroup` in the NSE Info.plist, or different groups on app vs. NSE. |
