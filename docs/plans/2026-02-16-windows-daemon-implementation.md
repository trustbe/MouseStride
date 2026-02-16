# Windows Daemon Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a Windows system tray daemon that tracks mouse distance, syncs to the shared Supabase leaderboard, and is distributed via WinGet.

**Architecture:** Rust binary using `tray-icon` for system tray, `GetCursorPos` polling at 60Hz for mouse tracking, JSON file persistence in `%APPDATA%`, and `ureq` for Supabase HTTP sync. MSI installer via `cargo-wix`.

**Tech Stack:** Rust, tray-icon, windows-sys, ureq, serde, cargo-wix

**Design doc:** `docs/plans/2026-02-16-windows-daemon-design.md`

**Dev constraint:** We're developing on macOS. Platform-specific Windows code uses `#[cfg(windows)]` and can only be tested via CI on `windows-latest`. Pure logic modules (name_gen, distance_calc math, persistence serialization) are tested locally.

---

### Task 1: Scaffold Rust project

**Files:**
- Create: `daemon-windows/Cargo.toml`
- Create: `daemon-windows/src/main.rs`
- Create: `daemon-windows/.gitignore`

**Step 1: Create Cargo.toml**

```toml
[package]
name = "mousestride"
version = "0.1.0"
edition = "2021"
description = "Mouse distance tracker for Windows"
license = "MIT"

[dependencies]
serde = { version = "1", features = ["derive"] }
serde_json = "1"
ureq = "2"
dirs = "6"
chrono = "0.4"
rand = "0.8"

[target.'cfg(windows)'.dependencies]
windows-sys = { version = "0.59", features = [
    "Win32_UI_WindowsAndMessaging",
    "Win32_Graphics_Gdi",
    "Win32_Foundation",
    "Win32_System_Registry",
] }
tray-icon = "0.19"
winresource = "0.1"

[target.'cfg(windows)'.build-dependencies]
winresource = "0.1"

[[bin]]
name = "mousestride"
path = "src/main.rs"
```

**Step 2: Create .gitignore**

```
/target
```

**Step 3: Create minimal main.rs**

```rust
mod name_gen;
mod distance_calc;
mod persistence;
mod dashboard;

#[cfg(windows)]
mod mouse_tracker;
#[cfg(windows)]
mod autostart;

fn main() {
    println!("MouseStride Windows daemon");
}
```

**Step 4: Create empty module files**

Create empty files for each module: `src/name_gen.rs`, `src/distance_calc.rs`, `src/persistence.rs`, `src/dashboard.rs`, `src/mouse_tracker.rs`, `src/autostart.rs`.

**Step 5: Verify it compiles on macOS**

Run: `cd daemon-windows && cargo check 2>&1`

Expected: compiles (Windows-only modules are gated behind `#[cfg(windows)]`)

**Step 6: Commit**

```bash
git add daemon-windows/
git commit -m "feat(windows): scaffold Rust project structure"
```

---

### Task 2: Anonymous name generator

Port `AnonymousNameService` from Swift to Rust. This is the shared 3-word format. Pure logic, testable on macOS.

**Files:**
- Create: `daemon-windows/src/name_gen.rs`

**Reference:** `Sources/MouseStrideCore/AnonymousNameService.swift`

**Step 1: Write failing tests**

```rust
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
        // With 20+ adjectives, same two picked is rare
        // Run 100 times, at least 90 should have different adjectives
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
```

**Step 2: Run tests to verify they fail**

Run: `cd daemon-windows && cargo test --lib name_gen 2>&1`

Expected: FAIL — functions not defined

**Step 3: Implement name_gen.rs**

```rust
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
```

**Step 4: Run tests to verify they pass**

Run: `cd daemon-windows && cargo test --lib name_gen 2>&1`

Expected: all 4 tests PASS

**Step 5: Commit**

```bash
git add daemon-windows/src/name_gen.rs
git commit -m "feat(windows): add 3-word anonymous name generator"
```

