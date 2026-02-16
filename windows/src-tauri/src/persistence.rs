use chrono::Local;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs;
use std::path::PathBuf;

#[derive(Debug, Serialize, Deserialize)]
pub struct AppData {
    pub total_distance_mm: f64,
    pub daily_history: HashMap<String, f64>,
    pub anonymous_name: String,
    pub auto_share_enabled: bool,
    pub last_milestone_index: i32,
}

impl Default for AppData {
    fn default() -> Self {
        Self {
            total_distance_mm: 0.0,
            daily_history: HashMap::new(),
            anonymous_name: String::new(),
            auto_share_enabled: false,
            last_milestone_index: -1,
        }
    }
}

pub struct PersistenceService {
    data: AppData,
    file_path: PathBuf,
}

impl PersistenceService {
    pub fn new() -> Self {
        let dir = dirs::data_local_dir()
            .unwrap_or_else(|| PathBuf::from("."))
            .join("MouseStride");

        fs::create_dir_all(&dir).ok();

        let file_path = dir.join("data.json");
        let data = Self::load_from_file(&file_path);

        Self { data, file_path }
    }

    fn load_from_file(path: &PathBuf) -> AppData {
        match fs::read_to_string(path) {
            Ok(contents) => serde_json::from_str(&contents).unwrap_or_default(),
            Err(_) => AppData::default(),
        }
    }

    pub fn save(&self) {
        if let Ok(json) = serde_json::to_string_pretty(&self.data) {
            fs::write(&self.file_path, json).ok();
        }
    }

    pub fn total_distance_mm(&self) -> f64 {
        self.data.total_distance_mm
    }

    pub fn set_total_distance_mm(&mut self, value: f64) {
        self.data.total_distance_mm = value;
    }

    pub fn add_total_distance_mm(&mut self, mm: f64) {
        self.data.total_distance_mm += mm;
    }

    pub fn today_distance_mm(&self) -> f64 {
        let key = Self::today_key();
        *self.data.daily_history.get(&key).unwrap_or(&0.0)
    }

    pub fn add_to_today(&mut self, mm: f64) {
        let key = Self::today_key();
        let entry = self.data.daily_history.entry(key).or_insert(0.0);
        *entry += mm;
    }

    pub fn best_day_mm(&self) -> f64 {
        self.data
            .daily_history
            .values()
            .copied()
            .fold(0.0_f64, f64::max)
    }

    pub fn days_tracked(&self) -> usize {
        self.data.daily_history.len()
    }

    pub fn anonymous_name(&self) -> &str {
        &self.data.anonymous_name
    }

    pub fn set_anonymous_name(&mut self, name: String) {
        self.data.anonymous_name = name;
    }

    pub fn auto_share_enabled(&self) -> bool {
        self.data.auto_share_enabled
    }

    pub fn set_auto_share_enabled(&mut self, enabled: bool) {
        self.data.auto_share_enabled = enabled;
    }

    pub fn last_milestone_index(&self) -> i32 {
        self.data.last_milestone_index
    }

    pub fn set_last_milestone_index(&mut self, index: i32) {
        self.data.last_milestone_index = index;
    }

    pub fn prune_old_entries(&mut self) {
        let cutoff = Local::now().date_naive() - chrono::Duration::days(30);
        self.data.daily_history.retain(|key, _| {
            chrono::NaiveDate::parse_from_str(key, "%Y-%m-%d")
                .map(|d| d >= cutoff)
                .unwrap_or(false)
        });
    }

    pub fn reset_all(&mut self) {
        self.data.total_distance_mm = 0.0;
        self.data.daily_history.clear();
        self.data.last_milestone_index = -1;
    }

    fn today_key() -> String {
        Local::now().format("%Y-%m-%d").to_string()
    }
}
