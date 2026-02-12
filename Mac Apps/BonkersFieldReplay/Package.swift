// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BonkersFieldReplay",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "BonkersFieldReplay", targets: ["BonkersFieldReplayApp"])
    ],
    targets: [
        .executableTarget(
            name: "BonkersFieldReplayApp",
            path: "Sources/BonkersFieldReplayApp"
        )
    ]
)
