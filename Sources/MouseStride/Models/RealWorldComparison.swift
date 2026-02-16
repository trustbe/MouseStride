import Foundation

enum RealWorldComparison {
    static func compare(mm: Double) -> String {
        switch mm {
        case ..<100:           // < 10 cm
            return "A mouse sneeze"
        case ..<1_000:         // < 1 m
            return "Across your keyboard"
        case ..<10_000:        // < 10 m
            return "Down your hallway"
        case ..<50_000:        // < 50 m
            return "An Olympic swimming pool"
        case ..<100_000:       // < 100 m
            return "Usain Bolt's sprint"
        case ..<500_000:       // < 500 m
            return "Around a football field"
        case ..<1_000_000:     // < 1 km
            return "Through Central Park"
        case ..<5_000_000:     // < 5 km
            return "A park run"
        case ..<10_000_000:    // < 10 km
            return "Across downtown"
        default:
            return "Your cursor needs a taxi"
        }
    }
}
