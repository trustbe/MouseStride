// Dashboard API client

const SUPABASE_URL: &str = "https://ygtemljaowgiypcberhz.supabase.co";
const SUPABASE_ANON_KEY: &str = "sb_publishable_od7WoRDYP46HKboEp2s1aA_HXWRf54X";

pub fn submit(
    anonymous_name: &str,
    today_mm: f64,
    total_mm: f64,
    best_day_mm: f64,
    days_tracked: usize,
) {
    let url = format!("{}/rest/v1/entries", SUPABASE_URL);
    let body = serde_json::json!({
        "anonymous_name": anonymous_name,
        "today_mm": today_mm as i64,
        "total_mm": total_mm as i64,
        "best_day_mm": best_day_mm as i64,
        "days_tracked": days_tracked,
        "milestone": null,
    });

    let _ = ureq::post(&url)
        .set("Content-Type", "application/json")
        .set("apikey", SUPABASE_ANON_KEY)
        .set("Authorization", &format!("Bearer {}", SUPABASE_ANON_KEY))
        .send_json(body);
}
