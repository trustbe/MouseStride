// Data persistence layer

use chrono::Local;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::path::PathBuf;

#[derive(Serialize, Deserialize, Default)]
pub struct Data {
    #[serde(default)]
    pub anonymous_name: Option<String>,
    #[serde(default)]
    pub total_distance_mm: f64,
    #[serde(default)]
    pub daily_history: HashMap<String, f64>,
}

pub struct Persistence {
    path: PathBuf,
    data: Data,
}

impl Persistence {
    pub fn new(path: PathBuf) -> Self {
        let data = std::fs::read_to_string(&path)
            .ok()
            .and_then(|s| serde_json::from_str(&s).ok())
            .unwrap_or_default();
        Self { path, data }
    }

    pub fn data_path() -> PathBuf {
        let dir = dirs::data_dir()
            .unwrap_or_else(|| PathBuf::from("."))
            .join("MouseStride");
        std::fs::create_dir_all(&dir).ok();
        dir.join("data.json")
    }

    pub fn total_distance_mm(&self) -> f64 {
        self.data.total_distance_mm
    }

    pub fn today_distance_mm(&self) -> f64 {
        let key = today_key();
        *self.data.daily_history.get(&key).unwrap_or(&0.0)
    }

    pub fn add_distance(&mut self, mm: f64) {
        self.data.total_distance_mm += mm;
        let key = today_key();
        *self.data.daily_history.entry(key).or_insert(0.0) += mm;
    }

    pub fn name(&self) -> Option<&str> {
        self.data.anonymous_name.as_deref()
    }

    pub fn set_name(&mut self, name: String) {
        self.data.anonymous_name = Some(name);
    }

    pub fn best_day_mm(&self) -> f64 {
        self.data.daily_history.values().cloned().fold(0.0, f64::max)
    }

    pub fn days_tracked(&self) -> usize {
        self.data.daily_history.len()
    }

    pub fn prune_old_entries(&mut self, max_days: i64) {
        let cutoff = Local::now().date_naive() - chrono::Duration::days(max_days);
        self.data.daily_history.retain(|key, _| {
            chrono::NaiveDate::parse_from_str(key, "%Y-%m-%d")
                .map(|d| d >= cutoff)
                .unwrap_or(false)
        });
    }

    pub fn save(&self) -> std::io::Result<()> {
        if let Some(parent) = self.path.parent() {
            std::fs::create_dir_all(parent)?;
        }
        let json = serde_json::to_string_pretty(&self.data)
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?;
        std::fs::write(&self.path, json)
    }
}

fn today_key() -> String {
    Local::now().format("%Y-%m-%d").to_string()
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::PathBuf;

    fn temp_path() -> PathBuf {
        let dir = std::env::temp_dir().join(format!("mousestride-test-{}", std::process::id()));
        std::fs::create_dir_all(&dir).unwrap();
        dir.join("data.json")
    }

    #[test]
    fn fresh_state_has_zero_totals() {
        let p = Persistence::new(temp_path());
        assert_eq!(p.total_distance_mm(), 0.0);
        assert_eq!(p.today_distance_mm(), 0.0);
    }

    #[test]
    fn add_distance_accumulates() {
        let path = temp_path();
        let mut p = Persistence::new(path.clone());
        p.add_distance(1000.0);
        p.add_distance(2000.0);
        p.save().unwrap();

        let p2 = Persistence::new(path);
        assert_eq!(p2.total_distance_mm(), 3000.0);
    }

    #[test]
    fn today_distance_tracks_separately() {
        let path = temp_path();
        let mut p = Persistence::new(path);
        p.add_distance(5000.0);
        assert_eq!(p.today_distance_mm(), 5000.0);
        assert_eq!(p.total_distance_mm(), 5000.0);
    }

    #[test]
    fn anonymous_name_persisted() {
        let path = temp_path();
        let mut p = Persistence::new(path.clone());
        p.set_name("Bold Frosty Owl".to_string());
        p.save().unwrap();

        let p2 = Persistence::new(path);
        assert_eq!(p2.name(), Some("Bold Frosty Owl"));
    }

    #[test]
    fn best_day_mm() {
        let path = temp_path();
        let mut p = Persistence::new(path);
        p.add_distance(1000.0);
        assert_eq!(p.best_day_mm(), 1000.0);
    }

    #[test]
    fn days_tracked() {
        let path = temp_path();
        let mut p = Persistence::new(path);
        p.add_distance(1000.0);
        assert_eq!(p.days_tracked(), 1);
    }

    #[test]
    fn prune_keeps_recent_entries() {
        let path = temp_path();
        let mut p = Persistence::new(path);
        p.add_distance(1000.0);
        let before = p.days_tracked();
        p.prune_old_entries(30);
        assert_eq!(p.days_tracked(), before);
    }
}