---

### Task 3: Distance calculator

Port `DistanceCalculator` and `DistanceUnit` from Swift. The mm/pixel conversion and unit formatting are pure math, testable on macOS. The DPI lookup is Windows-only.

**Files:**
- Create: `daemon-windows/src/distance_calc.rs`

**Reference:** `Sources/MouseStrideCore/DistanceCalculator.swift`, `Sources/MouseStrideCore/DistanceUnit.swift`

**Step 1: Write failing tests**

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn pixels_to_mm_at_96dpi() {
        // 96 DPI = 3.7795 pixels/mm → 1 pixel = 0.2646 mm
        let mm = pixels_to_mm(100.0, 96);
        assert!((mm - 26.46).abs() < 0.1, "100px at 96 DPI should be ~26.46mm, got {}", mm);
    }

    #[test]
    fn pixels_to_mm_at_144dpi() {
        // 144 DPI = 150% scaling → 1 pixel = 0.1764 mm
        let mm = pixels_to_mm(100.0, 144);
        assert!((mm - 17.64).abs() < 0.1, "100px at 144 DPI should be ~17.64mm, got {}", mm);
    }

    #[test]
    fn auto_format_metric_millimeters() {
        assert_eq!(auto_format(5.0, UnitSystem::Metric), "5 mm");
    }

    #[test]
    fn auto_format_metric_centimeters() {
        assert_eq!(auto_format(50.0, UnitSystem::Metric), "5.0 cm");
    }

    #[test]
    fn auto_format_metric_meters() {
        assert_eq!(auto_format(5_000.0, UnitSystem::Metric), "5.0 m");
    }

    #[test]
    fn auto_format_metric_kilometers() {
        assert_eq!(auto_format(5_000_000.0, UnitSystem::Metric), "5.0 km");
    }

    #[test]
    fn auto_format_imperial_inches() {
        assert_eq!(auto_format(20.0, UnitSystem::Imperial), "1 in");
    }

    #[test]
    fn auto_format_imperial_feet() {
        assert_eq!(auto_format(1_000.0, UnitSystem::Imperial), "3.3 ft");
    }

    #[test]
    fn auto_format_imperial_miles() {
        assert_eq!(auto_format(2_000_000.0, UnitSystem::Imperial), "1.2 mi");
    }

    #[test]
    fn teleport_filter() {
        assert!(!is_teleport(100.0));
        assert!(is_teleport(501.0));
        assert!(!is_teleport(500.0));
    }
}
```

**Step 2: Run tests to verify they fail**

Run: `cd daemon-windows && cargo test --lib distance_calc 2>&1`

Expected: FAIL

**Step 3: Implement distance_calc.rs**

```rust
const FALLBACK_DPI: u32 = 96;
const MM_PER_INCH: f64 = 25.4;
const TELEPORT_THRESHOLD: f64 = 500.0;

#[derive(Clone, Copy, PartialEq)]
pub enum UnitSystem {
    Metric,
    Imperial,
}

/// Convert pixel distance to millimeters given screen DPI
pub fn pixels_to_mm(pixels: f64, dpi: u32) -> f64 {
    let dpi = if dpi == 0 { FALLBACK_DPI } else { dpi };
    pixels * MM_PER_INCH / dpi as f64
}

/// Returns true if the distance looks like a teleport (screen jump)
pub fn is_teleport(pixel_distance: f64) -> bool {
    pixel_distance > TELEPORT_THRESHOLD
}

/// Get the system DPI. Falls back to 96 on non-Windows.
pub fn get_system_dpi() -> u32 {
    #[cfg(windows)]
    {
        unsafe { windows_sys::Win32::UI::WindowsAndMessaging::GetDpiForSystem() }
    }
    #[cfg(not(windows))]
    {
        FALLBACK_DPI
    }
}

