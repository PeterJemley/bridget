// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BridgetDashboard",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "BridgetDashboard",
            targets: ["BridgetDashboard"]),
    ],
    dependencies: [
        .package(path: "../BridgetCore"),
        .package(path: "../BridgetSharedUI"),
        .package(path: "../BridgetBridgeDetail")
    ],
    targets: [
        .target(
            name: "BridgetDashboard",
            dependencies: [
                "BridgetCore",
                "BridgetSharedUI", 
                "BridgetBridgeDetail"
            ]),
        .testTarget(
            name: "BridgetDashboardTests",
            dependencies: ["BridgetDashboard"]),
    ]
)