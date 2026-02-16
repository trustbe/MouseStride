import AppKit
import MouseStrideCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let mouseTracker = MouseTracker()
    private let distanceCalculator = DistanceCalculator()
    private let persistence: PersistenceService
    private let nameService: AnonymousNameService

    private var showingAllTime = false
    private var todayMM: Double = 0
    private var totalMM: Double = 0
    private var pendingMM: Double = 0

    private var uiTimer: Timer?
    private var saveTimer: Timer?
    private var syncTimer: Timer?

    private var unitSystem: UnitSystem {
        Locale.current.measurementSystem == .metric ? .metric : .imperial
    }

    override init() {
        let defaults = UserDefaults(suiteName: "com.mousestride.daemon")!
        self.persistence = PersistenceService(defaults: defaults)
        self.nameService = AnonymousNameService(defaults: defaults)
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        totalMM = persistence.totalDistanceMM
        todayMM = persistence.todayDistanceMM()
        persistence.pruneOldEntries()

        setupStatusItem()
        mouseTracker.start()
        startTimers()
        setupTerminationObserver()
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        updateDisplay()
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            showingAllTime.toggle()
            updateDisplay()
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open Dashboard", action: #selector(openDashboard), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit MouseStride", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func openDashboard() {
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

        let mm = showingAllTime ? totalMM : todayMM
        let prefix = showingAllTime ? "\u{03A3} " : "\u{2197} "
        let formatted = DistanceUnit.autoFormat(mm: mm, system: unitSystem)

        button.title = prefix + formatted
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
