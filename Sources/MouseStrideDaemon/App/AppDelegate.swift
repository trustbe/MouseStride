import AppKit
import MouseStrideCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var mouseTracker: MouseTracker!
    private var distanceCalculator: DistanceCalculator!
    private var persistence: PersistenceService!
    private var nameService: AnonymousNameService!

    private var todayMM: Double = 0
    private var totalMM: Double = 0
    private var pendingMM: Double = 0

    private var uiTimer: Timer?
    private var saveTimer: Timer?
    private var syncTimer: Timer?

    private var unitSystem: UnitSystem {
        Locale.current.measurementSystem == .metric ? .metric : .imperial
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let defaults = UserDefaults(suiteName: "com.mousestride.daemon") ?? .standard
        persistence = PersistenceService(defaults: defaults)
        nameService = AnonymousNameService(defaults: defaults)
        mouseTracker = MouseTracker()
        distanceCalculator = DistanceCalculator()

        totalMM = persistence.totalDistanceMM
        todayMM = persistence.todayDistanceMM()
        persistence.pruneOldEntries()

        setupStatusItem()
        mouseTracker.start()
        startTimers()
        setupTerminationObserver()
        syncToDashboard()
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.target = self
            button.action = #selector(statusItemClicked(_:))
        }

        updateDisplay()
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        let menu = NSMenu()

        let todayItem = NSMenuItem(title: "Today: \(DistanceUnit.autoFormat(mm: todayMM, system: unitSystem))", action: nil, keyEquivalent: "")
        todayItem.image = NSImage(systemSymbolName: "calendar", accessibilityDescription: nil)
        todayItem.isEnabled = false
        menu.addItem(todayItem)

        let totalItem = NSMenuItem(title: "Total: \(DistanceUnit.allTimeFormat(mm: totalMM, system: unitSystem))", action: nil, keyEquivalent: "")
        totalItem.image = NSImage(systemSymbolName: "infinity", accessibilityDescription: nil)
        totalItem.isEnabled = false
        menu.addItem(totalItem)

        menu.addItem(.separator())

        let challengeItem = NSMenuItem(title: "Challenge (\(nameService.name))", action: #selector(openDashboard), keyEquivalent: "")
        challengeItem.image = NSImage(systemSymbolName: "trophy.fill", accessibilityDescription: nil)
        menu.addItem(challengeItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit MouseStride", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func openDashboard() {
        syncToDashboard()
        let name = nameService.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "https://trustbe.github.io/MouseStride/dashboard.html?highlight=\(name)") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func quitApp() {
        save()
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Display

    private func updateDisplay() {
        guard let button = statusItem.button else { return }

        let formatted = DistanceUnit.autoFormat(mm: todayMM, system: unitSystem)

        button.title = formatted
        button.image = NSImage(systemSymbolName: "cursorarrow.motionlines", accessibilityDescription: "MouseStride")
        button.imagePosition = .imageLeading
    }

    // MARK: - Timers

    private func startTimers() {
        uiTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateFromTracker()
        }

        saveTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.save()
        }

        syncTimer = Timer.scheduledTimer(withTimeInterval: 900.0, repeats: true) { [weak self] _ in
            self?.syncToDashboard()
        }
    }

    private func updateFromTracker() {
        let points = mouseTracker.drainAccumulatedPoints()
        if points > 0 {
            let mm = distanceCalculator.pointsToMM(points)
            todayMM += mm
            totalMM += mm
            pendingMM += mm
        }
        updateDisplay()
    }

    // MARK: - Persistence

    private func save() {
        if pendingMM > 0 {
            persistence.totalDistanceMM += pendingMM
            persistence.addToToday(mm: pendingMM)
            pendingMM = 0
        }
    }

    private func syncToDashboard() {
        DashboardService.submit(
            anonymousName: nameService.name,
            todayMM: todayMM,
            totalMM: totalMM,
            bestDayMM: persistence.bestDayMM(),
            daysTracked: persistence.daysTracked(),
            milestone: nil
        )
    }

    private func setupTerminationObserver() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            let points = self.mouseTracker.drainAccumulatedPoints()
            if points > 0 {
                self.pendingMM += self.distanceCalculator.pointsToMM(points)
            }
            self.save()
        }
    }
}
