// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VibeNotes",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "VibeNotes",
            dependencies: [])
    ]
)
