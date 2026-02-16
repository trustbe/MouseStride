use serde::Serialize;

#[derive(Debug, Clone, Serialize)]
pub struct Milestone {
    pub distance_mm: f64,
    pub title: String,
    pub body: String,
    pub icon: String,
}

pub static MILESTONES: &[(&str, f64, &str, &str)] = &[
    (
        "400m Hurdles!",
        400_000.0,
        "Your only obstacles were the keyboard and that coffee mug.",
        "figure.run",
    ),
    (
        "800m!",
        800_000.0,
        "Middle-distance champion of the desk. The crowd goes mild!",
        "flame.fill",
    ),
    (
        "One Mile!",
        1_609_344.0,
        "Your mouse is officially a jogger. Time for a tiny headband.",
        "bolt.fill",
    ),
    (
        "5K Complete!",
        5_000_000.0,
        "Your mouse deserves a participation medal and a banana.",
        "medal.fill",
    ),
    (
        "10K!",
        10_000_000.0,
        "Your mouse is now a serious runner. Should we get it tiny shoes?",
        "star.fill",
    ),
    (
        "Half Marathon!",
        21_097_500.0,
        "21.1 km! Your mouse is halfway to eternal glory. Don't stop now!",
        "medal.star.fill",
    ),
    (
        "MARATHON COMPLETE!",
        42_195_000.0,
        "42.195 km! Your mouse needs new shoes, a massage, and a vacation.",
        "trophy.fill",
    ),
    (
        "100 km Ultramarathon!",
        100_000_000.0,
        "Your mouse has officially left the city. Send a postcard!",
        "mountain.2.fill",
    ),
    (
        "250 km!",
        250_000_000.0,
        "Your mouse could've walked from Prague to Brno by now.",
        "train.side.front.car",
    ),
    (
        "500 km!",
        500_000_000.0,
        "Your mouse is an intercity traveler. Does it need a train ticket?",
        "airplane",
    ),
    (
        "1,000 km!",
        1_000_000_000.0,
        "Your mouse belongs in a museum. Or at least in the Hall of Fame.",
        "globe.americas.fill",
    ),
];

pub fn get_milestones() -> Vec<Milestone> {
    MILESTONES
        .iter()
        .map(|(title, dist, body, icon)| Milestone {
            title: title.to_string(),
            distance_mm: *dist,
            body: body.to_string(),
            icon: icon.to_string(),
        })
        .collect()
}

pub fn check_milestones(total_mm: f64, last_index: i32) -> Option<(i32, Milestone)> {
    for (i, (title, dist, body, icon)) in MILESTONES.iter().enumerate() {
        let idx = i as i32;
        if idx > last_index && total_mm >= *dist {
            return Some((
                idx,
                Milestone {
                    title: title.to_string(),
                    distance_mm: *dist,
                    body: body.to_string(),
                    icon: icon.to_string(),
                },
            ));
        }
    }
    None
}

pub fn last_reached_milestone(total_mm: f64) -> Option<Milestone> {
    let mut last = None;
    for (title, dist, body, icon) in MILESTONES {
        if total_mm >= *dist {
            last = Some(Milestone {
                title: title.to_string(),
                distance_mm: *dist,
                body: body.to_string(),
                icon: icon.to_string(),
            });
        } else {
            break;
        }
    }
    last
}

pub fn next_milestone(total_mm: f64) -> Option<Milestone> {
    for (title, dist, body, icon) in MILESTONES {
        if total_mm < *dist {
            return Some(Milestone {
                title: title.to_string(),
                distance_mm: *dist,
                body: body.to_string(),
                icon: icon.to_string(),
            });
        }
    }
    None
}
