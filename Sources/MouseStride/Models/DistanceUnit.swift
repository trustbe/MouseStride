import Foundation

enum UnitSystem: String, CaseIterable {
    case metric = "Metric"
    case imperial = "Imperial"
}

enum DistanceUnit: String, CaseIterable {
    // Metric
    case millimeters = "mm"
    case centimeters = "cm"
    case meters = "m"
    case kilometers = "km"
    // Imperial
    case inches = "in"
    case feet = "ft"
    case yards = "yd"
    case miles = "mi"

    var abbreviation: String { rawValue }

    func convert(fromMM mm: Double) -> Double {
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

    func format(mm: Double) -> String {
        let value = convert(fromMM: mm)
        switch self {
        case .millimeters, .inches:
            return String(format: "%.0f %@", value, abbreviation)
        default:
            return String(format: "%.1f %@", value, abbreviation)
        }
    }

    static func bestUnit(forMM mm: Double, system: UnitSystem = .metric) -> DistanceUnit {
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

    static func autoFormat(mm: Double, system: UnitSystem = .metric) -> String {
        let unit = bestUnit(forMM: mm, system: system)
        return unit.format(mm: mm)
    }

    /// For All Time: stick to km/miles once reached
    static func allTimeFormat(mm: Double, system: UnitSystem = .metric) -> String {
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
