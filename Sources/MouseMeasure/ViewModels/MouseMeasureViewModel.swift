import AppKit
import Combine
import SwiftUI

@MainActor
final class MouseMeasureViewModel: ObservableObject {
    @Published var todayDistanceMM: Double = 0
    @Published var totalDistanceMM: Double = 0
    @Published var statusBarText: String = "0 mm"
    @Published var lastMilestoneTitle: String? = nil
    @Published var lastMilestoneIcon: String? = nil
    @Published var nextMilestoneText: String? = nil
    @Published var nextMilestoneIcon: String? = nil
    @Published var autoShareEnabled: Bool {
        didSet {
            UserDefaults.standard.set(autoShareEnabled, forKey: "autoShareEnabled")
            if autoShareEnabled { startAutoShareTimer() } else { stopAutoShareTimer() }
        }
    }
    var unitSystem: UnitSystem {
        Locale.current.measurementSystem == .metric ? .metric : .imperial
    }

    private let mouseTracker = MouseTracker()
    private let distanceCalculator = DistanceCalculator()
    private let persistence = PersistenceService()
    private let milestones = MilestoneService()

    private var uiTimer: Timer?
    private var saveTimer: Timer?
    private var autoShareTimer: Timer?

    /// Points accumulated since last UI update, converted to mm and added to running totals
    private var pendingMM: Double = 0

    init() {
        autoShareEnabled = UserDefaults.standard.bool(forKey: "autoShareEnabled")
        totalDistanceMM = persistence.totalDistanceMM
        todayDistanceMM = persistence.todayDistanceMM()
        persistence.pruneOldEntries()
        updateStatusBar()
        updateMilestoneInfo()

        mouseTracker.start()
        startTimers()
        if autoShareEnabled { startAutoShareTimer() }
        setupTerminationObserver()
    }

    deinit {
        uiTimer?.invalidate()
        saveTimer?.invalidate()
        autoShareTimer?.invalidate()
    }

    func resetAll() {
        todayDistanceMM = 0
        totalDistanceMM = 0
        pendingMM = 0
        persistence.resetAll()
        milestones.resetMilestones()
        updateStatusBar()
    }

    func quit() {
        save()
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Share Data

    var daysTracked: Int {
        persistence.daysTracked()
    }

    var bestDayMM: Double {
        persistence.bestDayMM()
    }

    var lastReachedMilestone: Milestone? {
        milestones.lastReachedMilestone(totalMM: totalDistanceMM)
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

    private func startAutoShareTimer() {
        autoShareTimer?.invalidate()
        autoShareTimer = Timer.scheduledTimer(withTimeInterval: 900, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.submitToDashboard()
            }
        }
    }

    private func stopAutoShareTimer() {
        autoShareTimer?.invalidate()
        autoShareTimer = nil
    }

    private func submitToDashboard() {
        DashboardService.submit(
            todayMM: todayDistanceMM,
            totalMM: totalDistanceMM,
            bestDayMM: bestDayMM,
            daysTracked: daysTracked,
            milestone: lastReachedMilestone?.title
        )
    }

    private func updateFromTracker() {
        let points = mouseTracker.drainAccumulatedPoints()
        if points > 0 {
            let mm = distanceCalculator.pointsToMM(points)
            todayDistanceMM += mm
            totalDistanceMM += mm
            pendingMM += mm
        }

        updateStatusBar()
        updateMilestoneInfo()
        milestones.checkMilestones(totalMM: totalDistanceMM)
    }

    private func updateMilestoneInfo() {
        if let last = milestones.lastReachedMilestone(totalMM: totalDistanceMM) {
            lastMilestoneTitle = last.title
            lastMilestoneIcon = last.icon
        } else {
            lastMilestoneTitle = nil
            lastMilestoneIcon = nil
        }
        if let next = milestones.nextMilestone(totalMM: totalDistanceMM) {
            let remaining = next.distanceMM - totalDistanceMM
            nextMilestoneText = "\(next.title.replacingOccurrences(of: "!", with: "")) in \(DistanceUnit.autoFormat(mm: remaining, system: unitSystem))"
            nextMilestoneIcon = next.icon
        } else {
            nextMilestoneText = nil
            nextMilestoneIcon = nil
        }
    }

    private func updateStatusBar() {
        statusBarText = DistanceUnit.autoFormat(mm: totalDistanceMM, system: unitSystem)
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
