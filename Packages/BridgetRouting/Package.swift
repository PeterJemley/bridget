// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BridgetRouting",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "BridgetRouting",
            targets: ["BridgetRouting"]),
    ],
    dependencies: [
        .package(path: "../BridgetCore"),
        .package(path: "../BridgetSharedUI")
    ],
    targets: [
        .target(
            name: "BridgetRouting",
            dependencies: ["BridgetCore", "BridgetSharedUI"]),
        .testTarget(
            name: "BridgetRoutingTests",
            dependencies: ["BridgetRouting"]),
    ]
) 