// Prevents additional console window on Windows in release
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use mouse_stride::commands::{self, AppState};
use mouse_stride::distance_calc;
use mouse_stride::milestones;
use mouse_stride::mouse_tracker;
use mouse_stride::name_gen;
use mouse_stride::persistence::PersistenceService;

use mouse_stride::dashboard;

use parking_lot::Mutex;
use std::sync::atomic::{AtomicBool, AtomicU64, Ordering};
use std::time::Duration;
use tauri::tray::TrayIconEvent;
use tauri::{Manager, PhysicalPosition, WindowEvent};

static LAST_TRAY_CLICK_MS: AtomicU64 = AtomicU64::new(0);
static SHOWING_WINDOW: AtomicBool = AtomicBool::new(false);

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

fn main() {
    // Initialize services
    distance_calc::init();

    let mut persistence = PersistenceService::new();
    persistence.prune_old_entries();

    // Generate anonymous name if empty
    if persistence.anonymous_name().is_empty() {
        let name = name_gen::generate_name();
        persistence.set_anonymous_name(name);
        persistence.save();
    }

    let initial_total = persistence.total_distance_mm();
    let initial_today = persistence.today_distance_mm();

    let app_state = AppState {
        persistence: Mutex::new(persistence),
        pending_mm: Mutex::new(0.0),
        today_mm: Mutex::new(initial_today),
        total_mm: Mutex::new(initial_total),
    };

    // Start mouse tracking
    mouse_tracker::start();

    tauri::Builder::default()
        .plugin(tauri_plugin_notification::init())
        .plugin(tauri_plugin_autostart::init(
            tauri_plugin_autostart::MacosLauncher::LaunchAgent,
            None,
        ))
        .plugin(tauri_plugin_shell::init())
        .manage(app_state)
        .invoke_handler(tauri::generate_handler![
            commands::get_stats,
            commands::get_milestones,
            commands::set_auto_share,
            commands::submit_to_community,
            commands::share_results,
            commands::get_anonymous_name,
            commands::quit_app,
        ])
        .on_tray_icon_event(|tray, event| {
            if let TrayIconEvent::Click { position, .. } = event {
                let now = std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)
                    .unwrap_or_default()
                    .as_millis() as u64;
                LAST_TRAY_CLICK_MS.store(now, Ordering::SeqCst);

                let app = tray.app_handle();
                if let Some(window) = app.get_webview_window("main") {
                    if window.is_visible().unwrap_or(false) {
                        let _ = window.hide();
                    } else {
                        // Set flag before showing to suppress the immediate
                        // focus-loss event that macOS fires when clicking the
                        // tray area
                        SHOWING_WINDOW.store(true, Ordering::SeqCst);

                        // Position window below the tray icon, centered horizontally
                        let win_width = 300.0_f64;
                        let x = position.x - win_width / 2.0;
                        let y = position.y;
                        let _ = window.set_position(PhysicalPosition::new(x as i32, y as i32));
                        let _ = window.show();
                        let _ = window.set_focus();
                    }
                }
            }
        })
        .on_window_event(|window, event| {
            match event {
                WindowEvent::Focused(true) => {
                    // Window gained focus — clear the showing flag
                    SHOWING_WINDOW.store(false, Ordering::SeqCst);
                }
                WindowEvent::Focused(false) => {
                    // If we just showed the window via tray click, consume
                    // the flag and skip this focus-loss event
                    if SHOWING_WINDOW.compare_exchange(
                        true, false, Ordering::SeqCst, Ordering::SeqCst
                    ).is_ok() {
                        return;
                    }

                    // Also guard with a time window for any other edge cases
                    let now = std::time::SystemTime::now()
                        .duration_since(std::time::UNIX_EPOCH)
                        .unwrap_or_default()
                        .as_millis() as u64;
                    let last_click = LAST_TRAY_CLICK_MS.load(Ordering::SeqCst);
                    if now.saturating_sub(last_click) > 500 {
                        let _ = window.hide();
                    }
                }
                _ => {}
            }
        })
        .setup(|app| {
            let app_handle = app.handle().clone();

            // Hide main window on startup
            if let Some(window) = app.get_webview_window("main") {
                let _ = window.hide();
            }

            // 1-second timer: drain mouse tracker, update state, check milestones
            let handle = app_handle.clone();
            std::thread::spawn(move || {
                loop {
                    std::thread::sleep(Duration::from_secs(1));

                    let pixels = mouse_tracker::drain_accumulated_pixels();
                    if pixels > 0.0 {
                        let mm = distance_calc::pixels_to_mm(pixels);
                        let state = handle.state::<AppState>();

                        *state.today_mm.lock() += mm;
                        *state.total_mm.lock() += mm;
                        *state.pending_mm.lock() += mm;
                    }

                    // Check milestones
                    let state = handle.state::<AppState>();
                    let total = *state.total_mm.lock();
                    let last_index = state.persistence.lock().last_milestone_index();

                    if let Some((new_index, milestone)) =
                        milestones::check_milestones(total, last_index)
                    {
                        state.persistence.lock().set_last_milestone_index(new_index);

                        // Send toast notification
                        use tauri_plugin_notification::NotificationExt;
                        let _ = handle
                            .notification()
                            .builder()
                            .title(&milestone.title)
                            .body(&milestone.body)
                            .show();
                    }

                    // Update tray tooltip
                    if let Some(tray) = handle.tray_by_id("main-tray") {
                        let text = format!("MouseStride - {}", format_distance(total));
                        let _ = tray.set_tooltip(Some(&text));
                    }
                }
            });

            // 30-second timer: persist to disk
            let handle = app_handle.clone();
            std::thread::spawn(move || {
                loop {
                    std::thread::sleep(Duration::from_secs(30));

                    let state = handle.state::<AppState>();
                    let pending = {
                        let mut p = state.pending_mm.lock();
                        let v = *p;
                        *p = 0.0;
                        v
                    };

                    if pending > 0.0 {
                        let mut persistence = state.persistence.lock();
                        persistence.add_total_distance_mm(pending);
                        persistence.add_to_today(pending);
                        persistence.save();
                    }
                }
            });

            // 15-minute timer: auto-share
            let handle = app_handle.clone();
            std::thread::spawn(move || {
                loop {
                    std::thread::sleep(Duration::from_secs(900));

                    let state = handle.state::<AppState>();
                    let today = *state.today_mm.lock();
                    let total = *state.total_mm.lock();

                    let persistence = state.persistence.lock();
                    if persistence.auto_share_enabled() {
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
                }
            });

            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
