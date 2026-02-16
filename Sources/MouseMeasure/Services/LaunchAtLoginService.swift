import Foundation

enum LaunchAtLoginService {
    private static let label = "com.mousestride.launcher"

    private static var plistURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(label).plist")
    }

    static var isEnabled: Bool {
        FileManager.default.fileExists(atPath: plistURL.path)
    }

    static func toggle() {
        if isEnabled {
            disable()
        } else {
            enable()
        }
    }

    private static func enable() {
        let executablePath = ProcessInfo.processInfo.arguments[0]

        let plist: [String: Any] = [
            "Label": label,
            "ProgramArguments": [executablePath],
            "RunAtLoad": true,
            "KeepAlive": false
        ]

        let data = try? PropertyListSerialization.data(
            fromPropertyList: plist,
            format: .xml,
            options: 0
        )

        FileManager.default.createFile(atPath: plistURL.path, contents: data)
    }

    private static func disable() {
        try? FileManager.default.removeItem(at: plistURL)
    }
}
