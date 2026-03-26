# Dropout

A lightweight macOS menu bar app that notifies you the instant your WiFi drops.

macOS silently drops WiFi and hopes you notice. You're on a Zoom call, pushing code, or downloading something important — and the connection just vanishes. No notification. No sound. Nothing. You find out minutes later when things stop working.

**Dropout** fixes that. It uses Apple's CoreWLAN framework for **event-driven** monitoring (zero polling, zero battery impact) and sends a native macOS notification the moment your connection drops.

## Install

### Download (recommended)

Download `Dropout-1.0.0.dmg` from the [Releases](https://github.com/jessemeria/dropout/releases) page. Open the DMG and drag Dropout to your Applications folder.

### Build from source

```bash
git clone https://github.com/jessemeria/dropout.git
cd dropout
./Scripts/build-app.sh
open .build/app/Dropout.app
```

## Features

- **Instant disconnect/reconnect notifications** with downtime duration ("Back online after 47s")
- **Signal degradation warnings** before drops happen (-75 dBm threshold)
- **SSID change detection** — know when your Mac silently switches networks
- **"Connected but no internet"** detection via NWPathMonitor
- **Menu bar status icon** — live signal quality indicator
- **Event log** with SQLite storage and CSV export for ISP troubleshooting
- **Event hooks** — run custom scripts on WiFi events (Slack alerts, home automation, etc.)
- **Notification throttling** — smart deduplication prevents spam during WiFi flapping
- **Daily stats** — disconnects and total downtime at a glance
- **Launch at login** — set it and forget it
- **Signed with Developer ID** — no Gatekeeper warnings

## How It Works

Unlike shell-script hacks that poll every N seconds, Dropout registers for CoreWLAN events directly. The OS tells Dropout when something changes — no polling loop, no wasted battery, no missed events between polls.

| Monitor | What it catches |
|---------|----------------|
| `CWEventDelegate.linkDidChange` | WiFi connect/disconnect |
| `CWEventDelegate.ssidDidChange` | Network switches |
| `CWEventDelegate.linkQualityDidChange` | Signal degradation/recovery |
| `CWEventDelegate.powerDidChange` | WiFi radio on/off |
| `NWPathMonitor` | Internet reachability (WiFi up but no internet) |

## Menu Bar

Click the WiFi icon in your menu bar:

```
  Connected to HomeWiFi-5G
  Signal: Excellent (-42 dBm)
  Internet: Reachable
  ─────────────────────────────
  RECENT EVENTS
  2:30 PM  ● Reconnected (12s offline)
  2:29 PM  ○ Disconnected from HomeWiFi-5G
  1:15 PM  ● Signal weak (-75 dBm)
  ─────────────────────────────
  Today: 2 drops, 24s downtime
  ─────────────────────────────
  Sound Alerts            ✓
  Signal Warnings         ✓
  Launch at Login         ✓
  ─────────────────────────────
  Export Log...
  Event Hooks...
  ─────────────────────────────
  About Dropout
  Quit Dropout
```

## Event Hooks

Run custom scripts when WiFi events happen. Place executable `.sh` files in:

```
~/Library/Application Support/Dropout/hooks/
```

Available hooks:

| Script | Trigger |
|--------|---------|
| `on-disconnect.sh` | WiFi disconnected |
| `on-connect.sh` | WiFi reconnected |
| `on-ssid-change.sh` | Switched networks |
| `on-signal-weak.sh` | Signal below -75 dBm |
| `on-internet-lost.sh` | WiFi up, no internet |
| `on-internet-restored.sh` | Internet back |

Each script receives environment variables: `DROPOUT_EVENT`, `DROPOUT_SSID`, `DROPOUT_BSSID`, `DROPOUT_RSSI`, `DROPOUT_DETAILS`, `DROPOUT_TIMESTAMP`.

**Example** — post to Slack when WiFi drops:

```bash
#!/bin/bash
curl -X POST "https://hooks.slack.com/your/webhook" \
  -d "{\"text\":\"WiFi dropped from $DROPOUT_SSID at $(date)\"}"
```

## Data

| What | Where |
|------|-------|
| Event database | `~/Library/Application Support/Dropout/events.db` |
| Hook scripts | `~/Library/Application Support/Dropout/hooks/` |
| Hook log | `~/Library/Application Support/Dropout/hooks.log` |
| Preferences | UserDefaults (`com.meria.dropout`) |

Export your connection history as CSV from the menu bar for troubleshooting with your ISP.

## Requirements

- macOS 13 (Ventura) or later
- Location Services permission (macOS requires this for WiFi SSID access)

## Permissions

On first launch, Dropout asks for two permissions:

1. **Notifications** — to alert you when WiFi drops
2. **Location Services** — required by macOS to read WiFi network names (your location is never stored or sent anywhere)

If you skip Location Services, Dropout still monitors connect/disconnect events but can't display network names.

## Privacy

Dropout runs entirely on your Mac. No data is sent anywhere. No analytics. No telemetry. No network requests. It reads your local WiFi state through Apple's public CoreWLAN API and stores events in a local SQLite database.

## Uninstall

1. Quit Dropout from the menu bar
2. Delete `Dropout.app` from Applications
3. Optionally remove data: `rm -rf ~/Library/Application\ Support/Dropout`

## Why "Dropout"?

It's what your WiFi does when you're not looking.

## License

MIT — see [LICENSE](LICENSE)
