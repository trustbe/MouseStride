import AppKit
import CoreGraphics

final class DistanceCalculator {
    private static let fallbackMMPerPoint: CGFloat = 0.2646 // 96 DPI

    private var mmPerPoint: CGFloat

    init() {
        mmPerPoint = Self.calculateMMPerPoint()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func pointsToMM(_ points: CGFloat) -> Double {
        return Double(points * mmPerPoint)
    }

    @objc private func screenParametersChanged(_ notification: Notification) {
        mmPerPoint = Self.calculateMMPerPoint()
    }

    private static func calculateMMPerPoint() -> CGFloat {
        guard let screen = NSScreen.main else {
            return fallbackMMPerPoint
        }
        let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
            ?? CGMainDisplayID()
        let physicalSize = CGDisplayScreenSize(displayID) // in mm
        let screenWidth = screen.frame.width // in points

        guard physicalSize.width > 0, screenWidth > 0 else {
            return fallbackMMPerPoint
        }
        return physicalSize.width / screenWidth
    }

    static func mmPerPoint(for screenLocation: NSPoint) -> CGFloat {
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(screenLocation) }) else {
            return fallbackMMPerPoint
        }
        let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
            ?? CGMainDisplayID()
        let physicalSize = CGDisplayScreenSize(displayID)
        let screenWidth = screen.frame.width

        guard physicalSize.width > 0, screenWidth > 0 else {
            return fallbackMMPerPoint
        }
        return physicalSize.width / screenWidth
    }
}
