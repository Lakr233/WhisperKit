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
                .copy("Resources/ggml-silero-v5.1.2"),
            ]
        ),
        .binaryTarget(
            name: "whisper",
            url: "https://github.com/Lakr233/WhisperKit/releases/download/whisper.xcframework/e4fd5593a23ea7e4eade2c7dbc926f667c62eaad91c8023ae7f64679a4109cac-whisper.xcframework.zip",
            checksum: "e4fd5593a23ea7e4eade2c7dbc926f667c62eaad91c8023ae7f64679a4109cac"
        ),
    ]
)
