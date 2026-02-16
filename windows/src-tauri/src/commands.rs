use crate::milestones;
use crate::persistence::PersistenceService;
use crate::distance_calc;
use crate::dashboard;
use parking_lot::Mutex;
use serde::Serialize;
use tauri::State;

pub struct AppState {
    pub persistence: Mutex<PersistenceService>,
    pub pending_mm: Mutex<f64>,
    pub today_mm: Mutex<f64>,
    pub total_mm: Mutex<f64>,
}

#[derive(Serialize)]
pub struct StatsResponse {
    pub today_mm: f64,
    pub total_mm: f64,
    pub best_day_mm: f64,
    pub days_tracked: usize,
    pub anonymous_name: String,
    pub auto_share_enabled: bool,
    pub last_milestone_title: Option<String>,
    pub last_milestone_icon: Option<String>,
    pub next_milestone_title: Option<String>,
    pub next_milestone_icon: Option<String>,
    pub next_milestone_remaining_mm: Option<f64>,
    pub status_text: String,
}

#[derive(Serialize)]
pub struct MilestoneInfo {
    pub title: String,
    pub distance_mm: f64,
    pub body: String,
    pub icon: String,
    pub reached: bool,
}

fn format_distance(mm: f64) -> String {
    if mm >= 1_000_000.0 {
        format!("{:.1} km", mm / 1_000_000.0)
    } else if mm >= 1_000.0 {
        format!("{:.1} m", mm / 1_000.0)
    } else if mm >= 10.0 {
        format!("{:.1} cm", mm / 10.0)
    } else {
        format!("{:.0} mm", mm)
    }
}

#[tauri::command]
pub fn get_stats(state: State<AppState>) -> StatsResponse {
    let persistence = state.persistence.lock();
    let today = *state.today_mm.lock();
    let total = *state.total_mm.lock();

    let last = milestones::last_reached_milestone(total);
    let next = milestones::next_milestone(total);

    StatsResponse {
        today_mm: today,
        total_mm: total,
        best_day_mm: persistence.best_day_mm(),
        days_tracked: persistence.days_tracked(),
        anonymous_name: persistence.anonymous_name().to_string(),
        auto_share_enabled: persistence.auto_share_enabled(),
        last_milestone_title: last.as_ref().map(|m| m.title.clone()),
        last_milestone_icon: last.as_ref().map(|m| m.icon.clone()),
        next_milestone_title: next.as_ref().map(|m| m.title.clone()),
        next_milestone_icon: next.as_ref().map(|m| m.icon.clone()),
        next_milestone_remaining_mm: next.map(|m| m.distance_mm - total),
        status_text: format_distance(total),
    }
}

#[tauri::command]
pub fn get_milestones(state: State<AppState>) -> Vec<MilestoneInfo> {
    let total = *state.total_mm.lock();
    milestones::get_milestones()
        .into_iter()
        .map(|m| MilestoneInfo {
            reached: total >= m.distance_mm,
            title: m.title,
            distance_mm: m.distance_mm,
            body: m.body,
            icon: m.icon,
        })
        .collect()
}

#[tauri::command]
pub fn set_auto_share(state: State<AppState>, enabled: bool) {
    let mut persistence = state.persistence.lock();
    persistence.set_auto_share_enabled(enabled);
    persistence.save();
}

#[tauri::command]
pub fn submit_to_community(state: State<AppState>) {
    let persistence = state.persistence.lock();
    let today = *state.today_mm.lock();
    let total = *state.total_mm.lock();

    let last = milestones::last_reached_milestone(total);

    dashboard::submit(
        persistence.anonymous_name(),
        today,
        total,
        persistence.best_day_mm(),
        persistence.days_tracked(),
        last.map(|m| m.title),
    );
}

#[tauri::command]
pub fn share_results(state: State<AppState>) -> String {
    let persistence = state.persistence.lock();
    let today = *state.today_mm.lock();
    let total = *state.total_mm.lock();

    let last = milestones::last_reached_milestone(total);

    // Also submit to dashboard
    dashboard::submit(
        persistence.anonymous_name(),
        today,
        total,
        persistence.best_day_mm(),
        persistence.days_tracked(),
        last.as_ref().map(|m| m.title.clone()),
    );

    let mut lines = Vec::new();

    if let Some(m) = &last {
        lines.push(format!("{} \u{1F3C6}", m.title));
        lines.push(String::new());
    }

    lines.push(format!(
        "\u{1F5B1}\u{FE0F} My mouse traveled {} today!",
        format_distance(today)
    ));

    let days = persistence.days_tracked();
    let day_word = if days == 1 { "day" } else { "days" };
    lines.push(format!(
        "\u{1F4CA} Total: {} \u{00B7} {} {} \u{00B7} Best: {}",
        format_distance(total),
        days,
        day_word,
        format_distance(persistence.best_day_mm())
    ));

    lines.push(String::new());
    lines.push("Track your mouse \u{2192} https://trustbe.github.io/MouseStride".to_string());

    lines.join("\n")
}

#[tauri::command]
pub fn get_anonymous_name(state: State<AppState>) -> String {
    let persistence = state.persistence.lock();
    persistence.anonymous_name().to_string()
}

#[tauri::command]
pub fn quit_app(app: tauri::AppHandle) {
    app.exit(0);
}
