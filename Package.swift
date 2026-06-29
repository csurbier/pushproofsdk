// swift-tools-version:5.9
// Pushproof iOS SDK v1.3.3
import PackageDescription

// SDK natif iOS Pushproof (SPEC §3/§6). Deux produits :
// - PushproofCore : logique in-app (config, installId, envoi d'accusés, App Group).
// - PushproofNSE  : NotificationService importé par la cible NSE de l'app cliente.
let package = Package(
    name: "Pushproof",
    platforms: [.iOS(.v14)],
    products: [
        .library(name: "PushproofCore", targets: ["PushproofCore"]),
        .library(name: "PushproofNSE", targets: ["PushproofNSE"]),
    ],
    targets: [
        .target(name: "PushproofCore"),
        .target(name: "PushproofNSE", dependencies: ["PushproofCore"]),
    ]
)
