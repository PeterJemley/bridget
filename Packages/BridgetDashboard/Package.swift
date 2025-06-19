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
        .package(path: "../BridgetNetworking"),
        .package(path: "../BridgetSharedUI")
    ],
    targets: [
        .target(
            name: "BridgetDashboard",
            dependencies: [
                "BridgetCore",
                "BridgetNetworking", 
                "BridgetSharedUI"
            ]),
        .testTarget(
            name: "BridgetDashboardTests",
            dependencies: ["BridgetDashboard"]),
    ]
)