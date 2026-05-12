# Fresh-session handoff — SignalDrop v1.1 polish, Round 1

**Paste this entire file as the first message of a new Claude Code session running in `/Users/jesse/Developer/dropout/`.**

---

## Context (read this first)

You're picking up a SignalDrop development session. The previous session shipped v1.1's full feature set: nearby network scanner, live signal graph with axis polish, connection history tab with 24h/7d/30d period selector, per-network reliability rollup, PDF "ISP-ready receipt" export, and a notification Settings window with per-event toggles + phantom-drop suppression (min disconnect duration) + quiet hours.

Then we ran an adversarial polish audit on the whole v1.1 surface. The audit found 24 gaps. The full doc — with exact file paths, code locations, and fix patterns — lives at:

**`/Users/jesse/Developer/dropout/audits/v1.1-polish-audit-2026-05-11.md`**

**Read that doc before touching code.** It's the spec for this session.

## What you're shipping in this session

The audit's **Tier 1 + 2.9 bundle** — 6 surgical fixes that turn "competent v1.1" into "best-in-class v1.1." This is the ROUND 1 set:

1. **State-driven menu bar icon** (audit §1.1) — `wifi` / `wifi.exclamationmark` / `wifi.slash` based on connection + internet state. File: `MenuBarController.swift` `renderStatus()`.
2. **Signal Graph Y-axis autoscale** (audit §1.2) — compute domain from actual data instead of fixed -100..-20. File: `NetworkInsightsView.swift` `SignalGraphPane`.
3. **OUI vendor lookup in Scanner** (audit §1.3) — turn `8c:e9:b6:...` into "Cisco Meraki" or whatever. Bundle ~500 top vendors as JSON in `Resources/`. New file `OUILookup.swift`.
4. **Menu cleanup** (audit §1.4) — remove duplicate Sound/Signal toggles (Settings is the source of truth), kill "Show Welcome…" menu item, drop the redundant "Generate ISP Report" export option. Target: ≤10 menu items.
5. **Hover tooltip on Signal Graph** (audit §1.5) — Swift Charts `.chartOverlay { proxy in ... }` showing exact RSSI/Noise/timestamp at cursor.
6. **Signal-degraded minimum duration** (audit §2.9) — same pattern as the disconnect threshold we already shipped. Adds `minSignalDegradedDurationSeconds` to `NotificationSettings`. Files: `WiFiMonitor.swift`, `NotificationSettings.swift`, `SettingsView.swift`.

The audit doc has exact code-location pointers and recommended implementations for each of these. Do not invent — follow the audit.

## What is NOT in scope for this session

- **No new features.** Polish only. If you find a 7th idea, surface it to Jesse before implementing.
- **No App Store submission.** v1.0.2 is `WAITING_FOR_REVIEW` in ASC right now. Strategy: cancel + replace with v1.1 once polish is done. Do not interact with ASC API in this session except to query state.
- **No marketing changes.** Landing page, blog, press outreach are all already shipped (see CONTEXT_STATE.md).
- **No tier-2 or tier-3 items beyond §2.9.** Those are Round 2/3 sessions.

## Hard rules (Meria Standard)

These auto-load from `~/.claude/CLAUDE.md` + `~/.claude/rules/`. Quick reminders:

- **Adversarial verification, not confirmation verification.** After every change: open the app, click the real buttons, capture screenshots, find 5 ways it can break. Build success ≠ feature works.
- **Banned language** without real-user test evidence: "best in class", "100% operational", "complete", "production-ready". Replace with "happy path verified, known edges X/Y".
- **Trace the mental model before editing.** Read the full code path. Never edit blind.
- **Real screenshots > agent reports.** Use the Read tool directly on filed screenshots (Opus 4.7 has high-res vision). Don't spawn Explore agents for screenshot reading unless parallel.
- **Stage files by name.** Never `git add -A`. The session has 6 untracked source files + 4 modified — stage explicitly.
- **Commits are autonomous on verified batches.** Push to `MeriaApp/dropout` is OK after the round is verified end-to-end.

## How to verify each change

The standard loop:
```bash
cd /Users/jesse/Developer/dropout
xcodegen generate                                          # only after adding new files
xcodebuild -project SignalDrop.xcodeproj -scheme SignalDrop \
  -configuration Debug -destination 'platform=macOS' build 2>&1 | tail -5
killall SignalDrop 2>/dev/null; sleep 1
open ~/Library/Developer/Xcode/DerivedData/SignalDrop-*/Build/Products/Debug/SignalDrop.app
```

