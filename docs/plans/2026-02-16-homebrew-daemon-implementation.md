# MouseStride Daemon — Homebrew Cask Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a minimal MouseStride daemon distributed via Homebrew Cask that tracks mouse distance, shows live stats in the menu bar, and auto-syncs to the community dashboard.

**Architecture:** Extract shared tracking/persistence code into a `MouseStrideCore` library. Build a new `MouseStrideDaemon` executable that uses `NSStatusItem` for menu bar presence (left-click toggles today/all-time, right-click for dashboard+quit). Distribute via a personal Homebrew tap (`trustbe/homebrew-mousestride`).

**Tech Stack:** Swift 5.9, SPM, AppKit (NSStatusItem), macOS 13+, Homebrew Cask

**Design doc:** `docs/plans/2026-02-16-homebrew-daemon-design.md`

---

### Task 1: Extract MouseStrideCore Library — Package.swift & Directory Setup

**Files:**
- Modify: `Package.swift`
- Create: `Sources/MouseStrideCore/` (directory only)

**Step 1: Update Package.swift to add MouseStrideCore library target**

Replace the entire `Package.swift` with:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MouseStride",
    platforms: [.macOS(.v13)],
    targets: [
        .target(
            name: "MouseStrideCore",
            path: "Sources/MouseStrideCore"
        ),
        .executableTarget(
            name: "MouseStride",
            dependencies: ["MouseStrideCore"],
            path: "Sources/MouseStride",
            exclude: ["App/Info.plist", "Resources"]
        ),
        .executableTarget(
            name: "MouseStrideDaemon",
            dependencies: ["MouseStrideCore"],
            path: "Sources/MouseStrideDaemon",
            exclude: ["App/Info.plist", "Resources"]
        )
    ]
)
```

**Step 2: Create the MouseStrideCore directory**

```bash
mkdir -p Sources/MouseStrideCore
```

**Step 3: Verify Package.swift parses**

Don't build yet — `MouseStrideCore` and `MouseStrideDaemon` directories need files first. Just verify the manifest is valid:

```bash
swift package dump-package
```

Expected: JSON output of the package description (may warn about missing sources, that's OK).

**Step 4: Commit**

```bash
git add Package.swift
git commit -m "chore: add MouseStrideCore library and MouseStrideDaemon targets to Package.swift"
```

---

### Task 2: Create MouseStrideCore — Shared Source Files

Move and adapt the 6 shared source files to `Sources/MouseStrideCore/` with `public` access and parameterized `UserDefaults`.

**Files:**
- Create: `Sources/MouseStrideCore/MouseTracker.swift`
- Create: `Sources/MouseStrideCore/DistanceCalculator.swift`
- Create: `Sources/MouseStrideCore/DistanceUnit.swift`
- Create: `Sources/MouseStrideCore/PersistenceService.swift`
- Create: `Sources/MouseStrideCore/DashboardService.swift`
- Create: `Sources/MouseStrideCore/AnonymousNameService.swift`

**Step 1: Create MouseTracker.swift**

Copy from `Sources/MouseStride/Services/MouseTracker.swift` and add `public` access:

```swift
import AppKit
import Foundation

public final class MouseTracker {
    private let teleportThreshold: CGFloat = 500.0

    private var previousLocation: NSPoint?
    private var globalMonitor: Any?
    private var localMonitor: Any?

    public private(set) var accumulatedPoints: CGFloat = 0

    public var onDistanceAccumulated: (() -> Void)?

    public init() {
        setupSleepWakeObservers()
    }

    deinit {
        stop()
        NotificationCenter.default.removeObserver(self)
    }

