# dropout

A lightweight macOS menu bar app that notifies you the instant your WiFi drops.

macOS silently drops WiFi and hopes you notice. You're on a Zoom call, pushing code, or downloading something important — and the connection just vanishes. No notification. No sound. Nothing. You find out minutes later when things stop working.

**dropout** fixes that. It uses Apple's CoreWLAN framework for **event-driven** monitoring (zero polling, zero battery impact) and sends a native macOS notification the moment your connection drops.

## Features

- **Instant disconnect/reconnect notifications** with downtime duration ("Back online after 47s")
- **Signal degradation warnings** before drops happen (-75 dBm threshold)
- **SSID change detection** — know when your Mac silently switches networks
- **"Connected but no internet"** detection via NWPathMonitor
- **Menu bar status icon** — wifi / wifi.slash / wifi.exclamationmark
- **Event log** with SQLite storage and CSV export (for ISP troubleshooting)
- **Daily stats** — disconnects and total downtime at a glance
- **Launch at login** — set it and forget it
- **Configurable** — toggle sounds, signal warnings from the menu

## How It Works

Unlike shell-script hacks that poll every N seconds, dropout registers for CoreWLAN events directly. The OS tells dropout when something changes — no polling loop, no wasted battery, no missed events between polls.

| Monitor | What it catches |
|---------|----------------|
| `CWEventDelegate.linkDidChange` | WiFi connect/disconnect |
| `CWEventDelegate.ssidDidChange` | Network switches |
| `CWEventDelegate.linkQualityDidChange` | Signal degradation/recovery |
| `CWEventDelegate.powerDidChange` | WiFi radio on/off |
| `NWPathMonitor` | Internet reachability (WiFi up but no internet) |

## Requirements

- macOS 13 (Ventura) or later
- Swift 5.9+
- Location Services permission (macOS requires this for WiFi SSID access)

## Install

```bash
git clone https://github.com/yourusername/dropout.git
cd dropout
chmod +x Scripts/install.sh
./Scripts/install.sh
```

This builds from source, installs the binary, and creates a LaunchAgent for auto-start.

## Uninstall

```bash
./Scripts/uninstall.sh          # keeps event database
./Scripts/uninstall.sh --purge  # removes everything
```

## Build from Source

```bash
swift build -c release
.build/release/dropout
```

## Menu Bar

Click the WiFi icon in your menu bar to see:

```
  Connected to HomeWiFi-5G
  Signal: Excellent (-42 dBm)
  Internet: Reachable
  ─────────────────────────
  RECENT EVENTS
  2:30 PM  ● Reconnected (12s offline)
  2:29 PM  ○ Disconnected
  1:15 PM  ● Signal weak (-75 dBm)
  ─────────────────────────
  Today: 2 drops, 24s downtime
  ─────────────────────────
  Sound Alerts          ✓
  Signal Warnings       ✓
  Launch at Login       ✓
  ─────────────────────────
  Export Log...
  Quit Dropout
```

## Data

- **Event database:** `~/Library/Application Support/Dropout/events.db`
- **Log file:** `~/Library/Application Support/Dropout/dropout.log`
- **Preferences:** stored in UserDefaults (`com.meria.dropout`)

Export your connection history as CSV from the menu bar for troubleshooting with your ISP.

## Privacy

dropout runs entirely on your Mac. No data is sent anywhere. No analytics. No network requests. It only reads your local WiFi state through Apple's public CoreWLAN API.

## Why "dropout"?

It's what your WiFi does when you're not looking.

## License

MIT
