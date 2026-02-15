import Foundation

final class PersistenceService {
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let totalDistanceMM = "totalDistanceMM"
        static let dailyHistory = "dailyHistory"
    }

    var totalDistanceMM: Double {
        get { defaults.double(forKey: Keys.totalDistanceMM) }
        set { defaults.set(newValue, forKey: Keys.totalDistanceMM) }
    }

    var dailyHistory: [String: Double] {
        get {
            defaults.dictionary(forKey: Keys.dailyHistory) as? [String: Double] ?? [:]
        }
        set {
            defaults.set(newValue, forKey: Keys.dailyHistory)
        }
    }

    func addToToday(mm: Double) {
        let key = Self.todayKey()
        var history = dailyHistory
        history[key] = (history[key] ?? 0) + mm
        dailyHistory = history
    }

    func todayDistanceMM() -> Double {
        dailyHistory[Self.todayKey()] ?? 0
    }

    func resetToday() {
        var history = dailyHistory
        history.removeValue(forKey: Self.todayKey())
        dailyHistory = history
    }

    func resetAll() {
        totalDistanceMM = 0
        dailyHistory = [:]
    }

    /// Prune entries older than 30 days
    func pruneOldEntries() {
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

    static func todayKey() -> String {
        dateFormatter().string(from: Date())
    }

    private static func dateFormatter() -> DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }

    func bestDayMM() -> Double {
        dailyHistory.values.max() ?? 0
    }

    func daysTracked() -> Int {
        dailyHistory.count
    }
}
