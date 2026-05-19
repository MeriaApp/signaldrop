# Changelog

## 1.1.0 (build 7) — 2026-05-18

App Review compliance fix for Guideline 5.1.1(iv) — Privacy. The
pre-permission explainer screens (Location, Notifications) previously
used a directional "Allow"/"Enable" inner button and offered an exit
via a "Skip" footer button. Apple's guidance requires that pre-prompt
screens use neutral button labels ("Continue", "Next") and that the
user always proceed to the OS permission prompt after seeing the
explainer.

- Renamed step titles "Allow location access" → "Location access" and
  "Allow notifications" → "Notifications".
- Removed the inner "Allow"/"Enable" call-to-action; the only path
  forward is now the footer "Continue" button.
- Removed the "Skip" footer label; on permission steps the footer
  button is always "Continue" and tapping it directly triggers the
  CoreLocation / UNUserNotificationCenter authorization request.
- The post-onboarding "done" step still surfaces an honest summary
  when the user declined either permission in the OS prompt.

No functional WiFi-monitoring changes. Build 6 (previous submission)
is superseded.

## 1.0.2 — 2026-05-11

Fixes a stale-status bug where the menu header could keep showing
"Connected to <SSID>" hours after the connection actually changed,
plus a complete first-launch onboarding redesign.

### WiFi monitoring

- Restart CoreWLAN event monitoring on system wake. `CWWiFiClient`
  delegate callbacks can go silent across sleep/wake and never recover
  on their own; SignalDrop now re-registers all monitored events from
  `NSWorkspace.didWakeNotification`.
- Self-heal the status header from the 30 s periodic refresh by
  re-reading `currentState()` every tick instead of relying purely on
  delegate events.
- Require both `powerOn()` and a non-nil `ssid()` before reporting
  "connected" — guards against stale SSID strings while the radio is
  logically off.
- Detect non-WiFi internet paths via `NWPathMonitor` and render
  "WiFi Off — Online via Tether" / "Online via Ethernet" instead of
  silently showing a stale SSID when the active path bypasses WiFi.

### First-launch experience

- Replaced the legacy `NSAlert` welcome with a proper SwiftUI
  onboarding window (welcome → location → notifications → done) so
  the two permission prompts no longer race each other at startup.
- Onboarding includes a "Skip" path and explicit "Open System
  Settings" affordances for re-granting denied permissions.

### Build + distribution

- Universal binary (arm64 + x86_64) for Release builds — Intel Mac
  users can now run SignalDrop.
- About dialog reads version + build from `Info.plist` dynamically.
- `build-app.sh` and `package-dmg.sh` now read the version from
  `project.yml` (single source of truth) and hard-fail on missing
  notarization credentials. Both scripts run a `spctl --assess` check
  before declaring success.
- `uninstall.sh` now correctly removes the `signaldrop` binary and
  the `/Applications/SignalDrop.app` bundle (previous version
  referenced a stale `dropout` binary name).

## 1.0.0 — 2026-03-26

Initial release.

- Event-driven WiFi monitoring via CoreWLAN (zero polling)
- Instant disconnect/reconnect notifications with downtime duration
- Signal degradation warnings (-75 dBm threshold with hysteresis)
- SSID change detection
- Dead network auto-disconnect (leaves without forgetting the network)
- "Connected but no internet" detection via NWPathMonitor
- Manual disconnect from menu bar (Cmd+D)
- Notification throttling to prevent spam during WiFi flapping
- Event hooks — run custom scripts on any WiFi event
- SQLite event log with CSV export
- Menu bar status icon with daily stats
- Location Services support for SSID access on macOS 14+
- Developer ID signed and notarized by Apple
- Launch at login via SMAppService
