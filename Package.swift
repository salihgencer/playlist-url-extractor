// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "PlaylistURLExtractor",
    defaultLocalization: "en",
    platforms: [.macOS(.v13)],
    products: [
        // Xcode uygulama hedefi (project.yml) bu ürünü bağlar.
        .library(name: "PlaylistURLExtractorKit", targets: ["PlaylistURLExtractorKit"])
    ],
    targets: [
        .target(
            name: "PlaylistURLExtractorKit",
            path: "Sources/PlaylistURLExtractorKit",
            resources: [.process("Resources")]
        ),
        // Yalnız geliştirme: `swift run PlaylistURLExtractorDev`. App Store derlemesi Xcode projesinden.
        .executableTarget(
            name: "PlaylistURLExtractorDev",
            dependencies: ["PlaylistURLExtractorKit"],
            path: "Sources/PlaylistURLExtractorDev"
        ),
        .testTarget(
            name: "PlaylistURLExtractorKitTests",
            dependencies: ["PlaylistURLExtractorKit"],
            path: "Tests/PlaylistURLExtractorKitTests"
        )
    ]
)