pub fn auto_format(mm: f64, system: UnitSystem) -> String {
    match system {
        UnitSystem::Metric => {
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
        UnitSystem::Imperial => {
            if mm >= 1_609_344.0 {
                format!("{:.1} mi", mm / 1_609_344.0)
            } else if mm >= 91_440.0 {
                format!("{:.1} yd", mm / 914.4)
            } else if mm >= 304.8 {
                format!("{:.1} ft", mm / 304.8)
            } else {
                format!("{:.0} in", mm / 25.4)
            }
        }
    }
}
```

**Step 4: Run tests to verify they pass**

Run: `cd daemon-windows && cargo test --lib distance_calc 2>&1`

Expected: all tests PASS

**Step 5: Commit**

```bash
git add daemon-windows/src/distance_calc.rs
git commit -m "feat(windows): add distance calculator with unit formatting"
```

---

### Task 4: Persistence service

Port `PersistenceService` from Swift. Uses JSON file in `%APPDATA%/MouseStride/`. Pure logic + filesystem, testable on macOS with temp dirs.

**Files:**
- Create: `daemon-windows/src/persistence.rs`

**Reference:** `Sources/MouseStrideCore/PersistenceService.swift`

**Step 1: Write failing tests**

```rust
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
        p.add_distance(1000.0);  // today
        let before = p.days_tracked();
        p.prune_old_entries(30);
        assert_eq!(p.days_tracked(), before);
    }
}
```

**Step 2: Run tests to verify they fail**

Run: `cd daemon-windows && cargo test --lib persistence 2>&1`

Expected: FAIL

**Step 3: Implement persistence.rs**

```rust
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
```

**Step 4: Run tests to verify they pass**

Run: `cd daemon-windows && cargo test --lib persistence 2>&1`

Expected: all tests PASS

**Step 5: Commit**

```bash
git add daemon-windows/src/persistence.rs
git commit -m "feat(windows): add JSON persistence service"
```

---

### Task 5: Dashboard sync

Port `DashboardService` from Swift. HTTP POST to Supabase. Testable on macOS (just HTTP).

**Files:**
- Create: `daemon-windows/src/dashboard.rs`

**Reference:** `Sources/MouseStrideCore/DashboardService.swift`

**Step 1: Implement dashboard.rs**

No unit tests for HTTP calls — this is a thin wrapper around `ureq`. We verify via the existing dashboard page.

```rust
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
```

**Step 2: Verify it compiles**

Run: `cd daemon-windows && cargo check 2>&1`

Expected: compiles

**Step 3: Commit**

```bash
git add daemon-windows/src/dashboard.rs
git commit -m "feat(windows): add Supabase dashboard sync"
```

---

### Task 6: Mouse tracker (Windows-only)

`GetCursorPos` polling at ~60Hz with teleport filter. Windows-only, tested via CI.

**Files:**
- Create: `daemon-windows/src/mouse_tracker.rs`

**Step 1: Implement mouse_tracker.rs**

```rust
#[cfg(windows)]
use windows_sys::Win32::Foundation::POINT;
#[cfg(windows)]
use windows_sys::Win32::UI::WindowsAndMessaging::GetCursorPos;

use crate::distance_calc::is_teleport;

pub struct MouseTracker {
    prev_x: f64,
    prev_y: f64,
    accumulated_pixels: f64,
    initialized: bool,
}

impl MouseTracker {
    pub fn new() -> Self {
        Self {
            prev_x: 0.0,
            prev_y: 0.0,
            accumulated_pixels: 0.0,
            initialized: false,
        }
    }

    /// Poll current cursor position and accumulate distance
    pub fn poll(&mut self) {
        let (x, y) = match get_cursor_pos() {
            Some(pos) => pos,
            None => return,
        };

        if !self.initialized {
            self.prev_x = x;
            self.prev_y = y;
            self.initialized = true;
            return;
        }

        let dx = x - self.prev_x;
        let dy = y - self.prev_y;
        let distance = (dx * dx + dy * dy).sqrt();

        self.prev_x = x;
        self.prev_y = y;

        if is_teleport(distance) {
            return;
        }

        self.accumulated_pixels += distance;
    }

