// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BridgetHistory",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "BridgetHistory",
            targets: ["BridgetHistory"]),
    ],
    dependencies: [
        .package(path: "../BridgetCore"),
        .package(path: "../BridgetSharedUI")
    ],
    targets: [
        .target(
            name: "BridgetHistory",
            dependencies: [
                "BridgetCore",
                "BridgetSharedUI"
            ]),
        .testTarget(
            name: "BridgetHistoryTests",
            dependencies: ["BridgetHistory"]),
    ]
)