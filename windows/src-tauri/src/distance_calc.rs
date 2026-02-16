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

#[cfg(target_os = "linux")]
fn calculate_mm_per_pixel() -> f64 {
    // Parse xrandr output to get physical display size and resolution
    if let Ok(output) = std::process::Command::new("xrandr").output() {
        let stdout = String::from_utf8_lossy(&output.stdout);
        // Look for a connected display line with resolution and physical size
        // e.g. "1920x1080+0+0 ... 527mm x 296mm"
        for line in stdout.lines() {
            if !line.contains(" connected") {
                continue;
            }
            // Find physical size: "NNNmm x NNNmm"
            if let Some(mm_pos) = line.find("mm x ") {
                // Parse width_mm (number before "mm x")
                let before_mm = &line[..mm_pos];
                let width_mm: Option<f64> = before_mm
                    .rsplit_once(' ')
                    .and_then(|(_, num)| num.parse().ok());

                // Parse height_mm (number after "mm x ", ending at "mm")
                let after_x = &line[mm_pos + 5..]; // skip "mm x "
                let height_mm: Option<f64> = after_x
                    .split("mm")
                    .next()
                    .and_then(|num| num.trim().parse().ok());

                // Find resolution: "NNNNxNNNN" pattern
                let resolution: Option<(f64, f64)> = line
                    .split_whitespace()
                    .find_map(|word| {
                        let parts: Vec<&str> = word.split('x').collect();
                        if parts.len() == 2 {
                            if let (Ok(w), Ok(h)) = (
                                parts[0].parse::<f64>(),
                                parts[1].split('+').next().unwrap_or("").parse::<f64>(),
                            ) {
                                if w > 100.0 && h > 100.0 {
                                    return Some((w, h));
                                }
                            }
                        }
                        None
                    });

                if let (Some(w_mm), Some(w_px)) = (width_mm, resolution.map(|(w, _)| w)) {
                    if w_mm > 0.0 && w_px > 0.0 {
                        return w_mm / w_px;
                    }
                }

                // Try with height if width failed
                if let (Some(h_mm), Some(h_px)) = (height_mm, resolution.map(|(_, h)| h)) {
                    if h_mm > 0.0 && h_px > 0.0 {
                        return h_mm / h_px;
                    }
                }
            }
        }
    }
    0.2646 // fallback
}

#[cfg(target_os = "macos")]
fn calculate_mm_per_pixel() -> f64 {
    use core_graphics::display::CGDisplay;

    let display = CGDisplay::main();
    let size_mm = display.screen_size();   // CGSize in mm
    let width_px = display.pixels_wide() as f64;

    if size_mm.width > 0.0 && width_px > 0.0 {
        size_mm.width / width_px
    } else {
        0.2646
    }
}

#[cfg(not(any(windows, target_os = "linux", target_os = "macos")))]
fn calculate_mm_per_pixel() -> f64 {
    0.2646
}
