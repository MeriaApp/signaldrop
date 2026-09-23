# SignalDrop 1.2.0: making the listing true (2026-09-23)

The live v1.1.0 listing (from the public iTunes lookup API, 2026-09-23) was checked claim by claim
against `Sources/SignalDrop/`. Jesse's direction: if a claim is important, build it rather than drop it.

## What changed in the app for 1.2.0 (build 8)

| Listing claim | Was | Now |
|---|---|---|
| "Connected but no internet" detection | `NWPathMonitor` path status only, which is blind to an ISP outage behind a working router | `NetworkMonitor.swift` confirms reachability with an HTTPS check to `captive.apple.com` every 30 s (120 s on hotspots or in Low Data Mode). Two failures in a row mean offline; it rechecks every 10 s while offline and re-arms after wake. |
| Disconnect and reconnect alerts with exact downtime | Reconnect alerts off by default, so the downtime was never shown | Any drop SignalDrop alerted you to is followed by a "back" alert with the downtime (quiet hours still apply). "Internet restored" now carries its downtime too. |
| "Notifications disabled" shown correctly | Stale after first-launch onboarding (Madison's report) | Re-read on menu open, every 30 s, and after onboarding |
| (no claim) | Losing WiFi also fired "Internet Unreachable" immediately, bypassing the 5 s flicker suppression | Internet-loss alerts fire only while WiFi stays connected |

Claims that could not be made true were reworded: "zero polling / zero battery impact / zero missed
events" became "negligible battery"; "zero network requests" became "collects no data; the only
request is an anonymous connectivity check to Apple"; and the stale "What's coming" roadmap was
removed. The same rewording is in jessemeria.com commit `7d69ec3` (privacy policy §9, landing page,
support, press kit, llms.txt and three blog posts). That commit is not deployed; deploy it with the
1.2.0 release.

**App Privacy answers stay "Data Not Collected".** The check sends no user data. It goes to Apple, not
to us or a partner, and nothing is retained by us.

## Description (replaces the live one)

macOS doesn't tell you when your WiFi disconnects. The icon goes from full bars to empty bars and hopes you notice. You find out minutes later when your video call freezes, your terminal hangs, or your upload fails.

SignalDrop fixes that. It's a lightweight Mac menu bar app that watches your WiFi and sends a macOS notification when your connection drops, your signal weakens, or your WiFi stays connected but the internet stops answering. When you're back, it tells you exactly how long you were offline.

WHAT IT DOES:

• Disconnect notifications as soon as a drop lasts longer than 5 seconds (adjustable), so 1-second roaming flickers don't spam you
• A "back online" notification with the exact downtime after every drop it alerts you to
• "Connected but no internet" detection: catches the network that shows full bars while your ISP is down or a captive portal is blocking you
• Signal-weakness warnings before your connection drops (–75 dBm threshold with hysteresis to avoid notification spam)
• Optional alerts when your Mac silently switches networks
• Connection quality grade (A through F) based on 24-hour stability
• Per-network reliability tracking with uptime percentages and disconnect counts
• Network Insights: nearby networks with vendor identification, a live signal and noise graph, and 24-hour, 7-day and 30-day connection history
• ISP-ready receipt: one-click copy of an outage timeline, or a one-page PDF report, to send to your ISP
• Event log with CSV export
• Per-event notification settings, quiet hours, and a test-notification button
• Launch at login: set it and forget it

HOW IT WORKS:

SignalDrop uses Apple's CoreWLAN framework, so macOS tells it the moment your WiFi changes instead of it constantly polling. To catch dead networks, it checks every 30 seconds that the internet actually answers, using the same tiny Apple connectivity check macOS itself uses. Battery impact is negligible.

PRIVACY:

SignalDrop collects no data. No analytics. No telemetry. No accounts. Its only network request is that anonymous connectivity check to Apple, which carries nothing about you or your networks. WiFi events are stored in a local database that you control. Your location (required by macOS for WiFi network names) is never recorded or transmitted.

## Promotional text (170 max; can be changed without review, so set it on release day)

Your Mac doesn't tell you when WiFi drops, or when the internet dies behind full bars. SignalDrop does, and tells you exactly how long you were offline.

## What's New in 1.2.0

SignalDrop now catches the outage your WiFi icon hides.

• Connected but no internet: when your WiFi shows full bars but your ISP is down or a captive portal is blocking you, SignalDrop now notices within about 30 seconds and alerts you. It uses the same tiny Apple connectivity check macOS itself uses, and nothing about you is sent.
• Back-online alerts with downtime: after any drop SignalDrop alerts you to, it now tells you when you're back and exactly how long you were offline.
• Fixed: the menu could say "Notifications disabled" even after you allowed notifications. It now updates as soon as permission changes.
• Fewer duplicate alerts: losing WiFi no longer triggers a separate "Internet unreachable" alert on top of the disconnect alert.

## Review notes addition

SignalDrop 1.2 adds one outbound request: an anonymous HTTPS GET to https://captive.apple.com/hotspot-detect.html (the endpoint macOS uses for captive-portal detection), which detects WiFi that is connected without internet access. It carries no user data. The privacy policy (§9) describes it.
