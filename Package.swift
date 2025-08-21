// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let repository = "Lakr233/WhisperKit"
let binaryHash = "be85f4dd1b3f537d56a2b8185593e93e8fc63cb484b2476187ac936e709c2f35"

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
        .library(name: "WhisperKit", type: .static, targets: ["WhisperKit"]),
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
