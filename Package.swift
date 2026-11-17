// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LidToggle",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "LidToggle", targets: ["LidToggle"])],
    targets: [
        .executableTarget(name: "LidToggle"),
        .testTarget(name: "LidToggleTests", dependencies: ["LidToggle"])
    ]
)
