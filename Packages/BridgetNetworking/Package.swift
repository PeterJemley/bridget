// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BridgetNetworking",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "BridgetNetworking",
            targets: ["BridgetNetworking"]),
    ],
    dependencies: [
        .package(path: "../BridgetCore")
    ],
    targets: [
        .target(
            name: "BridgetNetworking",
            dependencies: ["BridgetCore"]),
        .testTarget(
            name: "BridgetNetworkingTests",
            dependencies: ["BridgetNetworking"]),
    ]
)