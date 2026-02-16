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
