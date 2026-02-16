# MouseStride

A lightweight macOS menu bar app that tracks how far your mouse cursor travels.

## Features

- **Real-time distance tracking** — today and all-time stats, DPI-aware
- **Automatic unit detection** — metric or imperial based on your locale
- **Milestones & achievements** — unlock badges as your cursor racks up distance
- **Community Sync** — optionally share anonymous stats to a live leaderboard
- **Share Results** — generate a share card with your stats
- **Launch at Login** — start tracking automatically with your Mac

## Requirements

- macOS 13.0 (Ventura) or later
- Swift 5.9+ (for building from source)

## Install

### Download (recommended)

Grab the latest DMG from [GitHub Releases](https://github.com/trustbe/MouseStride/releases), open it, and drag **MouseStride.app** to `/Applications`.

> **Note:** MouseStride is not code-signed. On first launch, macOS will block it. Right-click the app → **Open** → click **Open** in the dialog to allow it.

### Homebrew (daemon only)

A lightweight background daemon — tracks distance, shows live stats in the menu bar, auto-syncs to the community dashboard. No UI popover.

```bash
brew tap trustbe/mousestride
brew install --cask mousestride
open /Applications/MouseStrideDaemon.app
```

### Build from source

```bash
git clone https://github.com/trustbe/MouseStride.git
cd MouseStride
./install.sh
```

Or manually:

```bash
make bundle
open MouseStride.app
```

## Uninstall

```bash
# Remove the app
rm -rf /Applications/MouseStride.app

# Remove launch-at-login entry (if enabled)
rm -f ~/Library/LaunchAgents/com.mousestride.app.plist
```

## Privacy

MouseStride is designed with privacy in mind:

- No account or login required
- All tracking data is stored locally via UserDefaults
- Community Sync is opt-in and strictly anonymous — only distance and a random animal name are shared
- No analytics, no telemetry

## Community Dashboard

See how your cursor stacks up: [Community Dashboard](https://trustbe.github.io/MouseStride/dashboard.html)

## License

[MIT](LICENSE)
