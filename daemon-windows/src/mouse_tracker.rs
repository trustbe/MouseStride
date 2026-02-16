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