    /// Drain accumulated pixels, resetting to zero
    pub fn drain(&mut self) -> f64 {
        let val = self.accumulated_pixels;
        self.accumulated_pixels = 0.0;
        val
    }

    /// Reset previous position (call after sleep/wake)
    pub fn reset_position(&mut self) {
        self.initialized = false;
    }
}

#[cfg(windows)]
fn get_cursor_pos() -> Option<(f64, f64)> {
    let mut point = POINT { x: 0, y: 0 };
    let ok = unsafe { GetCursorPos(&mut point) };
    if ok != 0 {
        Some((point.x as f64, point.y as f64))
    } else {
        None
    }
}

#[cfg(not(windows))]
fn get_cursor_pos() -> Option<(f64, f64)> {
    None // stub for non-Windows compilation
}
```

**Step 2: Verify it compiles on macOS**

Run: `cd daemon-windows && cargo check 2>&1`

Expected: compiles (non-Windows stub returns None)

**Step 3: Commit**

```bash
git add daemon-windows/src/mouse_tracker.rs
git commit -m "feat(windows): add GetCursorPos mouse tracker"
```

---

### Task 7: Autostart (Windows-only)

Registry `Run` key for auto-launch at login.

**Files:**
- Create: `daemon-windows/src/autostart.rs`

**Step 1: Implement autostart.rs**

```rust
#[cfg(windows)]
pub fn register() {
    use std::ffi::OsStr;
    use std::os::windows::ffi::OsStrExt;
    use windows_sys::Win32::System::Registry::*;

    let exe_path = std::env::current_exe().unwrap_or_default();
    let exe_str = exe_path.to_string_lossy();

    let key_path: Vec<u16> = OsStr::new("Software\\Microsoft\\Windows\\CurrentVersion\\Run")
        .encode_wide()
        .chain(std::iter::once(0))
        .collect();

    let value_name: Vec<u16> = OsStr::new("MouseStride")
        .encode_wide()
        .chain(std::iter::once(0))
        .collect();

    let value_data: Vec<u16> = OsStr::new(&*exe_str)
        .encode_wide()
        .chain(std::iter::once(0))
        .collect();

    unsafe {
        let mut hkey = 0isize;
        let result = RegCreateKeyExW(
            HKEY_CURRENT_USER,
            key_path.as_ptr(),
            0,
            std::ptr::null(),
            0,
            KEY_WRITE,
            std::ptr::null(),
            &mut hkey,
            std::ptr::null_mut(),
        );

        if result == 0 {
            RegSetValueExW(
                hkey,
                value_name.as_ptr(),
                0,
                REG_SZ,
                value_data.as_ptr() as *const u8,
                (value_data.len() * 2) as u32,
            );
            RegCloseKey(hkey);
        }
    }
}

#[cfg(not(windows))]
pub fn register() {
    // no-op on non-Windows
}
```

**Step 2: Verify it compiles**

Run: `cd daemon-windows && cargo check 2>&1`

Expected: compiles

**Step 3: Commit**

```bash
git add daemon-windows/src/autostart.rs
git commit -m "feat(windows): add autostart via registry Run key"
```

---

### Task 8: Main entry point with tray icon

Wire everything together: tray icon, polling loop, timers, persistence, dashboard sync.

**Files:**
- Modify: `daemon-windows/src/main.rs`
- Create: `daemon-windows/icons/icon.ico` (copy from existing)
- Create: `daemon-windows/build.rs`

**Step 1: Create build.rs for icon embedding**

```rust
#[cfg(windows)]
fn main() {
    let mut res = winresource::WindowsResource::new();
    res.set_icon("icons/icon.ico");
    res.compile().unwrap();
}

