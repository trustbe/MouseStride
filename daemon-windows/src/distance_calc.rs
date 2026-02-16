// Distance calculation utilities

const FALLBACK_DPI: u32 = 96;
const MM_PER_INCH: f64 = 25.4;
const TELEPORT_THRESHOLD: f64 = 500.0;

#[derive(Clone, Copy, PartialEq)]
pub enum UnitSystem {
    Metric,
    Imperial,
}

/// Convert pixel distance to millimeters given screen DPI.
pub fn pixels_to_mm(pixels: f64, dpi: u32) -> f64 {
    let dpi = if dpi == 0 { FALLBACK_DPI } else { dpi };
    pixels * MM_PER_INCH / dpi as f64
}

/// Returns true if the distance looks like a teleport (screen jump).
pub fn is_teleport(pixel_distance: f64) -> bool {
    pixel_distance > TELEPORT_THRESHOLD
}

/// Get the system DPI. Falls back to 96 on non-Windows.
pub fn get_system_dpi() -> u32 {
    #[cfg(windows)]
    {
        unsafe { windows_sys::Win32::UI::HiDpi::GetDpiForSystem() }
    }
    #[cfg(not(windows))]
    {
        FALLBACK_DPI
    }
}

/// Auto-format a distance in millimeters to the best human-readable unit.
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn pixels_to_mm_at_96dpi() {
        let mm = pixels_to_mm(100.0, 96);
        assert!((mm - 26.46).abs() < 0.1, "100px at 96 DPI should be ~26.46mm, got {}", mm);
    }

    #[test]
    fn pixels_to_mm_at_144dpi() {
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
