// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BridgetStatistics",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "BridgetStatistics",
            targets: ["BridgetStatistics"]),
    ],
    dependencies: [
        .package(path: "../BridgetCore"),
        .package(path: "../BridgetSharedUI")
    ],
    targets: [
        .target(
            name: "BridgetStatistics",
            dependencies: [
                "BridgetCore",
                "BridgetSharedUI"
            ]),
        .testTarget(
            name: "BridgetStatisticsTests",
            dependencies: ["BridgetStatistics"]),
    ]
)