// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let repository = "Lakr233/WhisperKit"
let binaryHash = "09d628e837314129c801c228a12d2f630187441f5987cfc36cd28f9b4db99c91"

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
            url: "https://github.com/\(repository)/releases/download/whisper.xcframework/\(binaryHash)-whisper.xcframework.zip",
            checksum: binaryHash
        ),
    ]
)
