use parking_lot::Mutex;

static MM_PER_PIXEL: Mutex<f64> = Mutex::new(0.2646); // 96 DPI fallback

pub fn init() {
    refresh_dpi();
}

pub fn refresh_dpi() {
    let mm_per_px = calculate_mm_per_pixel();
    *MM_PER_PIXEL.lock() = mm_per_px;
}

pub fn pixels_to_mm(pixels: f64) -> f64 {
    pixels * *MM_PER_PIXEL.lock()
}

#[cfg(windows)]
fn calculate_mm_per_pixel() -> f64 {
    use windows::Win32::Graphics::Gdi::{GetDC, GetDeviceCaps, ReleaseDC, HORZRES, HORZSIZE};

    unsafe {
        let hdc = GetDC(None);
        if hdc.is_invalid() {
            return 0.2646;
        }

        let width_mm = GetDeviceCaps(hdc, HORZSIZE) as f64;
        let width_px = GetDeviceCaps(hdc, HORZRES) as f64;

        ReleaseDC(None, hdc);

        if width_mm > 0.0 && width_px > 0.0 {
            width_mm / width_px
        } else {
            0.2646
        }
    }
}

#[cfg(not(windows))]
fn calculate_mm_per_pixel() -> f64 {
    0.2646
}