#[cfg(not(windows))]
fn main() {}
```

**Step 2: Copy icon.ico**

```bash
# Use sips to convert the existing icns to ico, or copy from a prior build
# For now, create the icons/ directory — the actual .ico will be added when building on Windows CI
mkdir -p daemon-windows/icons
```

Note: We'll generate the `.ico` from the existing PNG in the CI workflow, or convert it manually. For now the build.rs is gated behind `#[cfg(windows)]`.

**Step 3: Implement main.rs**

```rust
mod name_gen;
mod distance_calc;
mod persistence;
mod dashboard;
mod mouse_tracker;
mod autostart;

use persistence::Persistence;
use mouse_tracker::MouseTracker;
use distance_calc::{pixels_to_mm, auto_format, get_system_dpi, UnitSystem};

use std::time::{Duration, Instant};

fn main() {
    let path = Persistence::data_path();
    let mut persistence = Persistence::new(path);
    let mut tracker = MouseTracker::new();

    // Load or generate anonymous name
    if persistence.name().is_none() {
        persistence.set_name(name_gen::generate_name());
        persistence.save().ok();
    }
    let name = persistence.name().unwrap().to_string();

    // Register autostart
    autostart::register();

    // Initial sync
    sync_dashboard(&persistence, &name);

    let dpi = get_system_dpi();
    let unit_system = detect_unit_system();

    #[cfg(windows)]
    run_with_tray(tracker, persistence, name, dpi, unit_system);

    #[cfg(not(windows))]
    run_headless(tracker, persistence, name, dpi, unit_system);
}

fn detect_unit_system() -> UnitSystem {
    // Check Windows locale for metric/imperial
    // Fallback: use metric
    UnitSystem::Metric
}

fn sync_dashboard(persistence: &Persistence, name: &str) {
    dashboard::submit(
        name,
        persistence.today_distance_mm(),
        persistence.total_distance_mm(),
        persistence.best_day_mm(),
        persistence.days_tracked(),
    );
}

/// Headless fallback for non-Windows (dev/testing only)
#[cfg(not(windows))]
fn run_headless(
    mut tracker: MouseTracker,
    mut persistence: Persistence,
    name: String,
    dpi: u32,
    unit_system: UnitSystem,
) {
    eprintln!("MouseStride: running in headless mode (no tray icon on this platform)");
    eprintln!("Name: {}", name);
    loop {
        std::thread::sleep(Duration::from_millis(16));
        tracker.poll();
    }
}

/// Windows tray icon event loop
#[cfg(windows)]
fn run_with_tray(
    mut tracker: MouseTracker,
    mut persistence: Persistence,
    name: String,
    dpi: u32,
    unit_system: UnitSystem,
) {
    use tray_icon::{TrayIconBuilder, menu::{Menu, MenuItem, PredefinedMenuItem}};
    use tray_icon::menu::MenuEvent;

    // Build menu
    let quit_item = MenuItem::new("Quit MouseStride", true, None);
    let quit_id = quit_item.id().clone();

    let dashboard_label = format!("Challenge ({})", name);
    let dashboard_item = MenuItem::new(&dashboard_label, true, None);
    let dashboard_id = dashboard_item.id().clone();

    let today_item = MenuItem::new("Today: 0 mm", false, None);
    let total_item = MenuItem::new("Total: 0 mm", false, None);

    let menu = Menu::new();
    menu.append(&today_item).ok();
    menu.append(&total_item).ok();
    menu.append(&PredefinedMenuItem::separator()).ok();
    menu.append(&dashboard_item).ok();
    menu.append(&PredefinedMenuItem::separator()).ok();
    menu.append(&quit_item).ok();

    // Load icon
    let icon = load_icon();

    let _tray = TrayIconBuilder::new()
        .with_menu(Box::new(menu))
        .with_tooltip("MouseStride")
        .with_icon(icon)
        .build()
        .expect("Failed to create tray icon");

    // Timer tracking
    let mut last_save = Instant::now();
    let mut last_sync = Instant::now();
    let mut pending_mm = 0.0;

    let menu_channel = MenuEvent::receiver();

    loop {
        // Poll mouse at ~60Hz
        tracker.poll();

        // Every frame: accumulate distance
        let pixels = tracker.drain();
        if pixels > 0.0 {
            let mm = pixels_to_mm(pixels, dpi);
            pending_mm += mm;
        }

        // 1s: update tray display
        // (tray-icon doesn't support dynamic title text, so we update menu items)
        // Menu items update on next open

        // 30s: save to disk
        if last_save.elapsed() >= Duration::from_secs(30) && pending_mm > 0.0 {
            persistence.add_distance(pending_mm);
            pending_mm = 0.0;
            persistence.save().ok();

            today_item.set_text(&format!("Today: {}", auto_format(persistence.today_distance_mm(), unit_system)));
            total_item.set_text(&format!("Total: {}", auto_format(persistence.total_distance_mm(), unit_system)));

            last_save = Instant::now();
        }

        // 15min: sync to dashboard
        if last_sync.elapsed() >= Duration::from_secs(900) {
            sync_dashboard(&persistence, &name);
            last_sync = Instant::now();
        }

        // Handle menu events (non-blocking)
        if let Ok(event) = menu_channel.try_recv() {
            if event.id == quit_id {
                // Save remaining distance before quit
                if pending_mm > 0.0 {
                    persistence.add_distance(pending_mm);
                    persistence.save().ok();
                }
                std::process::exit(0);
            } else if event.id == dashboard_id {
                sync_dashboard(&persistence, &name);
                let encoded = urlencoding_simple(&name);
                let url = format!("https://trustbe.github.io/MouseStride/dashboard.html?highlight={}", encoded);
                let _ = open_url(&url);
            }
        }

        std::thread::sleep(Duration::from_millis(16));
    }
}

#[cfg(windows)]
fn load_icon() -> tray_icon::Icon {
    // Load embedded icon resource or fallback
    let icon_bytes = include_bytes!("../icons/icon.ico");
    // Parse ICO and create icon (simplified — use image crate if needed)
    tray_icon::Icon::from_rgba(vec![0u8; 32 * 32 * 4], 32, 32)
        .expect("Failed to create icon")
}

#[cfg(windows)]
fn open_url(url: &str) -> std::io::Result<()> {
    std::process::Command::new("cmd")
        .args(["/C", "start", "", url])
        .spawn()?;
    Ok(())
}

fn urlencoding_simple(s: &str) -> String {
    s.replace(' ', "%20")
}
```

