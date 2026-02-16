use serde::Serialize;

const SUPABASE_URL: &str = "https://ygtemljaowgiypcberhz.supabase.co";
const SUPABASE_ANON_KEY: &str = "sb_publishable_od7WoRDYP46HKboEp2s1aA_HXWRf54X";

#[derive(Serialize)]
struct DashboardEntry {
    anonymous_name: String,
    today_mm: i64,
    total_mm: i64,
    best_day_mm: i64,
    days_tracked: usize,
    milestone: Option<String>,
}

pub fn submit(
    anonymous_name: &str,
    today_mm: f64,
    total_mm: f64,
    best_day_mm: f64,
    days_tracked: usize,
    milestone: Option<String>,
) {
    let entry = DashboardEntry {
        anonymous_name: anonymous_name.to_string(),
        today_mm: today_mm as i64,
        total_mm: total_mm as i64,
        best_day_mm: best_day_mm as i64,
        days_tracked,
        milestone,
    };

    let url = format!("{}/rest/v1/entries", SUPABASE_URL);

    // Fire-and-forget on a separate thread (works from any context)
    std::thread::spawn(move || {
        let rt = tokio::runtime::Builder::new_current_thread()
            .enable_all()
            .build();

        if let Ok(rt) = rt {
            rt.block_on(async {
                let client = reqwest::Client::new();
                let _ = client
                    .post(&url)
                    .header("Content-Type", "application/json")
                    .header("apikey", SUPABASE_ANON_KEY)
                    .header("Authorization", format!("Bearer {}", SUPABASE_ANON_KEY))
                    .json(&entry)
                    .send()
                    .await;
            });
        }
    });
}
