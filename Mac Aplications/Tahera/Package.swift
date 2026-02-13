// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Tahera",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "Tahera", targets: ["Tahera"])
    ],
    targets: [
        .executableTarget(
            name: "Tahera",
            path: "Sources/Tahera",
            resources: [.process("Resources")]
        )
    ]
)