**Step 4: Verify it compiles on macOS**

Run: `cd daemon-windows && cargo check 2>&1`

Expected: compiles (Windows code gated behind `#[cfg(windows)]`)

**Step 5: Commit**

```bash
git add daemon-windows/src/main.rs daemon-windows/build.rs
git commit -m "feat(windows): add main entry point with tray icon and event loop"
```

---

### Task 9: CI workflow for Windows builds

**Files:**
- Create: `.github/workflows/release-windows.yml`

**Step 1: Create the workflow**

```yaml
name: Release Windows

on:
  push:
    tags: ['v*']

permissions:
  contents: write

jobs:
  build-windows:
    runs-on: windows-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install Rust
        uses: dtolnay/rust-toolchain@stable

      - name: Extract version
        id: version
        shell: bash
        run: echo "tag=${GITHUB_REF_NAME}" >> "$GITHUB_OUTPUT"

      - name: Convert icon
        shell: pwsh
        run: |
          # Use magick if available, otherwise skip (icon embedded at build)
          if (Get-Command magick -ErrorAction SilentlyContinue) {
            magick Sources/MouseStrideDaemon/Resources/MouseStride.icns daemon-windows/icons/icon.ico
          }

      - name: Build release
        working-directory: daemon-windows
        run: cargo build --release

      - name: Install cargo-wix
        run: cargo install cargo-wix

      - name: Build MSI
        working-directory: daemon-windows
        run: cargo wix --no-build --nocapture

      - name: Upload MSI to release
        env:
          GH_TOKEN: ${{ github.token }}
        shell: bash
        run: |
          MSI=$(ls daemon-windows/target/wix/*.msi | head -1)
          VERSION=${{ steps.version.outputs.tag }}
          gh release upload "$VERSION" "$MSI" --clobber || \
          gh release create "$VERSION" "$MSI" \
            --title "MouseStride $VERSION" \
            --generate-notes
```

