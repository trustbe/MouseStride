#![cfg_attr(windows, windows_subsystem = "windows")]
#![allow(unused_imports, unused_mut)]

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
    _persistence: Persistence,
    name: String,
    _dpi: u32,
    _unit_system: UnitSystem,
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

    // Load tray icon from pre-rendered 32x32 white RGBA data (visible on dark taskbar)
    let icon_rgba = include_bytes!("../icons/icon-32x32-white.rgba").to_vec();
    let icon = tray_icon::Icon::from_rgba(icon_rgba, 32, 32)
        .expect("Failed to create tray icon from embedded RGBA data");

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

        // Accumulate distance
        let pixels = tracker.drain();
        if pixels > 0.0 {
            let mm = pixels_to_mm(pixels, dpi);
            pending_mm += mm;
        }

        // 30s: save to disk and update menu
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
                if pending_mm > 0.0 {
                    persistence.add_distance(pending_mm);
                    persistence.save().ok();
                }
                std::process::exit(0);
            } else if event.id == dashboard_id {
                sync_dashboard(&persistence, &name);
                let encoded = name.replace(' ', "%20");
                let url = format!("https://trustbe.github.io/MouseStride/dashboard.html?highlight={}", encoded);
                let _ = std::process::Command::new("cmd")
                    .args(["/C", "start", "", &url])
                    .spawn();
            }
        }

        std::thread::sleep(Duration::from_millis(16));
    }
}
