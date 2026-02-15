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
    @Published var lastMilestoneTitle: String? = nil
    @Published var nextMilestoneText: String? = nil
    @Published var unitSystem: UnitSystem {
        didSet {
            UserDefaults.standard.set(unitSystem.rawValue, forKey: "unitSystem")
            updateStatusBar()
            updateAvgSpeed()
        }
    }

    private let mouseTracker = MouseTracker()
    private let distanceCalculator = DistanceCalculator()
    private let persistence = PersistenceService()
    private let milestones = MilestoneService()

    private var uiTimer: Timer?
    private var saveTimer: Timer?
    private var sessionStartDate = Date()

    /// Points accumulated since last UI update, converted to mm and added to running totals
    private var pendingMM: Double = 0

    init() {
        let saved = UserDefaults.standard.string(forKey: "unitSystem") ?? UnitSystem.metric.rawValue
        unitSystem = UnitSystem(rawValue: saved) ?? .metric

        totalDistanceMM = persistence.totalDistanceMM
        todayDistanceMM = persistence.todayDistanceMM()
        persistence.pruneOldEntries()
        updateStatusBar()
        updateMilestoneInfo()

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
        milestones.resetMilestones()
        updateStatusBar()
        updateAvgSpeed()
    }

    func quit() {
        save()
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Timers

    private func startTimers() {
        uiTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateFromTracker()
            }
        }

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
        updateMilestoneInfo()
        milestones.checkMilestones(totalMM: totalDistanceMM)
    }

    private func updateMilestoneInfo() {
        if let last = milestones.lastReachedMilestone(totalMM: totalDistanceMM) {
            lastMilestoneTitle = last.title
        } else {
            lastMilestoneTitle = nil
        }
        if let next = milestones.nextMilestone(totalMM: totalDistanceMM) {
            let remaining = next.distanceMM - totalDistanceMM
            nextMilestoneText = "\(next.title.replacingOccurrences(of: "!", with: "")) in \(DistanceUnit.autoFormat(mm: remaining, system: unitSystem))"
        } else {
            nextMilestoneText = nil
        }
    }

    private func updateStatusBar() {
        statusBarText = DistanceUnit.autoFormat(mm: totalDistanceMM, system: unitSystem)
    }

    private func updateAvgSpeed() {
        let elapsed = Date().timeIntervalSince(sessionStartDate)
        guard elapsed > 0 else {
            formattedAvgSpeed = unitSystem == .metric ? "0 mm/s" : "0 in/s"
            return
        }
        let mmPerSec = sessionDistanceMM / elapsed
        switch unitSystem {
        case .metric:
            if mmPerSec >= 1_000 {
                formattedAvgSpeed = String(format: "%.1f m/s", mmPerSec / 1_000)
            } else if mmPerSec >= 10 {
                formattedAvgSpeed = String(format: "%.1f cm/s", mmPerSec / 10)
            } else {
                formattedAvgSpeed = String(format: "%.1f mm/s", mmPerSec)
            }
        case .imperial:
            let inPerSec = mmPerSec / 25.4
            if inPerSec >= 12 {
                formattedAvgSpeed = String(format: "%.1f ft/s", inPerSec / 12)
            } else {
                formattedAvgSpeed = String(format: "%.1f in/s", inPerSec)
            }
        }
    }

    // MARK: - Persistence (drain-and-fold)

    private func save() {
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
