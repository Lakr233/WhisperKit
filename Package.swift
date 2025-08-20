// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WhisperKit",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .tvOS(.v15),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "WhisperKit", targets: ["WhisperKit"]),
    ],
    targets: [
        .target(
            name: "WhisperKit",
            dependencies: [
                .target(name: "whisper"),
            ],
            resources: [
                .copy("Resources/Models/ggml-silero-v5.1.2.bin"),
            ]
        ),
        .binaryTarget(
            name: "whisper",
            path: "./BinaryTarget/whisper.xcframework.zip"
        ),
    ]
)
