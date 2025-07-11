// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BridgetSharedUI",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "BridgetSharedUI",
            targets: ["BridgetSharedUI"]),
    ],
    dependencies: [
        .package(path: "../BridgetCore")
    ],
    targets: [
        .target(
            name: "BridgetSharedUI",
            dependencies: ["BridgetCore"]),
        .testTarget(
            name: "BridgetSharedUITests",
            dependencies: ["BridgetSharedUI"]),
    ]
)