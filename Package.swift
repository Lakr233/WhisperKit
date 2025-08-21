// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WhisperKit",
    platforms: [
        .macOS(.v13),
        .macCatalyst(.v16),
        .iOS(.v16),
        .tvOS(.v16),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "WhisperKit", type: .dynamic, targets: ["WhisperKit"]),
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
            url: "https://github.com/Lakr233/WhisperKit/releases/download/whisper.xcframework/3568601e1090a4a568e1e32d461aebfca196e60b975d7022235038385f678d3f-whisper.xcframework.zip",
            checksum: "3568601e1090a4a568e1e32d461aebfca196e60b975d7022235038385f678d3f"
        ),
    ]
)
