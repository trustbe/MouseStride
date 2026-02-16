use rand::seq::SliceRandom;

const ADJECTIVES: &[&str] = &[
    "Swift", "Lazy", "Cosmic", "Tiny", "Bold", "Sneaky", "Fluffy", "Turbo", "Mighty", "Chill",
    "Zippy", "Gentle", "Wild", "Pixel", "Neon", "Cozy", "Brave", "Silent", "Hyper", "Frosty",
];

const ANIMALS: &[&str] = &[
    "Penguin", "Otter", "Fox", "Hamster", "Panda", "Koala", "Owl", "Cat", "Bunny", "Gecko",
    "Sloth", "Wolf", "Dolphin", "Moth", "Ferret", "Crow", "Seal", "Bee", "Hawk", "Mouse",
];

pub fn generate_name() -> String {
    let mut rng = rand::thread_rng();
    let adj = ADJECTIVES.choose(&mut rng).unwrap_or(&"Swift");
    let animal = ANIMALS.choose(&mut rng).unwrap_or(&"Mouse");
    format!("{} {}", adj, animal)
}