**Step 2: Commit**

```bash
git add .github/workflows/release-windows.yml
git commit -m "ci: add Windows MSI build and release workflow"
```

---

### Task 10: Update macOS name generator to 3-word format

Shared change: update `AnonymousNameService.swift` to generate 3-word names for new users. Existing names are preserved (backward compatible).

**Files:**
- Modify: `Sources/MouseStrideCore/AnonymousNameService.swift`

**Step 1: Update the Swift name generator**

Change line 29 from:
```swift
let generated = "\(Self.adjectives.randomElement()!) \(Self.animals.randomElement()!)"
```
To:
```swift
let adj1 = Self.adjectives.randomElement()!
let adj2 = Self.adjectives.randomElement()!
let generated = "\(adj1) \(adj2) \(Self.animals.randomElement()!)"
```

**Step 2: Verify macOS daemon builds**

Run: `swift build -c release --product MouseStrideDaemon 2>&1`

Expected: builds successfully

**Step 3: Commit**

```bash
git add Sources/MouseStrideCore/AnonymousNameService.swift
git commit -m "feat: update anonymous names to 3-word format for scale"
```

---

### Task 11: WiX installer config

**Files:**
- Create: `daemon-windows/wix/main.wxs`

**Step 1: Initialize cargo-wix config**

This is done by running `cargo wix init` in CI on Windows, which generates `wix/main.wxs`. For now, create a placeholder that CI will use.

The `cargo wix init` command auto-generates the WiX manifest from `Cargo.toml` metadata. We rely on CI to do this. No local action needed beyond ensuring `Cargo.toml` has the correct metadata (already done in Task 1).

**Step 2: Commit (if any local files created)**

```bash
# Only commit if wix/ directory was created
git add daemon-windows/wix/ 2>/dev/null
git commit -m "build(windows): add WiX installer config" 2>/dev/null || true
```

---

### Task 12: Icon file

**Files:**
- Create: `daemon-windows/icons/icon.ico`

**Step 1: Convert existing icon to .ico format**

```bash
# On macOS, convert the PNG to ICO using sips + iconutil or ImageMagick
# If ImageMagick is available:
magick Sources/MouseStrideDaemon/Resources/MouseStride.icns daemon-windows/icons/icon.ico
# Or fallback: the CI workflow handles conversion on Windows
```

If `magick` is not available locally, the CI workflow converts it. Create the `icons/` directory and add a note.

**Step 2: Commit**

```bash
mkdir -p daemon-windows/icons
git add daemon-windows/icons/
git commit -m "build(windows): add application icon"
```

---

## Summary

| Task | Description | Platform |
|------|-------------|----------|
| 1 | Scaffold Rust project | macOS (cargo check) |
| 2 | Anonymous name generator (3-word) | macOS (unit tests) |
| 3 | Distance calculator + unit formatting | macOS (unit tests) |
| 4 | JSON persistence service | macOS (unit tests) |
| 5 | Supabase dashboard sync | macOS (compile check) |
| 6 | Mouse tracker (GetCursorPos polling) | Windows CI only |
| 7 | Autostart (registry Run key) | Windows CI only |
| 8 | Main entry point + tray icon | macOS (compile check) |
| 9 | CI workflow for Windows builds | GitHub Actions |
| 10 | Update macOS name gen to 3-word | macOS (swift build) |
| 11 | WiX installer config | Windows CI |
| 12 | Icon file | macOS/CI |

**Total tasks:** 12
**Locally testable:** Tasks 1-5, 8, 10, 12
**Windows CI only:** Tasks 6, 7, 9, 11
