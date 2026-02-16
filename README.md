# MouseStride

A lightweight macOS menu bar daemon that tracks how far your mouse cursor travels.

## Features

- **Real-time distance tracking** — today and all-time stats in the menu bar, DPI-aware
- **Automatic unit detection** — metric or imperial based on your locale
- **Community dashboard** — anonymous stats auto-sync to a live leaderboard every 15 minutes
- **Zero UI** — runs silently in the menu bar, click for stats and dashboard link

## Requirements

- macOS 13.0 (Ventura) or later

## Install

### Download

Grab the [latest zip](https://github.com/trustbe/MouseStride/releases/download/v0.0.2/MouseStrideDaemon-v0.0.2.zip), unzip, and move **MouseStrideDaemon.app** to `/Applications`.

> **Note:** MouseStride is not code-signed. On first launch, right-click the app → **Open** → click **Open** in the dialog.

### Homebrew

```bash
brew tap trustbe/mousestride
brew install --cask mousestride
open /Applications/MouseStrideDaemon.app
```

### Build from source

```bash
git clone https://github.com/trustbe/MouseStride.git
cd MouseStride
make daemon-bundle
open MouseStrideDaemon.app
```

## Uninstall

```bash
rm -rf /Applications/MouseStrideDaemon.app
```

## Privacy

- No account or login required
- All tracking data stored locally via UserDefaults
- Community sync is anonymous — only distance and a random animal name are shared
- No analytics, no telemetry

## Community Dashboard

See how your cursor stacks up: [Community Dashboard](https://trustbe.github.io/MouseStride/dashboard.html)

## License

[MIT](LICENSE)
