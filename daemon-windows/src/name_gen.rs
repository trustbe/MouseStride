// Mouse name generator

use rand::seq::SliceRandom;

pub const ADJECTIVES: &[&str] = &[
    "Swift", "Lazy", "Cosmic", "Tiny", "Bold",
    "Sneaky", "Fluffy", "Turbo", "Mighty", "Chill",
    "Zippy", "Gentle", "Wild", "Pixel", "Neon",
    "Cozy", "Brave", "Silent", "Hyper", "Frosty",
];

pub const ANIMALS: &[&str] = &[
    "Penguin", "Otter", "Fox", "Hamster", "Panda",
    "Koala", "Owl", "Cat", "Bunny", "Gecko",
    "Sloth", "Wolf", "Dolphin", "Moth", "Ferret",
    "Crow", "Seal", "Bee", "Hawk", "Mouse",
];

/// Generate a 3-word anonymous name: "Adjective Adjective Animal"
pub fn generate_name() -> String {
    let mut rng = rand::thread_rng();
    let adj1 = ADJECTIVES.choose(&mut rng).unwrap();
    let adj2 = ADJECTIVES.choose(&mut rng).unwrap();
    let animal = ANIMALS.choose(&mut rng).unwrap();
    format!("{} {} {}", adj1, adj2, animal)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn generates_three_word_name() {
        let name = generate_name();
        let parts: Vec<&str> = name.split(' ').collect();
        assert_eq!(parts.len(), 3, "Name should have 3 words: {}", name);
    }

    #[test]
    fn name_uses_valid_words() {
        let name = generate_name();
        let parts: Vec<&str> = name.split(' ').collect();
        assert!(ADJECTIVES.contains(&parts[0]), "First word should be an adjective");
        assert!(ADJECTIVES.contains(&parts[1]), "Second word should be an adjective");
        assert!(ANIMALS.contains(&parts[2]), "Third word should be an animal");
    }

    #[test]
    fn adjectives_differ_with_high_probability() {
        let mut different = 0;
        for _ in 0..100 {
            let name = generate_name();
            let parts: Vec<&str> = name.split(' ').collect();
            if parts[0] != parts[1] {
                different += 1;
            }
        }
        assert!(different >= 80, "Most names should have different adjectives: {}/100", different);
    }

    #[test]
    fn word_lists_have_at_least_20_entries() {
        assert!(ADJECTIVES.len() >= 20);
        assert!(ANIMALS.len() >= 20);
    }
}
