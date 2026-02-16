# Windows Daemon Design

**Date:** 2026-02-16
**Status:** Approved

## Overview

Build a Windows system tray daemon for MouseStride, mirroring the macOS daemon's functionality. Distributed via WinGet (Microsoft's package manager). Uses Rust with `tray-icon` crate and `GetCursorPos` polling for mouse tracking.

## Architecture

| Component | macOS (Swift) | Windows (Rust) |
|-----------|---------------|----------------|
| Mouse tracking | `NSEvent.addGlobalMonitorForEvents` | `GetCursorPos` polling at ~60Hz |
| Distance calc | `CGDisplayScreenSize` → mm/point | `GetDpiForSystem` → mm/pixel (96 DPI fallback) |
| System tray | `NSStatusItem` | `tray-icon` crate |
| Persistence | `UserDefaults` (plist) | JSON file in `%APPDATA%/MouseStride/` |
| Dashboard sync | `URLSession` POST to Supabase | `ureq` blocking HTTP |
| Auto-start | `SMAppService.register()` | Registry `HKCU\Software\Microsoft\Windows\CurrentVersion\Run` |
| Anonymous names | 3-word: Adjective + Adjective + Animal | Same word lists, identical generation |
| Installer | Homebrew cask (zip) | MSI via `cargo-wix`, distributed via WinGet |

## Anonymous Name System (Shared Change)

Current 2-word system (20 adj × 20 animals = 400 combinations) is insufficient for scale. Moving to 3-word format:

- **Format:** `"Adjective Adjective Animal"` (e.g., "Swift Cosmic Penguin")
- **Current lists (20×20×20):** 8,000 combinations
- **Target (100×100×100):** 1,000,000 combinations
- **Backward compatible:** Existing 2-word names are persisted and kept

Both macOS and Windows daemons share the same word lists and dashboard backend (same Supabase leaderboard, cross-platform).

## Data Flow

```
[GetCursorPos 60Hz poll]
    → accumulate pixel distance (with 500px teleport filter)
    → [1s timer] convert pixels→mm via DPI, update tray text
    → [30s timer] persist to %APPDATA%/MouseStride/data.json
    → [15min timer] POST to Supabase /rest/v1/entries
```

## Tray Menu

```
Today: 4.2 m
Total: 1.3 km
─────────────
Challenge (Swift Cosmic Penguin)  → opens dashboard in browser
─────────────
Quit MouseStride
```

## File Layout

```
daemon-windows/
├── Cargo.toml
├── build.rs              # embed icon in .exe
├── wix/                  # MSI installer config
│   └── main.wxs
├── icons/
│   └── icon.ico
└── src/
    ├── main.rs           # entry point, tray setup, event loop
    ├── mouse_tracker.rs  # GetCursorPos polling + teleport filter
    ├── distance_calc.rs  # DPI-aware pixel→mm conversion
    ├── persistence.rs    # JSON file in %APPDATA%
    ├── dashboard.rs      # Supabase HTTP sync
    ├── name_gen.rs       # 3-word anonymous names (shared word lists)
    └── autostart.rs      # Registry Run key management
```

## Key Crate Dependencies

- `tray-icon` — system tray icon and menu
- `windows-sys` — Win32 API bindings (GetCursorPos, GetDpiForSystem, registry)
- `ureq` — blocking HTTP client for Supabase sync
- `serde` + `serde_json` — JSON persistence
- `dirs` — cross-platform app data directory resolution
- `winresource` — embed icon in .exe at build time

## Distribution

### WinGet

1. CI builds `.msi` via `cargo-wix` on `v*` tag push
2. Upload MSI to GitHub release
3. Submit manifest to `microsoft/winget-pkgs`:

```yaml
PackageIdentifier: trustbe.MouseStride
PackageVersion: 1.0.0
InstallerUrl: https://github.com/trustbe/MouseStride/releases/download/v1.0.0/MouseStride-1.0.0.msi
InstallerSha256: ...
InstallerType: msi
```

Install: `winget install trustbe.MouseStride`

### CI Workflow

New `.github/workflows/release-windows.yml`:
- Trigger: push tag `v*`
- Runner: `windows-latest`
- Steps: checkout → install Rust → cargo build --release → cargo wix → upload MSI to release

## Persistence Format

`%APPDATA%/MouseStride/data.json`:

```json
{
  "anonymous_name": "Swift Cosmic Penguin",
  "total_distance_mm": 87000000,
  "daily_history": {
    "2026-02-16": 5400000,
    "2026-02-15": 3200000
  }
}
```

## Auto-Start

On first launch, add registry key:
```
HKCU\Software\Microsoft\Windows\CurrentVersion\Run
  MouseStride = "C:\Program Files\MouseStride\mousestride.exe"
```

## Decisions

| Decision | Rationale |
|----------|-----------|
| Polling over hooks | Simpler, no antivirus flags, 60Hz is sufficient for distance tracking |
| `tray-icon` crate | Maintained by Tauri team, well-tested on Windows |
| JSON over SQLite | Simpler, matches the macOS plist approach (key-value persistence) |
| `ureq` over `reqwest` | Blocking is fine (sync runs on timer), smaller binary, no async runtime needed |
| `cargo-wix` for MSI | WinGet requires MSI/MSIX, cargo-wix is the standard Rust MSI toolchain |
| Shared leaderboard | macOS and Windows users compete on the same Supabase dashboard |
| 3-word names | Scales to 1M+ combinations for millions of users |
