// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MouseMeasure",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "MouseMeasure",
            path: "Sources/MouseMeasure",
            exclude: ["App/Info.plist"]
        )
    ]
)
