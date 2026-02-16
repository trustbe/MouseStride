// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MouseStride",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "MouseStride",
            path: "Sources/MouseStride",
            exclude: ["App/Info.plist"]
        )
    ]
)
