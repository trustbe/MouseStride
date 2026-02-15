import Foundation

enum DistanceUnit: String, CaseIterable {
    case millimeters = "mm"
    case centimeters = "cm"
    case meters = "m"
    case kilometers = "km"

    var abbreviation: String { rawValue }

    func convert(fromMM mm: Double) -> Double {
        switch self {
        case .millimeters: return mm
        case .centimeters: return mm / 10.0
        case .meters: return mm / 1_000.0
        case .kilometers: return mm / 1_000_000.0
        }
    }

    func format(mm: Double) -> String {
        let value = convert(fromMM: mm)
        switch self {
        case .millimeters:
            return String(format: "%.0f %@", value, abbreviation)
        case .centimeters:
            return String(format: "%.1f %@", value, abbreviation)
        case .meters:
            return String(format: "%.2f %@", value, abbreviation)
        case .kilometers:
            return String(format: "%.2f %@", value, abbreviation)
        }
    }

    static func bestUnit(forMM mm: Double) -> DistanceUnit {
        if mm >= 1_000_000 {
            return .kilometers
        } else if mm >= 1_000 {
            return .meters
        } else if mm >= 10 {
            return .centimeters
        } else {
            return .millimeters
        }
    }

    static func autoFormat(mm: Double) -> String {
        let unit = bestUnit(forMM: mm)
        return unit.format(mm: mm)
    }
}
