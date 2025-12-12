// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OutfitPickerCLI",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .watchOS(.v10),
    ],
    products: [
        .library(name: "OutfitPickerCore", targets: ["OutfitPickerCore"]),
        .executable(name: "outfit-picker", targets: ["OutfitPickerCLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0")
    ],
    targets: [
        .target(name: "OutfitPickerCore", dependencies: [], path: "Sources/OutfitPickerCore"),
        .target(
            name: "OutfitPickerTestSupport", dependencies: ["OutfitPickerCore"],
            path: "Sources/OutfitPickerTestSupport"
        ),
        .executableTarget(
            name: "OutfitPickerCLI",
            dependencies: [
                "OutfitPickerCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "OutfitPickerCoreTests",
            dependencies: ["OutfitPickerCore", "OutfitPickerTestSupport"],
            path: "Tests/OutfitPickerCoreTests"
        ),
        .testTarget(
            name: "OutfitPickerCLITests",
            dependencies: ["OutfitPickerCLI", "OutfitPickerTestSupport"],
            path: "Tests/OutfitPickerCLITests"
        ),
    ]
)
