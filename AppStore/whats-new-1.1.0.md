# What's New — SignalDrop 1.1.0

**Marketing version:** 1.1.0
**Build:** 6
**Submission status:** STAGED, NOT SUBMITTED — Jesse approves the version
bump + reviewSubmission cancel/replace cycle separately.

---

## App Store Connect — "What's New" field (≤ 4000 chars)

```
v1.1 is the biggest upgrade since launch. SignalDrop now does much more
than catch disconnects — it explains them.

NETWORK INSIGHTS WINDOW
A new three-tab window (⌘N) gives you the picture every WiFi tool
should:

• Nearby networks — every AP your Mac can see, with signal bars,
  vendor identification (Apple, Cisco, TP-Link, Netgear, Ubiquiti,
  Google, Eero, Sagemcom, Arris, AVM, MikroTik and 19,000 others
  pulled from the IEEE registry), band, channel, and security.
  Sort, filter by 2.4 / 5 / 6 GHz, and spot your connected network
  at a glance.

• Signal graph — a live RSSI / Noise / TX-rate chart with hover
  inspection (cursor over any point shows the exact dBm, noise floor,
  SNR, and link rate at that moment), 1m / 5m / 15m / 1h time-range
  presets, and a pause button for when you want to study a specific
  moment without it scrolling away.

• Connection history — a 24h / 7d / 30d reliability report with an
  A–F grade, uptime %, outage count, total downtime, and a per-network
  rollup that tells you which network is actually responsible for your
  bad day. Click any outage to drill in — see the 60 seconds of
  signal/internet events leading up to the disconnect.

PDF "ISP-READY RECEIPT" EXPORT
Generate a branded one-page PDF of your reliability report — grade,
timeline strip, per-network breakdown, every outage with timestamps —
ready to send to your ISP, employer, or coworking-space landlord.

PHANTOM-DROP SUPPRESSION
Most disconnect notifiers fire on every 1-second flicker when your
Mac roams between access points. SignalDrop ignores drops shorter
than a threshold you set (5 seconds by default — tunable in Settings)
and only notifies when a real outage has lasted long enough to matter.
The History tab still records everything for the receipt.

NOTIFICATION SETTINGS WINDOW
A proper macOS preferences window (⌘,) with per-event toggles
(Disconnect / Reconnect / Weak signal / Internet unreachable / etc.),
minute-precision quiet hours, sound control, and a "Send test
notification" button so you can preview exactly what alerts will
look like.

PRESENTATION POLISH
• Menu bar icon now reflects state — full Wi-Fi glyph when connected,
  variable strength based on signal, exclamation when internet is
  unreachable, slash when WiFi is off.
• Hover annotations on the Signal Graph (timestamp, RSSI, Noise, SNR,
  TX rate — Apple Stocks-grade).
• "Connected" pill in the scanner so you can spot your network in a
  busy 20+ row scan.
• Grade pill in History has a hover tooltip explaining the math and
  what you'd need to clear for the next grade up.
• Accessibility labels on every custom control — VoiceOver speaks
  signal strength, tab names, toggle state.

For everyone running cafes, working from home, on a flaky hotel WiFi,
or just tired of guessing whether the slowness is the app or the
network — SignalDrop now has the answer.
```

Char count: ~3,140 (safe under 4,000).

---

## ASC API submission notes (for Jesse, when ready)

1. **Cancel the in-review 1.0.2 submission first.**
   ```
   PATCH /v1/reviewSubmissions/{rs_1_0_2_id}
   { "data": { "type": "reviewSubmissions", "id": "...", "attributes": { "canceled": true } } }
   ```
   (Reference memory: `reference_asc_review_submission_api_three_step_flow.md`.)

2. **Archive + upload 1.1.0 build 6:**
   ```
   xcodebuild -project SignalDrop.xcodeproj -scheme SignalDrop \
     -configuration Release -destination 'generic/platform=macOS' \
     -archivePath build/SignalDrop-1.1.0.xcarchive archive
   xcodebuild -exportArchive -archivePath build/SignalDrop-1.1.0.xcarchive \
     -exportPath build/SignalDrop-1.1.0 -exportOptionsPlist ExportOptions.plist
   xcrun altool --upload-app -f build/SignalDrop-1.1.0/SignalDrop.pkg \
     -t macos --apiKey 5RDJ5SQ5LK --apiIssuer "$ASC_API_ISSUER_ID"
   ```
   (Or use Transporter.app if API path fails.)

3. **Create reviewSubmission 1.1.0, attach version, submit:**
   The 3-step flow from `reference_asc_review_submission_api_three_step_flow.md`.
   Default `releaseType: AFTER_APPROVAL` (Jesse's standing preference —
   see `feedback_asc_default_release_type_after_approval.md`).

4. **No visual audit attachment required** — v1.1 doesn't change any
   reviewer-visible compliance surface (no paywall changes, no new
   permissions, no 3.1.2(a) disclosure changes). Cycle should be
   uneventful at App Review.

---

## What got cut from v1.1 (queued for v1.2+)

- Auto-scroll the Signal Graph to the outage timestamp when "Show in
  Signal Graph" is clicked from the History drill-in. v1.1 just
  switches the tab; time-range pre-scroll is a follow-up.
- Network / Band / Security columns sortable. Currently only Signal +
  Channel are sortable in v1.1 because their underlying types are
  trivially Comparable; the others need conformance wiring.
- Conditional "Likely cause" column hiding when 100% of rows are
  unclassified. Replaced with "Not classified" placeholder in v1.1.
  Conditional column hiding would require macOS 14.4+; we deploy to 13.0.
- Remote-host availability alerts (the new Jesse-suggested feature for
  Mac-mini-as-home-AI-hub monitoring). Captured in memory as a v1.2+
  candidate (`idea_signaldrop_remote_host_availability_alerts.md`).
