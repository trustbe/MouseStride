use parking_lot::Mutex;
use std::sync::atomic::{AtomicBool, Ordering};
use std::thread;

static ACCUMULATED_PIXELS: Mutex<f64> = Mutex::new(0.0);
static PREVIOUS_X: Mutex<Option<i32>> = Mutex::new(None);
static PREVIOUS_Y: Mutex<Option<i32>> = Mutex::new(None);
static RUNNING: AtomicBool = AtomicBool::new(false);

const TELEPORT_THRESHOLD: f64 = 500.0;

pub fn start() {
    if RUNNING.swap(true, Ordering::SeqCst) {
        return; // already running
    }

    thread::spawn(|| {
        run_hook_loop();
    });
}

pub fn drain_accumulated_pixels() -> f64 {
    let mut acc = ACCUMULATED_PIXELS.lock();
    let value = *acc;
    *acc = 0.0;
    value
}

pub fn reset_position() {
    *PREVIOUS_X.lock() = None;
    *PREVIOUS_Y.lock() = None;
}

#[cfg(windows)]
fn run_hook_loop() {
    use windows::Win32::Foundation::{LPARAM, LRESULT, WPARAM};
    use windows::Win32::UI::WindowsAndMessaging::{
        CallNextHookEx, GetMessageW, SetWindowsHookExW, UnhookWindowsHookEx, HHOOK, MSLLHOOKSTRUCT,
        MSG, WH_MOUSE_LL, WM_MOUSEMOVE,
    };

    unsafe extern "system" fn hook_callback(
        n_code: i32,
        w_param: WPARAM,
        l_param: LPARAM,
    ) -> LRESULT {
        if n_code >= 0 && w_param.0 as u32 == WM_MOUSEMOVE {
            let mouse_struct = &*(l_param.0 as *const MSLLHOOKSTRUCT);
            let cx = mouse_struct.pt.x;
            let cy = mouse_struct.pt.y;

            let mut prev_x = PREVIOUS_X.lock();
            let mut prev_y = PREVIOUS_Y.lock();

            if let (Some(px), Some(py)) = (*prev_x, *prev_y) {
                let dx = (cx - px) as f64;
                let dy = (cy - py) as f64;
                let distance = (dx * dx + dy * dy).sqrt();

                if distance <= TELEPORT_THRESHOLD {
                    *ACCUMULATED_PIXELS.lock() += distance;
                }
            }

            *prev_x = Some(cx);
            *prev_y = Some(cy);
        }

        unsafe { CallNextHookEx(HHOOK::default(), n_code, w_param, l_param) }
    }

    unsafe {
        let hook = SetWindowsHookExW(WH_MOUSE_LL, Some(hook_callback), None, 0);

        if let Ok(hook) = hook {
            let mut msg = MSG::default();
            while GetMessageW(&mut msg, None, 0, 0).as_bool() {
                // message loop keeps hook alive
            }
            let _ = UnhookWindowsHookEx(hook);
        }

        RUNNING.store(false, Ordering::SeqCst);
    }
}

#[cfg(target_os = "linux")]
fn run_hook_loop() {
    use rdev::{listen, Event, EventType};

    let callback = move |event: Event| {
        if let EventType::MouseMove { x, y } = event.event_type {
            let cx = x as i32;
            let cy = y as i32;

            let mut prev_x = PREVIOUS_X.lock();
            let mut prev_y = PREVIOUS_Y.lock();

            if let (Some(px), Some(py)) = (*prev_x, *prev_y) {
                let dx = (cx - px) as f64;
                let dy = (cy - py) as f64;
                let distance = (dx * dx + dy * dy).sqrt();

                if distance <= TELEPORT_THRESHOLD {
                    *ACCUMULATED_PIXELS.lock() += distance;
                }
            }

            *prev_x = Some(cx);
            *prev_y = Some(cy);
        }
    };

    if let Err(e) = listen(callback) {
        eprintln!("rdev listen error: {:?}", e);
    }

    RUNNING.store(false, Ordering::SeqCst);
}

#[cfg(target_os = "macos")]
fn run_hook_loop() {
    use core_graphics::event::{CGEventTap, CGEventTapLocation, CGEventTapPlacement, CGEventTapOptions, CGEventType, CallbackResult};
    use core_foundation::runloop::CFRunLoop;

    let event_types = vec![
        CGEventType::MouseMoved,
        CGEventType::LeftMouseDragged,
        CGEventType::RightMouseDragged,
    ];

    let tap = CGEventTap::new(
        CGEventTapLocation::HID,
        CGEventTapPlacement::HeadInsertEventTap,
        CGEventTapOptions::ListenOnly,
        event_types,
        |_proxy, _event_type, event| {
            let location = event.location();
            let cx = location.x as i32;
            let cy = location.y as i32;

            let mut prev_x = PREVIOUS_X.lock();
            let mut prev_y = PREVIOUS_Y.lock();

            if let (Some(px), Some(py)) = (*prev_x, *prev_y) {
                let dx = (cx - px) as f64;
                let dy = (cy - py) as f64;
                let distance = (dx * dx + dy * dy).sqrt();

                if distance <= TELEPORT_THRESHOLD {
                    *ACCUMULATED_PIXELS.lock() += distance;
                }
            }

            *prev_x = Some(cx);
            *prev_y = Some(cy);

            CallbackResult::Keep
        },
    );

    match tap {
        Ok(tap) => {
            unsafe {
                let loop_source = tap.mach_port().create_runloop_source(0).expect("failed to create run loop source");
                let run_loop = CFRunLoop::get_current();
                run_loop.add_source(&loop_source, core_foundation::runloop::kCFRunLoopCommonModes);
                tap.enable();
                CFRunLoop::run_current();
            }
        }
        Err(()) => {
            eprintln!("Failed to create CGEventTap - ensure Accessibility permissions are granted");
        }
    }

    RUNNING.store(false, Ordering::SeqCst);
}

#[cfg(not(any(windows, target_os = "linux", target_os = "macos")))]
fn run_hook_loop() {
    // Stub for unsupported platforms
    use std::time::Duration;
    while RUNNING.load(Ordering::SeqCst) {
        thread::sleep(Duration::from_secs(1));
    }
}
