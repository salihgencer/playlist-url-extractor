// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "YouTubeExtractor",
    platforms: [.macOS(.v13)],
    targets: [
        .target(
            name: "YouTubeExtractorLib",
            path: "Sources/YouTubeExtractorLib"
        ),
        .executableTarget(
            name: "YouTubeExtractor",
            dependencies: ["YouTubeExtractorLib"],
            path: "Sources/YouTubeExtractor"
        ),
        .testTarget(
            name: "YouTubeExtractorTests",
            dependencies: ["YouTubeExtractorLib"],
            path: "Tests/YouTubeExtractorTests"
        )
    ]
)