For UI verification: SignalDrop is a menu bar app. The status item is at index 6 in the ControlCenter process menu bar. To trigger UI flows:

```bash
osascript <<'EOF'
tell application "System Events"
    tell process "ControlCenter"
        click menu bar item 6 of menu bar 1
    end tell
    delay 0.5
    tell process "SignalDrop"
        click menu item "Network Insights…" of menu 1 of menu bar item 1 of menu bar 1
    end tell
end tell
EOF
```

Tab switching: `⌘1` (Scanner), `⌘2` (Signal Graph), `⌘3` (Connection History). Export PDF: `⌘E` while History tab is focused. Settings: `⌘,`.

For window screenshots, position the window first then capture:
```bash
osascript -e 'tell application "System Events" to tell process "SignalDrop" to set position of window 1 to {200, 200}'
osascript -e 'tell application "System Events" to tell process "SignalDrop" to set size of window 1 to {1100, 900}'
screencapture -o -R 200,200,1100,900 /Users/jesse/Developer/dropout/test-artifacts/X.png
```

## Known gotchas the audit doc covers

These will save you 30 minutes each if you read them:

- **Two events.db locations.** Sandboxed Debug reads from `~/Library/Containers/com.meria.signaldrop/...` not `~/Library/Application Support/SignalDrop/`. Container is pre-seeded with 40 test events. If History tab shows empty, check you're looking at the right DB.
- **SwiftUI custom controls fail osascript hierarchy queries.** Use keyboard shortcuts or cliclick coordinates. AppleScript `click button "Export PDF…"` returns "not found." Use `⌘E` instead.
- **SourceKit diagnostics lag the compiler.** "Cannot find type X" warnings in the diagnostic panel are usually stale. If `xcodebuild` succeeds with no `error:` line, the code is fine.
- **xcodegen generate** is required after adding new source files. `.xcodeproj` is generated, not hand-maintained.
- **APPSTORE flag is on for Debug too.** To test Direct-only paths (Sparkle, WebhookService), use the `SignalDropDirect` scheme.

## Session start protocol

Run these in order at the start of the new session:

```bash
cd /Users/jesse/Developer/dropout
git status -sb
git log --oneline -5
ls -la audits/ prompts/ CONTEXT_STATE.md
```

Then read:
1. `CONTEXT_STATE.md` — what happened in the last session
2. `audits/v1.1-polish-audit-2026-05-11.md` — the full punch list (this is the spec)
3. `Sources/SignalDrop/MenuBarController.swift` (for §1.1, §1.4 work)
4. `Sources/SignalDrop/NetworkInsightsView.swift` (for §1.2, §1.5 work)

Then start with §1.1 (menu bar icon). It's the highest-impact single change and exercises the smallest amount of code.

## Expected output

By the end of the session:
- 6 audit items shipped + verified
- Build green
- Real-user walkthrough done: open menu (icon now reflects state), open Network Insights, switch through all 3 tabs (Y-axis autoscaled, hover tooltip works on signal graph, scanner shows vendor names next to BSSIDs), open Settings (signal-degraded threshold control present + working), test by toggling WiFi briefly to verify min-duration suppression and the new menubar icon transition
- Commit with explicit file staging
- Push to `MeriaApp/dropout` if Jesse confirms it's a verified batch
- Updated `CONTEXT_STATE.md` with a new dated session entry
- 2-5 new memory files capturing durable insights from this session

## Don't do

- Don't submit anything to ASC.
- Don't `git add -A`.
- Don't add features beyond the 6 in this list.
- Don't try to fix the SourceKit-vs-compiler discrepancy. That's a known macOS Xcode behavior.
- Don't restore the container event DB to empty. It's intentionally seeded with test data.
- Don't push to a non-Meria remote.

## Tier 2/3 items that come later (NOT this session)

For context only — these are queued for future sessions:
- §2.6 TX rate dual-axis or separate row
- §2.7 Outage drill-in detail sheet
- §2.10 Test notification button in Settings
- §2.11 Animated empty state on Scanner
- §2.12 Grade calculation tooltip
- §3.13–§3.21 final smoothing batch

After Round 1 ships, Jesse picks which Round 2 items to do.

---

## TL;DR for the fresh session

> Read `audits/v1.1-polish-audit-2026-05-11.md`. Execute Tier 1 (§1.1-§1.5) + §2.9. Six surgical fixes. Verify with real-user walkthrough. Commit + push. Update CONTEXT_STATE.md + memory.

Good luck.
