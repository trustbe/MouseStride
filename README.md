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

#### Installer

Download the [latest **MouseStride.pkg**](https://github.com/trustbe/MouseStride/releases/latest), double-click it, and follow the installer. The menu-bar icon appears immediately after install. On first mouse movement, macOS will ask permission for Input Monitoring — click **Allow**.

The installer is signed and notarized by Apple, so Gatekeeper will not warn you.

#### Build from source

```bash
git clone https://github.com/trustbe/MouseStride.git
cd MouseStride
make bundle
open MouseStrideDaemon.app
```

### Windows

**Requirements:** Windows 10 or later

#### winget (recommended)

```powershell
winget install trustbe.mousestride
```

#### Manual download

Grab the [latest MSI](https://github.com/trustbe/MouseStride/releases/latest) and run the installer.

> **Note:** The MSI is not code-signed. On first launch, Windows SmartScreen may show "Unknown publisher" — click **More info** → **Run anyway**. `winget` verifies the installer by SHA256 and skips this warning.

#### Build from source

```bash
git clone https://github.com/trustbe/MouseStride.git
cd MouseStride/daemon-windows
cargo build --release
```

## Uninstall

### macOS

```bash
rm -rf /Applications/MouseStrideDaemon.app
rm -f ~/Library/Preferences/com.mousestride.daemon.plist
```

### Windows

Uninstall via **Settings → Apps → MouseStride → Uninstall**, or run the MSI installer again and choose Remove.

## Privacy

- No account or login required
- All tracking data stored locally on your device
- Community sync is anonymous — only distance and a random animal name are shared
- No analytics, no telemetry

## Community Dashboard

See how your cursor stacks up: [Community Dashboard](https://mousestride.trustbe.com/dashboard.html)

## License

[MIT](LICENSE)
