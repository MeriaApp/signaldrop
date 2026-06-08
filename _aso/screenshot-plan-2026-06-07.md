# SignalDrop — Screenshot Plan (2026-06-07)

**Constraint:** PPO A/B testing does **not** exist for Mac apps — screenshots must be right by design. Screenshots are version-bound, so any change rides the **1.2.0** binary (same one carrying the metadata + ratings prompt).

## Category benchmark (what the best Mac WiFi utilities do)
Leading apps lead their listing with their **signature visual**: NetSpot → the heatmap; WiFi Explorer → the spectrum/signal graph; iStat Menus / menu-bar monitors → the at-a-glance menu readout. **Crucially, none of the analyzers alert you when WiFi drops or hand you an ISP receipt** — that is SignalDrop's unique wedge. So SignalDrop's frame 1 should lead with the thing competitors *can't* show: a drop being caught the instant it happens.
Sources: [Setapp — best WiFi analyzers](https://setapp.com/how-to/best-wifi-analyzer-for-mac) · [NetSpot — best WiFi analyzers Mac 2026](https://www.netspotapp.com/wifi-analyzer/best-wifi-analyzer-mac.html) · [MoniThor — best Mac menu bar apps 2026](https://monithor.dev/guides/best-mac-menu-bar-apps) · [PeakHour — monitor network congestion macOS](https://peakhourapp.com/insights/top-tools-to-monitor-network-congestion-on-macos)

## Current 5 live frames (inspected 2026-06-07 — all 2880×1800, clean, high-contrast, consistent)
| # live | Headline | Shows | Verdict |
|---|---|---|---|
| 1 | Never Miss a WiFi Drop Again | status panel + "WiFi Disconnected" toast + 2m14s downtime | ✅ strong hook — keep as #1 |
| 2 | Know Before You Drop | weak-signal (-76 dBm), B-, "Signal Weak" toast | good |
| 3 | Connection Quality Score | big **B+** grade + reliability stats | ✅ most visually arresting — under-used at #3 |
| 4 | ISP Troubleshooting Report | outage timeline + daily breakdown | ✅ unique "proof" wedge — credible |
| 5 | Dead Network Detection | connected-but-no-internet + toast | good |

**Honest assessment:** this is an **above-average Mac-utility set already** — consistent design system, benefit-caption headlines (3–5 word bold + one-line sub), high contrast, and frame 1 already leads with the killer hook. This is not a regression like Puana's. The lift here is ordering + a few additions, not a rescue.

## Recommended reorder (front-load the two strongest hooks)
**1 → 3 → 4 → 2 → 5**, i.e.:
1. **Never Miss a WiFi Drop Again** (drop caught + alert) — the promise, the wedge.
2. **Connection Quality Score — B+** (was #3) — the most instantly-graspable visual; a bold grade reads in 0.5s and differentiates from every analyzer.
3. **ISP Troubleshooting Report** (was #4) — the "prove it" receipt; SignalDrop's moat.
4. **Know Before You Drop** (weak-signal warning).
5. **Dead Network Detection**.

This is a metadata-only reorder of existing assets (no new art), executed at 1.2.0 upload via `Scripts/asc/upload_screenshots.py` (order = upload order).

## Additions to reach 8–10 frames (produce against the LIVE design generation, ride 1.2.0)
Add 3–4 frames, each a real app surface with a 3–7-word benefit caption:
- **Copy Receipt for Support** — "One click. A receipt your ISP can't argue with." (the differentiator; pairs with the ISP-report frame)
- **Event log + CSV export** — "Every drop, logged and exportable."
- **Lives in your menu bar** — "Always watching. Out of your way." (the real menu-bar dropdown)
- **100% on-device** — "Zero tracking. No data leaves your Mac." (privacy is a real buy-trigger for a network tool)

⚠️ **Tooling drift to fix first:** `compose_screenshots.py` + `upload_screenshots.py` reference an OLDER headline set/filenames (`01-status`, `02-isp-receipt`, …) that do **not** match the live frames ("Never Miss a WiFi Drop Again", etc.). Before regenerating, reconcile the compose script with the live generation so new frames match the shipped design.

## Model-dependent note
If Jesse picks **Option A (freemium)**, label the Pro-only frames (ISP receipt, A–F grade, event log) subtly so the free→Pro story is legible. If **Option B (stay paid)**, no labels needed.

## App preview (optional, P2)
1920×1080 screen-capture: real WiFi drop → menu-bar alert fires → Copy Receipt. A Mac preview can lift a utility's conversion. Capturable with `xcrun simctl`-style screen recording of the real app on this Mac. Defer to post-1.2.0.
