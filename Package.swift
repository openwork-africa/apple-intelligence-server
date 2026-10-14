// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "apple-intelligence-server",
    platforms: [.macOS("26.0")],
    targets: [
        .target(name: "AppleIntelligenceServer"),
        .executableTarget(name: "apple-intelligence-server", dependencies: ["AppleIntelligenceServer"]),
        .testTarget(name: "AppleIntelligenceServerTests", dependencies: ["AppleIntelligenceServer"]),
    ]
)
