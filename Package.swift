// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MouseStride",
    platforms: [.macOS(.v13)],
    targets: [
        .target(
            name: "MouseStrideCore",
            path: "Sources/MouseStrideCore"
        ),
        .executableTarget(
            name: "MouseStride",
            dependencies: ["MouseStrideCore"],
            path: "Sources/MouseStride",
            exclude: ["App/Info.plist", "Resources"]
        ),
        .executableTarget(
            name: "MouseStrideDaemon",
            dependencies: ["MouseStrideCore"],
            path: "Sources/MouseStrideDaemon",
            exclude: ["App/Info.plist", "Resources"]
        )
    ]
)
