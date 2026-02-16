# MouseStride

A lightweight system tray app that tracks how far your mouse cursor travels. Available for macOS and Windows.

## Features

- **Real-time distance tracking** — today and all-time stats in the system tray, DPI-aware
- **Automatic unit detection** — metric or imperial based on your locale
- **Community dashboard** — anonymous stats auto-sync to a live leaderboard every 15 minutes
- **Zero UI** — runs silently in the system tray, click for stats and dashboard link
- **Cross-platform** — same leaderboard for macOS and Windows users

## Install

### macOS

**Requirements:** macOS 13.0 (Ventura) or later

#### Homebrew (recommended)

```bash
brew tap trustbe/mousestride
brew install --cask mousestride
```

#### Manual download

Grab the [latest zip](https://github.com/trustbe/MouseStride/releases/latest), unzip, and move **MouseStrideDaemon.app** to `/Applications`.

> **Note:** MouseStride is not code-signed. On first launch, right-click the app → **Open** → click **Open** in the dialog.

#### Build from source

```bash
git clone https://github.com/trustbe/MouseStride.git
cd MouseStride
make daemon-bundle
open MouseStrideDaemon.app
```

### Windows

**Requirements:** Windows 10 or later

#### Manual download

Grab the [latest MSI](https://github.com/trustbe/MouseStride/releases/latest) and run the installer.

#### Build from source

```bash
git clone https://github.com/trustbe/MouseStride.git
cd MouseStride/daemon-windows
cargo build --release
```

## Uninstall

### macOS

#### Homebrew

```bash
brew uninstall --cask mousestride
```

#### Manual

```bash
rm -rf /Applications/MouseStrideDaemon.app
rm -f ~/Library/Preferences/com.mousestride.daemon.plist
```

### Windows

Uninstall via **Settings → Apps → MouseStride → Uninstall**, or run the MSI installer again and choose Remove.

## Privacy

- No account or login required
- All tracking data stored locally via UserDefaults
- Community sync is anonymous — only distance and a random animal name are shared
- No analytics, no telemetry

## Community Dashboard

See how your cursor stacks up: [Community Dashboard](https://trustbe.github.io/MouseStride/dashboard.html)

## License

[MIT](LICENSE)
