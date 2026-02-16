# MouseStride Daemon — Homebrew Cask Distribution

**Date:** 2026-02-16
**Status:** Approved
**Goal:** Reduce macOS install friction by distributing a lightweight daemon via Homebrew

## Problem

MouseStride is distributed as an unsigned DMG. Users hit a Gatekeeper warning on first launch and must right-click → Open to bypass it. This creates friction and user drop-off.

## Solution

A separate, minimal daemon app (`MouseStrideDaemon`) distributed via Homebrew Cask. No Gatekeeper friction — Homebrew handles it.

## Architecture

### What the daemon does

- **Tracks mouse distance** in the background (reuses existing `MouseTracker` + `DistanceCalculator`)
- **Auto-syncs** anonymous stats to the community dashboard every 15 minutes via `DashboardService`
- **Menu bar icon** with live distance display (e.g. `↗ 3.1 km`)
  - **Left-click:** toggles between today's distance and all-time distance
  - **Right-click:** context menu with "Open Dashboard" and "Quit"
- **No windows, no popover, no settings UI** — `LSUIElement = true`
- **Persists data** via `UserDefaults(suiteName: "com.mousestride.daemon")` to avoid conflicts with the full app
- **Auto-detects** metric/imperial from user locale

### What the daemon does NOT do

- No milestones/achievements
- No share cards
- No settings/preferences UI
- No launch-at-login toggle (managed via `brew services` instead)

## Project Structure

```
Sources/
  MouseStride/              # existing full app (unchanged)
  MouseStrideDaemon/        # new minimal daemon
    App/
      MouseStrideDaemonApp.swift
      Info.plist
    Resources/
      MouseStride.icns
  MouseStrideCore/          # shared library (extracted from existing code)
    MouseTracker.swift
    DistanceCalculator.swift
    DistanceUnit.swift
    PersistenceService.swift
    DashboardService.swift
    AnonymousNameService.swift
Package.swift               # adds MouseStrideCore library + MouseStrideDaemon target
Makefile                    # adds daemon-specific build targets
```

### Shared code

`MouseStrideCore` is a new library target containing code used by both apps:
- `MouseTracker` — CGEvent-based mouse position tracking
- `DistanceCalculator` — pixel-to-real-world distance conversion
- `DistanceUnit` — metric/imperial detection
- `PersistenceService` — UserDefaults wrapper (parameterized suite name)
- `DashboardService` — anonymous stats sync to API
- `AnonymousNameService` — random animal name generation

Both `MouseStride` (full app) and `MouseStrideDaemon` depend on `MouseStrideCore`.

## Homebrew Distribution

### Tap repository

New GitHub repo: `trustbe/homebrew-mousestride`

Contains a single Cask file:

```ruby
cask "mousestride" do
  version "1.0.0"
  sha256 "abc123..."
  url "https://github.com/trustbe/MouseStride/releases/download/v#{version}/MouseStrideDaemon-v#{version}.zip"
  name "MouseStride"
  desc "Lightweight mouse distance tracker for macOS"
  homepage "https://trustbe.github.io/MouseStride/"
  app "MouseStrideDaemon.app"
end
```

### Install flow

```bash
brew tap trustbe/mousestride
brew install --cask mousestride
# App is now in /Applications, launch it:
open /Applications/MouseStrideDaemon.app
# Or use brew services for auto-launch at login:
brew services start mousestride
```

### Uninstall

```bash
brew services stop mousestride
brew uninstall --cask mousestride
```

## CI/CD Changes

### Release workflow update

Add a parallel job to `.github/workflows/release.yml`:

1. Build `MouseStrideDaemon` as universal binary (arm64 + x86_64)
2. Create `.app` bundle
3. Zip the `.app`
4. Upload zip to GitHub Release alongside existing DMG

### Tap auto-update

A second workflow (or post-release step) that:
1. Computes SHA256 of the uploaded zip
2. Updates the Cask formula in `trustbe/homebrew-mousestride` with new version + SHA
3. Commits and pushes the update

## Data Isolation

| Aspect | Full App | Daemon |
|--------|----------|--------|
| Bundle ID | `com.mousestride.app` | `com.mousestride.daemon` |
| UserDefaults suite | Standard | `com.mousestride.daemon` |
| Install location | `/Applications/MouseStride.app` | `/Applications/MouseStrideDaemon.app` |

Both can be installed simultaneously without conflict. They track independently.

## Menu Bar Behavior

- **Icon:** MouseStride cursor icon (small, ~18pt)
- **Text:** Live distance counter updated every second
- **Today mode:** `↗ 3.1 km` (arrow icon suggests movement/today)
- **All-time mode:** `Σ 847 km` (sigma icon suggests cumulative)
- **Left-click:** Toggle between today and all-time
- **Right-click context menu:**
  - Open Dashboard → opens web dashboard in default browser
  - ---
  - Quit MouseStride

## Coexistence with Full App

The full GUI app (`MouseStride.app`) continues to be distributed via DMG on GitHub Releases. The daemon is a separate, complementary offering for users who prefer a minimal footprint and Homebrew-based installation.