    public func start() {
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

    public func stop() {
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

    public func drainAccumulatedPoints() -> CGFloat {
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
```

**Step 2: Create DistanceCalculator.swift**

Copy from `Sources/MouseStride/Services/DistanceCalculator.swift` and add `public` access:

```swift
import AppKit
import CoreGraphics

public final class DistanceCalculator {
    private static let fallbackMMPerPoint: CGFloat = 0.2646

    private var mmPerPoint: CGFloat

    public init() {
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

    public func pointsToMM(_ points: CGFloat) -> Double {
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
        let physicalSize = CGDisplayScreenSize(displayID)
        let screenWidth = screen.frame.width

        guard physicalSize.width > 0, screenWidth > 0 else {
            return fallbackMMPerPoint
        }
        return physicalSize.width / screenWidth
    }

    public static func mmPerPoint(for screenLocation: NSPoint) -> CGFloat {
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
```

**Step 3: Create DistanceUnit.swift**

Copy from `Sources/MouseStride/Models/DistanceUnit.swift` and add `public` access:

```swift
import Foundation

public enum UnitSystem: String, CaseIterable {
    case metric = "Metric"
    case imperial = "Imperial"
}

public enum DistanceUnit: String, CaseIterable {
    case millimeters = "mm"
    case centimeters = "cm"
    case meters = "m"
    case kilometers = "km"
    case inches = "in"
    case feet = "ft"
    case yards = "yd"
    case miles = "mi"

    public var abbreviation: String { rawValue }

    public func convert(fromMM mm: Double) -> Double {
        switch self {
        case .millimeters: return mm
        case .centimeters: return mm / 10.0
        case .meters: return mm / 1_000.0
        case .kilometers: return mm / 1_000_000.0
        case .inches: return mm / 25.4
        case .feet: return mm / 304.8
        case .yards: return mm / 914.4
        case .miles: return mm / 1_609_344.0
        }
    }

    public func format(mm: Double) -> String {
        let value = convert(fromMM: mm)
        switch self {
        case .millimeters, .inches:
            return String(format: "%.0f %@", value, abbreviation)
        default:
            return String(format: "%.1f %@", value, abbreviation)
        }
    }

    public static func bestUnit(forMM mm: Double, system: UnitSystem = .metric) -> DistanceUnit {
        switch system {
        case .metric:
            if mm >= 1_000_000 { return .kilometers }
            else if mm >= 1_000 { return .meters }
            else if mm >= 10 { return .centimeters }
            else { return .millimeters }
        case .imperial:
            if mm >= 1_609_344 { return .miles }
            else if mm >= 914.4 * 100 { return .yards }
            else if mm >= 304.8 { return .feet }
            else { return .inches }
        }
    }

    public static func autoFormat(mm: Double, system: UnitSystem = .metric) -> String {
        let unit = bestUnit(forMM: mm, system: system)
        return unit.format(mm: mm)
    }

    public static func allTimeFormat(mm: Double, system: UnitSystem = .metric) -> String {
        switch system {
        case .metric:
            if mm >= 1_000_000 { return DistanceUnit.kilometers.format(mm: mm) }
            return autoFormat(mm: mm, system: system)
        case .imperial:
            if mm >= 1_609_344 { return DistanceUnit.miles.format(mm: mm) }
            return autoFormat(mm: mm, system: system)
        }
    }
}
```

**Step 4: Create PersistenceService.swift (parameterized UserDefaults)**

This is a modified version that accepts a `UserDefaults` instance:

```swift
import Foundation

public final class PersistenceService {
    private let defaults: UserDefaults

    private enum Keys {
        static let totalDistanceMM = "totalDistanceMM"
        static let dailyHistory = "dailyHistory"
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var totalDistanceMM: Double {
        get { defaults.double(forKey: Keys.totalDistanceMM) }
        set { defaults.set(newValue, forKey: Keys.totalDistanceMM) }
    }

    public var dailyHistory: [String: Double] {
        get {
            defaults.dictionary(forKey: Keys.dailyHistory) as? [String: Double] ?? [:]
        }
        set {
            defaults.set(newValue, forKey: Keys.dailyHistory)
        }
    }

    public func addToToday(mm: Double) {
        let key = Self.todayKey()
        var history = dailyHistory
        history[key] = (history[key] ?? 0) + mm
        dailyHistory = history
    }

    public func todayDistanceMM() -> Double {
        dailyHistory[Self.todayKey()] ?? 0
    }

    public func resetToday() {
        var history = dailyHistory
        history.removeValue(forKey: Self.todayKey())
        dailyHistory = history
    }

    public func resetAll() {
        totalDistanceMM = 0
        dailyHistory = [:]
    }

    public func pruneOldEntries() {
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -30, to: Date())!
        let formatter = Self.dateFormatter()

        var history = dailyHistory
        history = history.filter { key, _ in
            guard let date = formatter.date(from: key) else { return false }
            return date >= cutoff
        }
        dailyHistory = history
    }

    public static func todayKey() -> String {
        dateFormatter().string(from: Date())
    }

    private static func dateFormatter() -> DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }

    public func bestDayMM() -> Double {
        dailyHistory.values.max() ?? 0
    }

    public func daysTracked() -> Int {
        dailyHistory.count
    }
}
```

**Step 5: Create AnonymousNameService.swift (parameterized UserDefaults)**

```swift
import Foundation

public final class AnonymousNameService {
    private let defaults: UserDefaults
    private static let key = "anonymousName"

    private static let adjectives = [
        "Swift", "Lazy", "Cosmic", "Tiny", "Bold",
        "Sneaky", "Fluffy", "Turbo", "Mighty", "Chill",
        "Zippy", "Gentle", "Wild", "Pixel", "Neon",
        "Cozy", "Brave", "Silent", "Hyper", "Frosty"
    ]

    private static let animals = [
        "Penguin", "Otter", "Fox", "Hamster", "Panda",
        "Koala", "Owl", "Cat", "Bunny", "Gecko",
        "Sloth", "Wolf", "Dolphin", "Moth", "Ferret",
        "Crow", "Seal", "Bee", "Hawk", "Mouse"
    ]

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var name: String {
        if let existing = defaults.string(forKey: Self.key) {
            return existing
        }
        let generated = "\(Self.adjectives.randomElement()!) \(Self.animals.randomElement()!)"
        defaults.set(generated, forKey: Self.key)
        return generated
    }
}
```

**Step 6: Create DashboardService.swift (name as parameter)**

```swift
import Foundation

public enum DashboardService {
    private static let supabaseURL = "https://ygtemljaowgiypcberhz.supabase.co"
    private static let supabaseAnonKey = "sb_publishable_od7WoRDYP46HKboEp2s1aA_HXWRf54X"

    public static func submit(
        anonymousName: String,
        todayMM: Double,
        totalMM: Double,
        bestDayMM: Double,
        daysTracked: Int,
        milestone: String?
    ) {
        guard let url = URL(string: "\(supabaseURL)/rest/v1/entries") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "anonymous_name": anonymousName,
            "today_mm": Int64(todayMM),
            "total_mm": Int64(totalMM),
            "best_day_mm": Int64(bestDayMM),
            "days_tracked": daysTracked,
            "milestone": milestone as Any
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request).resume()
    }
}
```

**Step 7: Verify MouseStrideCore builds**

```bash
swift build --target MouseStrideCore
```

Expected: Build Succeeded

**Step 8: Commit**

```bash
git add Sources/MouseStrideCore/
git commit -m "feat: create MouseStrideCore shared library with public APIs"
```

---

### Task 3: Update Full App to Use MouseStrideCore

Replace the original source files in `MouseStride` with thin wrappers or re-exports that import from `MouseStrideCore`, then delete the originals.

**Files:**
- Delete: `Sources/MouseStride/Services/MouseTracker.swift`
- Delete: `Sources/MouseStride/Services/DistanceCalculator.swift`
- Delete: `Sources/MouseStride/Services/PersistenceService.swift`
- Delete: `Sources/MouseStride/Services/DashboardService.swift`
- Delete: `Sources/MouseStride/Services/AnonymousNameService.swift`
- Delete: `Sources/MouseStride/Models/DistanceUnit.swift`
- Modify: `Sources/MouseStride/App/MouseStrideApp.swift`
- Modify: `Sources/MouseStride/ViewModels/MouseStrideViewModel.swift`
- Modify: `Sources/MouseStride/Views/PopupView.swift`
- Modify: `Sources/MouseStride/Services/ShareService.swift`
- Modify: `Sources/MouseStride/Services/MilestoneService.swift`
- Modify: `Sources/MouseStride/Services/LaunchAtLoginService.swift`
- Modify: `Sources/MouseStride/Models/RealWorldComparison.swift`

**Step 1: Delete the 6 files that are now in MouseStrideCore**

```bash
rm Sources/MouseStride/Services/MouseTracker.swift
rm Sources/MouseStride/Services/DistanceCalculator.swift
rm Sources/MouseStride/Services/PersistenceService.swift
rm Sources/MouseStride/Services/DashboardService.swift
rm Sources/MouseStride/Services/AnonymousNameService.swift
rm Sources/MouseStride/Models/DistanceUnit.swift
```

**Step 2: Add `import MouseStrideCore` to all remaining source files**

Add `import MouseStrideCore` at the top of each file that references shared types.

Files that need the import (add as the first import, before other imports):

- `Sources/MouseStride/App/MouseStrideApp.swift` — uses nothing directly from core, but add for consistency
- `Sources/MouseStride/ViewModels/MouseStrideViewModel.swift` — uses `MouseTracker`, `DistanceCalculator`, `PersistenceService`, `DashboardService`, `DistanceUnit`, `UnitSystem`
- `Sources/MouseStride/Views/PopupView.swift` — uses `DistanceUnit`, `AnonymousNameService`, `LaunchAtLoginService`
- `Sources/MouseStride/Services/ShareService.swift` — uses `DashboardService`, `Milestone`
- `Sources/MouseStride/Services/MilestoneService.swift` — uses nothing from core (standalone)
- `Sources/MouseStride/Models/RealWorldComparison.swift` — uses nothing from core (standalone)

The key files that MUST have `import MouseStrideCore`:
- `MouseStrideViewModel.swift`
- `PopupView.swift`
- `ShareService.swift`

**Step 3: Update MouseStrideViewModel.swift**

Two changes needed:

1. Add `import MouseStrideCore` at top
2. `AnonymousNameService` changed from enum with static `name` property to class with instance `name` property. Update references:
   - Add a stored property: `private let nameService = AnonymousNameService()`
   - In `submitToDashboard()`: change `AnonymousNameService.name` to `nameService.name`
3. `DashboardService.submit()` now takes `anonymousName:` as first parameter. Update the call:

```swift
func submitToDashboard() {
    DashboardService.submit(
        anonymousName: nameService.name,
        todayMM: todayDistanceMM,
        totalMM: totalDistanceMM,
        bestDayMM: bestDayMM,
        daysTracked: daysTracked,
        milestone: lastReachedMilestone?.title
    )
}
```

Make `nameService` accessible for the PopupView (add a computed property):

```swift
var anonymousName: String { nameService.name }
```

**Step 4: Update PopupView.swift**

1. Add `import MouseStrideCore`
2. Change `AnonymousNameService.name` reference to `viewModel.anonymousName`

In the header HStack, change:
```swift
// Old:
Text("(\(AnonymousNameService.name))")
// New:
Text("(\(viewModel.anonymousName))")
```

In the Community Sync button action, change:
```swift
// Old:
let name = AnonymousNameService.name.addingPercentEncoding(...)
// New:
let name = viewModel.anonymousName.addingPercentEncoding(...)
```

**Step 5: Update ShareService.swift**

1. Add `import MouseStrideCore`
2. Update `DashboardService.submit()` call to include `anonymousName:` parameter.

The `shareText` method needs the anonymous name. Add it as a parameter:

```swift
static func shareText(
    anonymousName: String,  // new parameter
    todayFormatted: String,
    ...
```

Update the `DashboardService.submit()` call inside:
```swift
DashboardService.submit(
    anonymousName: anonymousName,
    todayMM: todayMM,
    ...
```

Then update the call site in `PopupView.swift`:
```swift
ShareService.shareText(
    anonymousName: viewModel.anonymousName,
    todayFormatted: ...
```

**Step 6: Verify full app builds**

```bash
swift build --product MouseStride
```

Expected: Build Succeeded

**Step 7: Commit**

```bash
git add -A
git commit -m "refactor: migrate MouseStride to use MouseStrideCore shared library"
```

---

### Task 4: Create MouseStrideDaemon App

**Files:**
- Create: `Sources/MouseStrideDaemon/App/Info.plist`
- Create: `Sources/MouseStrideDaemon/App/MouseStrideDaemonApp.swift`
- Create: `Sources/MouseStrideDaemon/App/AppDelegate.swift`
- Create: `Sources/MouseStrideDaemon/Resources/` (copy icon)

**Step 1: Create directory structure**

```bash
mkdir -p Sources/MouseStrideDaemon/App
mkdir -p Sources/MouseStrideDaemon/Resources
```

**Step 2: Create Info.plist**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>MouseStride</string>
    <key>CFBundleIdentifier</key>
    <string>com.mousestride.daemon</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>MouseStrideDaemon</string>
    <key>CFBundleIconFile</key>
    <string>MouseStride</string>
    <key>LSUIElement</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
</dict>
</plist>
```

**Step 3: Copy icon file**

```bash
cp Sources/MouseStride/Resources/MouseStride.icns Sources/MouseStrideDaemon/Resources/MouseStride.icns
```

**Step 4: Create MouseStrideDaemonApp.swift (entry point)**

```swift
import AppKit

@main
struct MouseStrideDaemonApp {
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
```

**Step 5: Create AppDelegate.swift (all daemon logic)**

```swift
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
```

**Step 6: Verify daemon builds**

```bash
swift build --product MouseStrideDaemon
```

Expected: Build Succeeded

**Step 7: Verify full app still builds**

```bash
swift build --product MouseStride
```

Expected: Build Succeeded

**Step 8: Commit**

```bash
git add Sources/MouseStrideDaemon/
git commit -m "feat: add MouseStrideDaemon minimal menu bar app"
```

---

### Task 5: Update Makefile for Daemon Builds

**Files:**
- Modify: `Makefile`

**Step 1: Add daemon-specific targets to Makefile**

Add these targets after the existing ones. Keep all existing targets unchanged, but update `build`, `build-universal`, and `clean` to handle both products:

```makefile
APP_NAME = MouseStride
TARGET_NAME = MouseStride
DAEMON_NAME = MouseStrideDaemon
BUILD_DIR = .build/release
UNIVERSAL_BINARY = .build/universal/$(TARGET_NAME)
UNIVERSAL_DAEMON = .build/universal/$(DAEMON_NAME)
VERSION ?= dev
DMG_NAME = $(APP_NAME)-$(VERSION).dmg
DAEMON_ZIP = $(DAEMON_NAME)-$(VERSION).zip
APP_BUNDLE = $(APP_NAME).app
DAEMON_BUNDLE = $(DAEMON_NAME).app
CONTENTS = $(APP_BUNDLE)/Contents
MACOS = $(CONTENTS)/MacOS
DAEMON_CONTENTS = $(DAEMON_BUNDLE)/Contents
DAEMON_MACOS = $(DAEMON_CONTENTS)/MacOS

.PHONY: build bundle run build-universal bundle-universal dmg daemon-build daemon-bundle daemon-build-universal daemon-bundle-universal daemon-zip clean

build:
	swift build -c release

bundle: build
	mkdir -p $(MACOS)
	mkdir -p $(CONTENTS)/Resources
	cp $(BUILD_DIR)/$(TARGET_NAME) $(MACOS)/$(APP_NAME)
	cp Sources/MouseStride/App/Info.plist $(CONTENTS)/Info.plist
	cp Sources/MouseStride/Resources/MouseStride.icns $(CONTENTS)/Resources/MouseStride.icns

run: bundle
	open $(APP_BUNDLE)

build-universal:
	swift build -c release --triple arm64-apple-macosx --product $(TARGET_NAME)
	swift build -c release --triple x86_64-apple-macosx --product $(TARGET_NAME)
	mkdir -p .build/universal
	lipo -create \
		.build/arm64-apple-macosx/release/$(TARGET_NAME) \
		.build/x86_64-apple-macosx/release/$(TARGET_NAME) \
		-output $(UNIVERSAL_BINARY)

bundle-universal: build-universal
	mkdir -p $(MACOS)
	mkdir -p $(CONTENTS)/Resources
	cp $(UNIVERSAL_BINARY) $(MACOS)/$(APP_NAME)
	cp Sources/MouseStride/App/Info.plist $(CONTENTS)/Info.plist
	cp Sources/MouseStride/Resources/MouseStride.icns $(CONTENTS)/Resources/MouseStride.icns

dmg: bundle-universal
	hdiutil create -volname $(APP_NAME) -srcfolder $(APP_BUNDLE) -ov -format UDZO $(DMG_NAME)

# Daemon targets

daemon-build:
	swift build -c release --product $(DAEMON_NAME)

daemon-bundle: daemon-build
	mkdir -p $(DAEMON_MACOS)
	mkdir -p $(DAEMON_CONTENTS)/Resources
	cp $(BUILD_DIR)/$(DAEMON_NAME) $(DAEMON_MACOS)/$(DAEMON_NAME)
	cp Sources/MouseStrideDaemon/App/Info.plist $(DAEMON_CONTENTS)/Info.plist
	cp Sources/MouseStrideDaemon/Resources/MouseStride.icns $(DAEMON_CONTENTS)/Resources/MouseStride.icns

daemon-run: daemon-bundle
	open $(DAEMON_BUNDLE)

daemon-build-universal:
	swift build -c release --triple arm64-apple-macosx --product $(DAEMON_NAME)
	swift build -c release --triple x86_64-apple-macosx --product $(DAEMON_NAME)
	mkdir -p .build/universal
	lipo -create \
		.build/arm64-apple-macosx/release/$(DAEMON_NAME) \
		.build/x86_64-apple-macosx/release/$(DAEMON_NAME) \
		-output $(UNIVERSAL_DAEMON)

daemon-bundle-universal: daemon-build-universal
	mkdir -p $(DAEMON_MACOS)
	mkdir -p $(DAEMON_CONTENTS)/Resources
	cp $(UNIVERSAL_DAEMON) $(DAEMON_MACOS)/$(DAEMON_NAME)
	cp Sources/MouseStrideDaemon/App/Info.plist $(DAEMON_CONTENTS)/Info.plist
	cp Sources/MouseStrideDaemon/Resources/MouseStride.icns $(DAEMON_CONTENTS)/Resources/MouseStride.icns

daemon-zip: daemon-bundle-universal
	ditto -c -k --sequesterRsrc --keepParent $(DAEMON_BUNDLE) $(DAEMON_ZIP)

clean:
	rm -rf .build $(APP_BUNDLE) $(DAEMON_BUNDLE) *.dmg *.zip
```

**Step 2: Verify Makefile works**

```bash
make daemon-build
```

Expected: Build succeeds

**Step 3: Commit**

```bash
git add Makefile
git commit -m "build: add daemon build, bundle, and zip targets to Makefile"
```

---

### Task 6: Update CI/CD Release Workflow

**Files:**
- Modify: `.github/workflows/release.yml`

**Step 1: Add daemon build job to release workflow**

Replace the entire file:

```yaml
name: Release

on:
  push:
    tags: ['v*']

permissions:
  contents: write

jobs:
  build-and-release:
    runs-on: macos-15
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Extract version
        id: version
        run: echo "tag=${GITHUB_REF_NAME}" >> "$GITHUB_OUTPUT"

      - name: Build DMG (full app)
        run: make dmg VERSION=${{ steps.version.outputs.tag }}

      - name: Verify universal binary (full app)
        run: lipo -info .build/universal/MouseStride

      - name: Build Daemon ZIP
        run: make daemon-zip VERSION=${{ steps.version.outputs.tag }}

      - name: Verify universal binary (daemon)
        run: lipo -info .build/universal/MouseStrideDaemon

      - name: Create GitHub Release
        env:
          GH_TOKEN: ${{ github.token }}
        run: >
          gh release create "${{ steps.version.outputs.tag }}"
          "MouseStride-${{ steps.version.outputs.tag }}.dmg"
          "MouseStrideDaemon-${{ steps.version.outputs.tag }}.zip"
          --title "MouseStride ${{ steps.version.outputs.tag }}"
          --generate-notes
```

**Step 2: Commit**

```bash
git add .github/workflows/release.yml
git commit -m "ci: add daemon zip build and upload to release workflow"
```

---

### Task 7: Create Homebrew Tap Cask File (Template)

This task creates a template Cask file and documents the tap setup process. The actual Homebrew tap lives in a separate repo (`trustbe/homebrew-mousestride`).

**Files:**
- Create: `homebrew/mousestride.rb` (template for reference)

**Step 1: Create template directory and Cask file**

```bash
mkdir -p homebrew
```

Create `homebrew/mousestride.rb`:

```ruby
cask "mousestride" do
  version "1.0.0"
  sha256 "PLACEHOLDER_SHA256"

  url "https://github.com/trustbe/MouseStride/releases/download/v#{version}/MouseStrideDaemon-v#{version}.zip"
  name "MouseStride"
  desc "Lightweight mouse distance tracker for macOS"
  homepage "https://trustbe.github.io/MouseStride/"

  depends_on macos: ">= :ventura"

  app "MouseStrideDaemon.app"

  zap trash: [
    "~/Library/Preferences/com.mousestride.daemon.plist",
  ]
end
```

**Step 2: Update README.md with Homebrew install instructions**

Add a Homebrew section after the existing "Download (recommended)" section in `README.md`:

```markdown
### Homebrew (daemon only)

A lightweight background daemon — tracks distance, shows live stats in the menu bar, auto-syncs to the community dashboard. No UI popover.

```bash
brew tap trustbe/mousestride
brew install --cask mousestride
open /Applications/MouseStrideDaemon.app
```
```

**Step 3: Commit**

```bash
git add homebrew/ README.md
git commit -m "docs: add Homebrew Cask template and install instructions"
```

---

### Task 8: Manual Verification

**Step 1: Build both products from clean state**

```bash
make clean
swift build
```

Expected: Both `MouseStride` and `MouseStrideDaemon` build successfully.

**Step 2: Bundle and run the daemon locally**

```bash
make daemon-bundle
make daemon-run
```

Expected: A menu bar icon appears showing `↗ 0 mm` (or similar). Left-clicking toggles to `Σ 0 mm`. Right-clicking shows "Open Dashboard" and "Quit MouseStride".

**Step 3: Test the full app still works**

```bash
make bundle
make run
```

Expected: Full app launches with popover, all features working as before.

**Step 4: Final commit if any fixes were needed**

```bash
git add -A
git commit -m "fix: address issues found during manual verification"
```

---

## Summary of Commits

1. `chore: add MouseStrideCore library and MouseStrideDaemon targets to Package.swift`
2. `feat: create MouseStrideCore shared library with public APIs`
3. `refactor: migrate MouseStride to use MouseStrideCore shared library`
4. `feat: add MouseStrideDaemon minimal menu bar app`
5. `build: add daemon build, bundle, and zip targets to Makefile`
6. `ci: add daemon zip build and upload to release workflow`
7. `docs: add Homebrew Cask template and install instructions`

## Post-Implementation: Homebrew Tap Setup

After this plan is implemented and a release tag is pushed:

1. Create GitHub repo `trustbe/homebrew-mousestride`
2. Copy `homebrew/mousestride.rb` to `Casks/mousestride.rb` in that repo
3. Update the SHA256 with the actual hash from the release zip:
   ```bash
   shasum -a 256 MouseStrideDaemon-v1.0.0.zip
   ```
4. Test: `brew tap trustbe/mousestride && brew install --cask mousestride`
