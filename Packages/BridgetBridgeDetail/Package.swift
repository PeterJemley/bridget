// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BridgetBridgeDetail",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "BridgetBridgeDetail",
            targets: ["BridgetBridgeDetail"]),
    ],
    dependencies: [
        .package(path: "../BridgetCore"),
        .package(path: "../BridgetSharedUI")
    ],
    targets: [
        .target(
            name: "BridgetBridgeDetail",
            dependencies: [
                "BridgetCore",
                "BridgetSharedUI"
            ]),
        .testTarget(
            name: "BridgetBridgeDetailTests",
            dependencies: ["BridgetBridgeDetail"]),
    ]
)