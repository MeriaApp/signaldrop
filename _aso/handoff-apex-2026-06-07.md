# APEX HANDOFF — Implement SignalDrop's ASO overhaul (autonomous, Mac App Store)

You are implementing an approved ASO overhaul for **SignalDrop - WiFi Monitor** (com.meria.signaldrop, App ID 6761185430), a LIVE **macOS** app (Utilities / Developer Tools), **$4.99 paid, 0 ratings**. Code: `~/Developer/signaldrop` (xcodeproj may live at `~/Developer/dropout/SignalDrop.xcodeproj` — locate it). Run with the **APEX / best-in-world protocol** (`~/.claude/playbooks/apex-protocol.md`). **AI is the QA, not Jesse.**

## Read first
1. `~/Developer/signaldrop/_aso/aso-proposal-2026-06-07.md` — the approved spec.
2. `~/.claude/playbooks/aso-best-practices-2026.md` — canonical ASO playbook.
3. `~/.claude/playbooks/asc-api-patterns.md` — ASC REST API (JWT; PATCH stages, does NOT auto-submit).
4. `~/.claude/rules/real-user-testing.md`, `verify-every-shipped-edit.md`, `asc-pre-submission-visual-audit.md`.

## ⚠️ THE BIGGER LEVER THAN ASO — model decision (Jesse-gated, DO NOT change pricing without explicit go)
A paid app with 0 ratings is the hardest ASO position: paid → few installs → weak download velocity (the dominant ranking signal) → and 0 ratings tanks conversion. Metadata tuning raises the ceiling but the model is the real lever.
- **Option A (RECOMMENDED for ranking + matches the portfolio — LabelSnob/Puana/Composed are all free-with-IAP):** free menu-bar monitor + Pro IAP (ISP outage receipts, A–F reliability grades, event logs). Boosts install velocity + ratings volume fast.
- **Option B:** stay paid $4.99, lean on a ratings prompt after a caught drop + earn honest early reviews (slower).
**Present this to Jesse and get an explicit decision. Do the model-INDEPENDENT work below NOW regardless; do NOT flip pricing or build the IAP/free-tier split until Jesse says go** (it affects existing $4.99 buyers + revenue).

## Approved metadata rewrite (model-independent — do now)
- **Name:** `SignalDrop - WiFi Monitor` (25/30) — KEEP.
- **Subtitle:** `Network uptime & outage alerts` (30/30) — was `Catch WiFi drops. Prove it.` (kills the `wifi` Name-dup; slogan already lives in the filled Promo Text + description).
- **Keywords (96/100):** `disconnect,signal,strength,internet,connection,menubar,drop,isp,latency,ping,speed,status,router`
- **De-dup audit:** `{signaldrop,wifi,monitor}`·`{network,uptime,outage,alerts}`·`{disconnect,signal,strength,internet,connection,menubar,drop,isp,latency,ping,speed,status,router}` — removes the `wifi` triple-dup + `monitor`/`network` dups. Verify exact strings + counts via ASC API before staging.
- **Phrases formed:** wifi disconnect · wifi signal · signal strength · wifi strength · internet drop · wifi drop · network connection · menubar monitor · internet speed · wifi speed · isp outage · wifi status · network status · wifi router · ping/latency monitor.

## Other approved levers (model-independent)
- **Ratings (0 today — critical):** wire `SKStoreReviewController.requestReview(in:)` (works on macOS) to fire right after a drop is caught + shown (the satisfaction moment) — caps 3/user/365d, never on a button tap, never incentivize. Target 4.5★+. Render/drive it to prove timing.
- **Screenshots:** currently 5 desktop (`status, isp-receipt, weak-signal, event-log, reliability`) — content-appropriate. Expand toward 8–10; **frame 1 = the strongest hook** (live drop → menu-bar alert, OR the A–F reliability grade); clean, high-contrast, real macOS UI + 3–7-word benefit captions. ⚠️ **PPO A/B testing does NOT exist for Mac apps** — get the screenshots right by design (benchmark the best Mac utility listings first), no test to fall back on.
- **Category:** test secondary `Developer Tools` → `Productivity` (Dev Tools is too narrow; the audience is anyone with flaky WiFi). Utilities primary stays.
- **Promotional Text:** already filled (the only portfolio app using it) — refresh on each release for freshness.
- **App preview (optional):** 1920×1080 screen-capture (WiFi drops → menu-bar alert → outage receipt) — Mac preview can lift a utility's conversion.
- **es-MX/localization:** low priority (niche Mac utility, small Mac App Store search).

## Gates + verification + honesty
- **PATCH stages only — do NOT POST the submission or push public metadata without Jesse's explicit go.** Promo text edits can go live without review but confirm first.
- Read-back every staged field via ASC API. Pre-submission visual audit. Render/inspect the ratings prompt yourself.
- Apex rubric: benchmark top WiFi/network Mac utilities; 8–12 checkable rows incl. ≥3 negatives ("no word duplicated across the 3 fields," "frame 1 is a real hook," "subtitle carries keywords not a slogan"). Loop until every row ≥4.
- Honesty floor: for a 0-rating paid Mac utility, metadata raises the ceiling but the model decision is the bigger lever — say so. No "guaranteed ranking" language. ASA can't run keyword tests on Mac the same way — note the limitation.
- Commit by name (no `git add -A`); push to the SignalDrop remote after verified batches.

Deliver to Jesse: the model recommendation + decision needed, staged metadata (read-back-verified), ratings prompt verified, screenshot plan, and the exact "say go to submit" list.
