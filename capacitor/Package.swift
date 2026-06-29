// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PushproofCapacitor",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "PushproofCapacitor",
            targets: ["PushproofPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "8.0.0"),
        .package(url: "https://github.com/csurbier/pushproofsdk", from: "1.3.3"),
    ],
    targets: [
        .target(
            name: "PushproofPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm"),
                .product(name: "PushproofCore", package: "pushproofsdk"),
            ],
            path: "ios/Plugin"
        )
    ]
)
