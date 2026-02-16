import Foundation

public final class AnonymousNameService {
    private let defaults: UserDefaults
    private static let key = "anonymousName"

    // 100 adjectives × 100 colors × 100 animals = 1,000,000 combinations
    private static let adjectives = [
        "Swift", "Lazy", "Cosmic", "Tiny", "Bold",
        "Sneaky", "Fluffy", "Turbo", "Mighty", "Chill",
        "Zippy", "Gentle", "Wild", "Pixel", "Neon",
        "Cozy", "Brave", "Silent", "Hyper", "Frosty",
        "Lucky", "Dizzy", "Funky", "Jolly", "Rapid",
        "Clever", "Daring", "Eager", "Fierce", "Giddy",
        "Happy", "Icy", "Jumpy", "Keen", "Lively",
        "Merry", "Noble", "Odd", "Plucky", "Quick",
        "Rowdy", "Sly", "Tough", "Ultra", "Vivid",
        "Witty", "Zany", "Peppy", "Spry", "Wily",
        "Snappy", "Dapper", "Groovy", "Nimble", "Perky",
        "Quirky", "Rustic", "Smooth", "Tricky", "Wacky",
        "Crafty", "Dreamy", "Feisty", "Goofy", "Hasty",
        "Jazzy", "Kooky", "Lanky", "Moody", "Nerdy",
        "Plump", "Quiet", "Rocky", "Sassy", "Tasty",
        "Uppity", "Vocal", "Warm", "Zesty", "Breezy",
        "Crispy", "Dusty", "Edgy", "Fizzy", "Gusty",
        "Hazy", "Inky", "Jiffy", "Knobby", "Leafy",
        "Mushy", "Nutty", "Oily", "Puffy", "Raspy",
        "Shiny", "Tipsy", "Wavy", "Yappy", "Zingy"
    ]

    private static let colors = [
        "Red", "Blue", "Gold", "Jade", "Pink",
        "Teal", "Plum", "Rust", "Sage", "Mint",
        "Onyx", "Opal", "Ruby", "Aqua", "Lime",
        "Peach", "Coral", "Ivory", "Amber", "Slate",
        "Olive", "Mauve", "Lilac", "Tan", "Ashen",
        "Brass", "Cedar", "Dusk", "Ebony", "Fawn",
        "Gray", "Honey", "Indigo", "Khaki", "Lemon",
        "Mocha", "Navy", "Ochre", "Pearl", "Rose",
        "Sand", "Taupe", "Umber", "Wheat", "Azure",
        "Blush", "Cream", "Flint", "Grape", "Hazel",
        "Iron", "Jet", "Kiwi", "Lava", "Mango",
        "Noir", "Pine", "Quartz", "Sable", "Terra",
        "Violet", "Wine", "Zinc", "Birch", "Clay",
        "Denim", "Ember", "Frost", "Ginger", "Hemp",
        "Ice", "Jasper", "Kelp", "Lunar", "Maple",
        "Nectar", "Oxide", "Petal", "Raven", "Silver",
        "Smoke", "Snow", "Steel", "Stone", "Storm",
        "Sunny", "Tangy", "Topaz", "Tulip", "Umber",
        "Velvet", "Walnut", "Yarrow", "Cobalt", "Copper",
        "Mossy", "Dusty", "Foggy", "Misty", "Rusty"
    ]

    private static let animals = [
        "Penguin", "Otter", "Fox", "Hamster", "Panda",
        "Koala", "Owl", "Cat", "Bunny", "Gecko",
        "Sloth", "Wolf", "Dolphin", "Moth", "Ferret",
        "Crow", "Seal", "Bee", "Hawk", "Mouse",
        "Bear", "Deer", "Frog", "Goose", "Heron",
        "Jay", "Kite", "Lynx", "Mole", "Newt",
        "Puma", "Quail", "Robin", "Swan", "Toad",
        "Viper", "Wren", "Yak", "Crane", "Dove",
        "Eagle", "Finch", "Grouse", "Hare", "Ibis",
        "Jaguar", "Lark", "Moose", "Narwhal", "Osprey",
        "Parrot", "Raven", "Shark", "Tiger", "Urchin",
        "Vulture", "Whale", "Badger", "Clam", "Drake",
        "Falcon", "Gibbon", "Hippo", "Iguana", "Jackal",
        "Lemur", "Mantis", "Puffin", "Rhino", "Squid",
        "Toucan", "Bison", "Coyote", "Dingo", "Ermine",
        "Guppy", "Hornet", "Impala", "Koi", "Llama",
        "Macaw", "Okapi", "Pike", "Rook", "Snail",
        "Tapir", "Vole", "Wasp", "Zebra", "Asp",
        "Chimp", "Eel", "Goat", "Loon", "Mink",
        "Newt", "Oyster", "Ram", "Stork", "Tuna"
    ]

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var name: String {
        if let existing = defaults.string(forKey: Self.key) {
            return existing
        }
        let generated = "\(Self.adjectives.randomElement()!) \(Self.colors.randomElement()!) \(Self.animals.randomElement()!)"
        defaults.set(generated, forKey: Self.key)
        return generated
    }
}
