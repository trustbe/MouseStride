import AppKit
import Foundation

final class MouseTracker {
    private let teleportThreshold: CGFloat = 500.0

    private var previousLocation: NSPoint?
    private var globalMonitor: Any?
    private var localMonitor: Any?

    /// Accumulated distance in points since last drain
    private(set) var accumulatedPoints: CGFloat = 0

    var onDistanceAccumulated: (() -> Void)?

    init() {
        setupSleepWakeObservers()
    }

    deinit {
        stop()
        NotificationCenter.default.removeObserver(self)
    }

    func start() {
        let eventMask: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDragged, .rightMouseDragged]

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: eventMask) { [weak self] event in
            self?.handleMouseEvent(event)
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: eventMask) { [weak self] event in
            self?.handleMouseEvent(event)
            return event
        }

        previousLocation = NSEvent.mouseLocation
    }

    func stop() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
        previousLocation = nil
    }

    /// Drain and return accumulated points, resetting the accumulator to zero
    func drainAccumulatedPoints() -> CGFloat {
        let value = accumulatedPoints
        accumulatedPoints = 0
        return value
    }

    private func handleMouseEvent(_ event: NSEvent) {
        let currentLocation = NSEvent.mouseLocation

        guard let previous = previousLocation else {
            previousLocation = currentLocation
            return
        }

        let dx = currentLocation.x - previous.x
        let dy = currentLocation.y - previous.y
        let distance = sqrt(dx * dx + dy * dy)

        previousLocation = currentLocation

        // Teleport filter: ignore unrealistic jumps
        if distance > teleportThreshold {
            return
        }

        accumulatedPoints += distance
    }

    private func setupSleepWakeObservers() {
        let workspace = NSWorkspace.shared.notificationCenter
        workspace.addObserver(
            self,
            selector: #selector(systemWillSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        workspace.addObserver(
            self,
            selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    @objc private func systemWillSleep(_ notification: Notification) {
        previousLocation = nil
    }

    @objc private func systemDidWake(_ notification: Notification) {
        previousLocation = nil
    }
}
