import Foundation

enum AnonymousNameService {
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

    static var name: String {
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }
        let generated = "\(adjectives.randomElement()!) \(animals.randomElement()!)"
        UserDefaults.standard.set(generated, forKey: key)
        return generated
    }
}
