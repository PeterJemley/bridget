// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BridgetSettings",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "BridgetSettings",
            targets: ["BridgetSettings"]),
    ],
    dependencies: [
        .package(path: "../BridgetCore"),
        .package(path: "../BridgetNetworking")
    ],
    targets: [
        .target(
            name: "BridgetSettings",
            dependencies: [
                "BridgetCore",
                "BridgetDashboard",
                "BridgetNetworking"
            ]),
        .testTarget(
            name: "BridgetSettingsTests",
            dependencies: ["BridgetSettings"]),
    ]
)