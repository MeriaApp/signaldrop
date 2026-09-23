# App Store listing vs. the app: accuracy check (2026-09-23)

The live listing (fetched from the public iTunes lookup API on 2026-09-23, v1.1.0) was checked claim by
claim against `Sources/SignalDrop/`. On the Mac App Store, the description can only change with a new
version submission, so these edits ride along with the next build.

## Claims that don't match the app

1. **"Connected but no internet detection: catches dead networks that look online but aren't."**
   `NetworkMonitor.swift` uses `NWPathMonitor` `path.status == .satisfied`. That reports whether the
   Mac has a usable route (an interface with an IP and a gateway). It does not test whether the
   internet actually answers. If the router is up but the ISP is down, it still reads "satisfied", and
   the menu keeps showing "Internet: Reachable". So the app catches losing the route, not the case the
   listing describes. The only way to catch that case is a periodic lightweight probe, and that
   conflicts with "SignalDrop makes zero network requests". That is a product decision (see below).
2. **"Instant disconnect and reconnect notifications with exact downtime duration."** Reconnect
   notifications, which carry the downtime, are off by default (`notify.connected = false` in
   `NotificationSettings.swift`). Disconnect alerts also wait 5 s by default (phantom-drop
   suppression) before firing, so they aren't instant.
3. **"Zero polling means zero battery impact and zero missed events between polls."** The app re-reads
   CoreWLAN every 30 s to recover from event delivery that goes silent after sleep, and the Signal Graph
   samples every 1 s while Network Insights is open. The impact is negligible, not zero.
4. **"WHAT'S COMING: v1.1: Nearby network scanner + real-time signal/noise graphs."** v1.1 is live and
   already includes both. The v1.5 line promises "AP vendor identification", which also shipped in v1.1.
   The v1.5 and v2.0 items are promises the app hasn't kept yet, so drop the roadmap entirely.
5. **Release notes: "19,000 others pulled from the IEEE registry".** The bundled registry has about
   39,000 entries. That's an understatement rather than a false claim, and it fixes itself in the next
   version's notes.

## Claims that do match

- A –75 dBm weak-signal threshold with recovery at –65 dBm (hysteresis): `WiFiMonitor.swift:51-52`.
- SSID-change alerts exist; they are off by default and toggled in Settings.
- The A–F grade, per-network uptime, CSV export, copy-receipt, PDF export, quiet hours, test
  notification and launch at login all exist.
- Zero network requests in the App Store build: no `URLSession` or `NWConnection` anywhere, and the
  webhook and updater code is compiled out under `APPSTORE`.

## Proposed description (drop-in replacement)

macOS doesn't tell you when your WiFi disconnects. The icon goes from full bars to empty bars and hopes you notice. You find out minutes later when your video call freezes, your terminal hangs, or your upload fails.

SignalDrop fixes that. It's a lightweight Mac menu bar app that watches your WiFi and sends a macOS notification when your connection drops, your signal weakens, or your Mac loses its route to the internet.

WHAT IT DOES:

• Disconnect notifications as soon as a drop lasts longer than 5 seconds (adjustable), so 1-second roaming flickers don't spam you
• Optional reconnect notifications showing exactly how long you were offline
• Signal-weakness warnings before your connection drops (–75 dBm threshold with hysteresis to avoid notification spam)
• Internet-loss alerts when your Mac loses its route to the internet
• Optional alerts when your Mac silently switches networks
• Connection quality grade (A through F) based on 24-hour stability
• Per-network reliability tracking with uptime percentages and disconnect counts
• Network Insights: nearby networks with vendor identification, a live signal and noise graph, and 24-hour, 7-day and 30-day connection history
• ISP-ready receipt: one-click copy of an outage timeline, or a one-page PDF report, to send to your ISP
• Event log with CSV export
• Per-event notification settings, quiet hours, and a test-notification button
• Launch at login: set it and forget it

HOW IT WORKS:

SignalDrop uses Apple's CoreWLAN framework to be notified by macOS the moment your WiFi changes, rather than constantly polling. Battery impact is negligible.

PRIVACY:

SignalDrop makes zero network requests. No analytics. No telemetry. No accounts. No data leaves your Mac. WiFi events are stored in a local database that you control. Your location (required by macOS for WiFi network names) is never recorded or transmitted.

## Decision for Jesse: "connected but no internet"

- **Option A (recommended): reword it**, as in the description above. The listing stays true today,
  and the "zero network requests" privacy promise stays intact.
- **Option B: build real detection.** A light probe (for example, an HTTP request to
  `captive.apple.com` every 30–60 s while WiFi is connected) would catch an ISP that's down while
  WiFi stays up. That is the feature people actually want from this app. But it makes the privacy
  line false, so the privacy section, the privacy policy at jessemeria.com/signaldrop/privacy, and the
  App Privacy answers would all need rewording (a probe sends no user data, but it is a network
  request).
