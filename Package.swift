// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GPIO",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "GPIO",
            targets: ["GPIO"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-testing.git", from: "0.10.0")
    ],
    targets: [
        .target(
            name: "GPIO",
            dependencies: []),
        .testTarget(
            name: "GPIOTests",
            dependencies: [
                "GPIO",
                .product(name: "Testing", package: "swift-testing")
            ]),
    ]
)