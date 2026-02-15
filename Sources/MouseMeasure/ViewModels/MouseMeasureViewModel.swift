import AppKit
import Combine
import SwiftUI

@MainActor
final class MouseMeasureViewModel: ObservableObject {
    @Published var sessionDistanceMM: Double = 0
    @Published var todayDistanceMM: Double = 0
    @Published var totalDistanceMM: Double = 0
    @Published var statusBarText: String = "0 mm"
    @Published var formattedAvgSpeed: String = "0 mm/s"

    private let mouseTracker = MouseTracker()
    private let distanceCalculator = DistanceCalculator()
    private let persistence = PersistenceService()

    private var uiTimer: Timer?
    private var saveTimer: Timer?
    private var sessionStartDate = Date()

    /// Points accumulated since last UI update, converted to mm and added to running totals
    private var pendingMM: Double = 0

    init() {
        totalDistanceMM = persistence.totalDistanceMM
        todayDistanceMM = persistence.todayDistanceMM()
        persistence.pruneOldEntries()
        updateStatusBar()

        mouseTracker.start()
        startTimers()
        setupTerminationObserver()
    }

    deinit {
        uiTimer?.invalidate()
        saveTimer?.invalidate()
    }

    func resetSession() {
        sessionDistanceMM = 0
        sessionStartDate = Date()
        updateStatusBar()
        updateAvgSpeed()
    }

    func resetToday() {
        todayDistanceMM = 0
        if pendingMM > 0 {
            save()
        }
        persistence.resetToday()
        updateStatusBar()
    }

    func resetAll() {
        sessionDistanceMM = 0
        todayDistanceMM = 0
        totalDistanceMM = 0
        pendingMM = 0
        sessionStartDate = Date()
        persistence.resetAll()
        updateStatusBar()
        updateAvgSpeed()
    }

    func quit() {
        save()
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Timers

    private func startTimers() {
        // UI update every 1 second
        uiTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateFromTracker()
            }
        }

        // Persist every 30 seconds
        saveTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.save()
            }
        }
    }

    private func updateFromTracker() {
        let points = mouseTracker.drainAccumulatedPoints()
        if points > 0 {
            let mm = distanceCalculator.pointsToMM(points)
            sessionDistanceMM += mm
            todayDistanceMM += mm
            totalDistanceMM += mm
            pendingMM += mm
        }

        updateStatusBar()
        updateAvgSpeed()
    }

    private func updateStatusBar() {
        statusBarText = DistanceUnit.autoFormat(mm: totalDistanceMM)
    }

    private func updateAvgSpeed() {
        let elapsed = Date().timeIntervalSince(sessionStartDate)
        guard elapsed > 0 else {
            formattedAvgSpeed = "0 mm/s"
            return
        }
        let mmPerSec = sessionDistanceMM / elapsed
        if mmPerSec >= 1_000 {
            formattedAvgSpeed = String(format: "%.1f m/s", mmPerSec / 1_000)
        } else if mmPerSec >= 10 {
            formattedAvgSpeed = String(format: "%.1f cm/s", mmPerSec / 10)
        } else {
            formattedAvgSpeed = String(format: "%.1f mm/s", mmPerSec)
        }
    }

    // MARK: - Persistence (drain-and-fold)

    private func save() {
        // Drain pending mm into persistence
        if pendingMM > 0 {
            persistence.totalDistanceMM += pendingMM
            persistence.addToToday(mm: pendingMM)
            pendingMM = 0
        }
    }

    private func setupTerminationObserver() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                let points = self.mouseTracker.drainAccumulatedPoints()
                if points > 0 {
                    self.pendingMM += self.distanceCalculator.pointsToMM(points)
                }
                self.save()
            }
        }
    }
}
