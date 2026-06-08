# SignalDrop — ASO Proposal (2026-06-07)

**Mac App Store** utility (Utilities / Developer Tools), **$4.99 paid, 0 ratings**. Goal: rank for *wifi monitor, network monitor, wifi signal, internet drops, isp outage* and fix the cold-start. Grounded in `~/.claude/playbooks/aso-best-practices-2026.md`. **Proposals only.**

> ⚠️ **PPO (Product Page Optimization A/B testing) is iOS/iPadOS only — NOT available for Mac apps.** So SignalDrop's screenshots/icon can't be A/B-tested; they must be right by design.

## Current state (v1.1.0 live) — audit
| Field | Current | Chars | Verdict |
|---|---|---|---|
| **Name** | `SignalDrop - WiFi Monitor` | 25/30 | Good: brand + `wifi monitor` head term. |
| **Subtitle** | `Catch WiFi drops. Prove it.` | 27/30 | `wifi` **duplicates the Name**; mostly slogan. |
| **Keywords** | `wifi,disconnect,monitor,signal,network,menu,bar,reliability,notification,drops,isp,outage,uptime` | 96/100 | `wifi` (triple-dup: name+sub+kw) and `monitor` (dup with name) waste space. |
| **Promotional Text** | filled (143) | 143/170 | ✅ Only app in the portfolio using it. |
| **Description** | strong | 2199/4000 | ✅ |
| **Screenshots** | 5 desktop (`status, isp-receipt, weak-signal, event-log, reliability`) | — | Content-appropriate. Use more frames (up to 10); ensure frame 1 = the strongest hook (the menu-bar drop alert or the A–F grade). |
| **Category** | Utilities / Developer Tools | — | Utilities correct. **Developer Tools secondary is too narrow** — the audience is anyone with flaky WiFi. Test Productivity. |
| **Ratings** | **0 ratings, paid $4.99** | — | ❌ **The #1 problem** (see below). |

## 🔴 The cold-start problem (business-model flag for Jesse)
A **paid app with 0 ratings** is the hardest ASO position: paid → far fewer installs → weak download velocity (the dominant ranking signal) → and 0 ratings tanks conversion. ASO tuning helps, but the structural lever is the model. **Jesse's call:**
- **Option A — add a free trial / freemium** (free menu-bar monitor, Pro IAP for ISP receipts / A–F grades / logs). Boosts install velocity + ratings volume dramatically. *Recommended for ranking.*
- **Option B — stay paid**, lean hard on `requestReview` after a value moment (a drop caught) + earn honest early reviews. Slower.

## Metadata rewrite — RECOMMENDED
| Field | → Proposed | Chars |
|---|---|---|
| **Name** | `SignalDrop - WiFi Monitor` *(keep)* | 25/30 |
| **Subtitle** | `Network uptime & outage alerts` | 30/30 |
| **Keywords** | `disconnect,signal,strength,internet,connection,menubar,drop,isp,latency,ping,speed,status,router` | 96/100 |

- **Subtitle** kills the `wifi` dup and adds `network, uptime, outage, alerts` (the slogan lives in Promo + description).
- **Keywords** drop the `wifi`/`monitor`/`network` dups; add high-intent atoms.
- **De-dup:** `{signaldrop,wifi,monitor}`·`{network,uptime,outage,alerts}`·`{disconnect,signal,strength,internet,connection,menubar,drop,isp,latency,ping,speed,status,router}` → no repeats. ✅
- **Phrases:** wifi disconnect · wifi signal · signal strength · wifi strength · internet drop · wifi drop · network connection · menubar monitor · internet speed · wifi speed · isp outage · wifi status · network status · wifi router · ping/latency monitor.

## Other levers
- **Screenshots:** expand toward 8–10 frames; frame 1 = the killer hook (live drop → instant alert, or the A–F reliability grade); clean, high-contrast, real macOS UI + 3–7-word benefit captions. (No PPO on Mac — get it right first time.)
- **Ratings:** `requestReview` (or Mac equivalent `SKStoreReviewController`) after a drop is caught and shown — the satisfaction moment. Respond to reviews. Never incentivize.
- **App preview (optional):** 1920×1080 screen-capture: WiFi drops → menu-bar alert fires → outage receipt. Mac preview can lift a utility's conversion.
- **Category:** test secondary Developer Tools → Productivity for broader browse reach.
- **Promotional Text:** already good; refresh on each release for freshness.
- **es-MX / localization:** low priority (niche Mac utility, small Mac App Store search volume).

## Priority
P0: subtitle+keywords rewrite (kill the `wifi` triple-dup); **decide the paid-vs-freemium model (Jesse)**; wire the ratings prompt. P1: expand + sharpen screenshots (frame 1 hook); secondary category test. P2: app preview, promo refresh.

**Honesty floor:** for a 0-rating paid Mac utility, metadata tuning raises the ceiling but the model decision (Option A vs B) is the bigger lever. No "guaranteed ranking" claims.
