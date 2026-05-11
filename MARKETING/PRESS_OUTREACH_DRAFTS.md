# SignalDrop press outreach — Tier 1 drafts

**Status:** Drafts. NOT SENT. Send manually after reviewing each.
**From:** Jesse Meria <jrmeria@gmail.com>
**Reply-to:** jrmeria@gmail.com
**Date prepared:** 2026-05-11
**Linkable press kit:** https://jessemeria.com/signaldrop/press/

---

## Pre-flight checklist for every outreach

1. Wait until 1.0.2 is approved + live on the App Store (currently WAITING_FOR_REVIEW; 5-10 business days). Press will check the App Store before responding — a "not yet available" listing kills the conversation.
2. Personalize the first paragraph to a piece they recently wrote. Without that, the email reads as a press blast and gets archived. Spend the 60 seconds.
3. Don't BCC multiple targets. Send each one individually.
4. If they don't respond in 7 days, one follow-up is fine. Two is pushy. Three is desperate.

---

## #1 — MacStories (Federico Viticci, John Voorhees)

**Best contact:** John Voorhees handles most Mac app reviews. `john@macstories.net`.
**Why this fits:** MacStories has been writing about indie Mac utilities for years. John specifically covers menu bar apps and ISP-grade reliability tools. Their audience aligns precisely with SignalDrop's "everyday Mac user, productivity-focused" buyer.
**Recent piece to reference:** Whatever MacStories recently wrote about a menu bar utility (check macstories.net before sending; pick the most recent menu-bar-app coverage).

```
Subject: SignalDrop — the WiFi notification macOS forgot to build

Hi John,

Loved your recent piece on [SPECIFIC RECENT MACSTORIES MENU-BAR-APP COVERAGE — read 2-3 pieces and pick one, do not generic-praise the publication].

I've been an indie Mac developer for a while and just shipped SignalDrop to the Mac App Store: a menu bar app that notifies you the instant your WiFi disconnects. It's the thing macOS has never built natively.

The angle that might be MacStories-shaped: I built it because I was tired of arguing with my ISP about outages they didn't believe happened. The killer feature is a one-click "ISP receipt" that copies a paste-ready outage timeline to your clipboard — the data format that ends arguments with tier-1 support. Per-network reliability tracking with uptime grades is the second differentiator. No competitor in the $5-$10 tier does either.

Technically it's event-driven CoreWLAN (zero polling), NWPathMonitor for "WiFi up but no internet" detection, fully sandboxed for the Mac App Store, no analytics, no subscription. $4.99 one-time.

Mac App Store: https://apps.apple.com/app/id6761185430
Press kit (assets + fact sheet + quotable lines): https://jessemeria.com/signaldrop/press/
Origin story: https://jessemeria.com/blog/why-i-built-signaldrop

Happy to send a promo code, hop on a quick call, or answer technical questions. No pressure either way — just thought it might be worth a look.

Thanks,
Jesse Meria
Cafe Meria · Charlevoix, MI
```

---

## #2 — MacRumors (Tim Hardwick, Juli Clover, Mitchel Broussard)

**Best contact:** Tim Hardwick covers Mac apps regularly. `tim@macrumors.com`. Juli Clover for iOS/iPad-focused pieces, but Tim is the right MR contact for a Mac utility.
**Why this fits:** MR has enormous reach. Their Mac-app roundups regularly include indie utilities. The "WiFi" beat is unowned over there.
**Recent piece to reference:** MacRumors Roundups + their "Mac apps you should be using" type coverage.

```
Subject: SignalDrop — instant WiFi disconnect notifications for Mac (new on App Store)

Hi Tim,

[OPENER REFERENCING TIM'S RECENT MAC-APP COVERAGE — even a one-sentence reference is enough; the goal is to prove you read the publication.]

Quick pitch: just shipped SignalDrop, a Mac menu bar app that finally adds WiFi-disconnect notifications to macOS. Apple has never built this natively — the WiFi icon just changes to empty bars and hopes you notice. SignalDrop fixes it.

The feature that's unique vs every other Mac WiFi tool: per-network reliability tracking (uptime % per SSID over time) plus a one-click "ISP receipt" that generates a paste-ready outage timeline for support chats. Designed to defeat the "we ran a line test, everything looks fine" deflection. WiFi Explorer, Wifiry, WiFi Signal — none of them do either.

Specs:
- macOS 13 Ventura+, universal binary (Apple Silicon + Intel)
- $4.99 one-time, no IAP, no subscription
- Fully sandboxed, zero analytics, zero outbound network requests
- Event-driven CoreWLAN (no polling, no battery impact)

Mac App Store: https://apps.apple.com/app/id6761185430
Press kit: https://jessemeria.com/signaldrop/press/

Happy to send a promo code if it's something you'd cover. Thanks for considering.

Best,
Jesse Meria
```

---

## #3 — Daring Fireball (John Gruber)

**Best contact:** `daringfireball@gruber.com` (his linked address). Gruber rarely covers individual indie apps unless there's a hook beyond "new app."
**Why this fits:** Long shot, but if it lands, single biggest traffic driver for a Mac indie utility. The hook to use: privacy-first architecture + Apple's missing feature.
**Recent piece to reference:** Whatever Gruber recently linked to. He links to a few things daily; pick something Mac-utility-adjacent.

```
Subject: SignalDrop — what macOS should have done for WiFi all along

John,

Linkable, maybe not "Star" worthy, but possibly Linked-List shaped.

SignalDrop ($4.99 on the Mac App Store, just shipped 1.0.2): a menu bar app that notifies you when your WiFi drops. The thing macOS has never built natively. The WiFi icon goes from full bars to empty bars and you're supposed to notice on your own.

What's interesting about it isn't the disconnect alert though — that's table stakes. The pitch is that it uses NWPathMonitor + CoreWLAN together to distinguish "WiFi connection lost" from "WiFi up, internet unreachable." The latter is where most ISP arguments live, and it generates a one-click paste-ready receipt to send to ISP support: timestamps, durations, connection grade. The receipt format is designed to defeat tier-1's "we ran a line test, looks fine" script.

Privacy-first by architecture: zero outbound requests, no analytics, sandboxed, $4.99 one-time, no subscription. Indie developer in Charlevoix, Michigan — built it for myself, polished it for the Store.

Mac App Store: https://apps.apple.com/app/id6761185430
Press kit if you want assets: https://jessemeria.com/signaldrop/press/

No expectation. Thanks for reading.

— Jesse
```

---

## #4 — The Loop (Jim Dalrymple)

**Best contact:** `jim@loopinsight.com`
**Why this fits:** Jim covers indie Mac utilities consistently. Simpler, more direct style fits his preference.
**Recent piece to reference:** Pick a recent Loop post.

```
Subject: New on the Mac App Store — SignalDrop, the WiFi disconnect notification macOS forgot

Hi Jim,

Big fan of The Loop's long-running indie Mac coverage.

Just shipped SignalDrop to the Mac App Store. It's a menu bar app that finally adds WiFi disconnect notifications to macOS — the OS has never had this natively. Plus per-network reliability tracking and one-click ISP outage receipts. $4.99, no subscription, no analytics.

Built it because I run a cafe and got tired of arguing with my ISP about outages I couldn't prove. Sandboxed, universal binary, macOS 13+.

Store: https://apps.apple.com/app/id6761185430
Press kit: https://jessemeria.com/signaldrop/press/

Happy to send a promo code if you'd like to take a look. Thanks.

Best,
Jesse Meria
```

---

## #5 — Mac Power Users (David Sparks)

**Best contact:** `david@macsparky.com` (via macsparky.com)
**Why this fits:** David covers power-user Mac apps for productivity people. Has a podcast (Mac Power Users with Stephen Hackett) and a newsletter. SignalDrop fits both formats.
**Recent piece to reference:** Recent MacSparky Field Guide content or newsletter mention.

```
Subject: SignalDrop — a menu bar tool for Mac users who run their work life on WiFi

David,

I've been a long-time MacSparky reader. The Field Guides got me through Shortcuts and Keyboard Maestro.

Quick note: just shipped SignalDrop on the Mac App Store. It's aimed at power users who run remote work, calls, or production work from their Mac and have lived through the "Zoom froze, my WiFi died, now I have to apologize on camera" situation. SignalDrop catches the drops instantly and tracks per-network reliability over time so you actually know which WiFi to trust.

The killer feature for power users specifically: a one-click ISP receipt that generates paste-ready outage data for support chats. The kind of thing where you've been frustrated for years and now you have leverage in the conversation.

Sandboxed, $4.99 one-time, no telemetry, macOS 13+.

Mac App Store: https://apps.apple.com/app/id6761185430
Press kit: https://jessemeria.com/signaldrop/press/

If it fits a future Field Guide or newsletter, I'm happy to send a code, hop on a call, or answer technical questions. No pressure.

Best,
Jesse Meria
```

---

## #6 — Setapp (inclusion request)

**Best contact:** `business@setapp.com` or via the partner application form at setapp.com/partners
**Why this fits:** Setapp is a subscription bundle of Mac apps ($9.99/month for ~250 apps). Getting SignalDrop included generates recurring revenue and a steady install base without per-customer support. The cost: Setapp takes a per-use revenue share, but it's additive (doesn't cannibalize App Store sales).
**Format:** Setapp has a formal application process; the email below is a soft intro before the application.

```
Subject: SignalDrop — Mac WiFi monitor, Setapp inclusion inquiry

Hi Setapp partnership team,

I just shipped SignalDrop to the Mac App Store and would like to be considered for Setapp inclusion.

What it is: a Mac menu bar app that adds the WiFi-disconnect notification macOS has never had natively. Plus per-network reliability tracking with uptime grades, signal-weakness warnings, and a one-click "ISP receipt" that generates paste-ready outage data for support chats.

Why it fits Setapp: it sits squarely in the "everyday Mac utility for remote workers and productivity-focused users" category that Setapp anchors. Setapp users specifically tend to live on their Macs and run video calls daily — exactly SignalDrop's target audience. The privacy story (no telemetry, no analytics, no subscription) aligns with Setapp's curation principles.

Specs:
- Mac App Store: https://apps.apple.com/app/id6761185430
- Press kit + screenshots: https://jessemeria.com/signaldrop/press/
- Standalone price: $4.99 one-time

Happy to provide a Setapp-specific build (unsandboxed if needed for any feature-parity discussion), free promo codes for your editorial team, and any other materials you'd need to evaluate.

Looking forward to hearing from you.

Best,
Jesse Meria
Independent Mac developer · Charlevoix, MI
```

---

## #7 — Indie Hackers post (community, not press)

**Best venue:** indiehackers.com → post in "Sharing Wins" or "Developers" with appropriate flair.
**Why this fits:** IH audience is fellow indie devs. They appreciate transparency about pricing decisions, technical architecture, and revenue. SignalDrop has a real story worth sharing: competitive analysis, pricing-tier reasoning, the $19.99 vs $4.99 decision, monetization recovery (the app shipped free as an oversight). All of that is IH-shaped content.

```
Title: Shipped my Mac WiFi monitor at $4.99 after almost defaulting to free

Body:

Hey IH,

Quick share. I shipped SignalDrop, a Mac menu bar app that adds WiFi-disconnect notifications to macOS. The post-mortem worth sharing is the pricing decision.

I almost shipped it free. The 1.0.1 launch went out with $0 set in App Store Connect because I'd been so focused on getting through Apple's rejection-and-resubmit cycle that I never circled back to set a price. Two source-of-truth docs in my repo specified $3.99 and $4.99 respectively. The Store shipped $0 because nobody set the price tier.

After realizing this for v1.0.2, I did a competitive audit of the four direct competitors (WiFi Signal $4.99, Wifiry $9.99, WiFi Explorer $19.99, NetSpot freemium $45/$149 IAP). Settled on $4.99 with a public roadmap to bump pricing as features land (v1.1 nearby network scanner + signal graphs → $7.99; v1.5 customizable menu bar + AP vendor IDs → $9.99).

Why $4.99 over $19.99 when WiFi Explorer commands that price:
- Different positioning. WiFi Explorer is a diagnostic tool for network engineers. SignalDrop is an always-running reliability monitor for everyday users. Same category, different jobs.
- The unique features (per-network uptime tracking, one-click ISP outage receipts) are valuable but not "$15 more valuable than WiFi Signal" valuable.
- Better to ratchet pricing up with features than ship at $19.99 with reviews that punish "less features than the $19.99 reference."

Why not freemium with IAP:
- Adds StoreKit complexity for what's a single-feature app.
- NetSpot's freemium model is universally panned in reviews ("bait and switch"). I didn't want that brand association.

Why no subscription:
- Subscriptions feel icky for tools with no ongoing server cost. SignalDrop runs entirely on-device.

Apple Small Business Program is on my todo list — at $4.99 it'd take me from $3.50 net per sale to $4.24 net. Eligibility cap is $1M/year aggregate; I'm nowhere close, so it's just paperwork.

Mac App Store: https://apps.apple.com/app/id6761185430
Press kit + tech details: https://jessemeria.com/signaldrop/press/

Happy to share more on the technical architecture (event-driven CoreWLAN, Sparkle for the developer-distributed build only, dual-target xcodegen setup, etc.) if anyone's curious.
```

---

## #8 — Reddit r/macapps post

**Best venue:** reddit.com/r/macapps with [Showcase] or [Release] flair.
**Why this fits:** Real-time community of Mac app users + indie devs. Lower-effort lift than press email, higher impressions if it lands.
**Rules to follow:** r/macapps requires devs to disclose they're the dev. Don't sock-puppet — disclose openly.

```
Title: [Release] SignalDrop 1.0.2 — finally a Mac WiFi-disconnect notification ($4.99)

Body:

Hey r/macapps. Indie dev here, disclosing up front. Just shipped SignalDrop to the Mac App Store.

What it does: macOS has never had a native WiFi-disconnect notification — the menu-bar WiFi icon just changes to empty bars and you're supposed to notice. SignalDrop adds the missing notification. Plus:
- Per-network reliability tracking (uptime % per SSID over time)
- "Connected but no internet" detection via NWPathMonitor
- Signal-weakness warnings before the connection dies
- One-click ISP outage receipt for support chats (paste-ready format)
- Connection quality A-F grade based on rolling 24-hour stability

How it works under the hood: event-driven CoreWLAN (zero polling — the OS pushes events to the app the instant something changes), NWPathMonitor for reachability, SQLite event log on disk, no outbound network requests, no analytics, no subscription. Fully sandboxed for the Mac App Store path.

Pricing: $4.99 one-time. No IAP. No subscription. All future 1.x updates included.

Mac App Store: https://apps.apple.com/app/id6761185430
Source for the SEO content: https://jessemeria.com/signaldrop/ (landing page) and https://jessemeria.com/signaldrop/why-mac-wifi-drops (full diagnostic guide)

Happy to answer technical questions, share architecture decisions, or send promo codes to a handful of folks who want to try it before buying.
```

---

## #9 — Product Hunt launch (day-of-launch traffic spike)

**Timing:** Launch on a Tuesday or Wednesday between 12:01 AM and 7 AM Pacific. Avoid Mondays (low traffic) and Fridays (lower traffic). Avoid US holidays.
**Format:** Submit via producthunt.com/posts/new — title + tagline + description + comment first.

Title:
```
SignalDrop — Mac menu bar app that catches WiFi drops in real time
```

Tagline (60 char max):
```
Instant WiFi disconnect alerts + ISP-ready outage receipts
```

Description:
```
macOS has never built a WiFi-disconnect notification. The WiFi icon just goes from full bars to empty bars and hopes you notice. SignalDrop is the missing notification — plus per-network reliability tracking, signal-weakness warnings, "connected but no internet" detection, and one-click ISP outage receipts you can paste straight into support chats.

Built by an indie developer who got tired of arguing with his ISP about outages he couldn't prove.

$4.99 one-time. No IAP. No subscription. No analytics. macOS 13+, Apple Silicon + Intel.
```

First comment (Hunter posts this immediately after launch — drives early upvotes via algorithm boost):
```
Hey PH 👋

Solo dev here. SignalDrop came out of a year of getting brushed off by my ISP about WiFi outages they didn't believe happened. The killer feature, the one I actually built it for, is a one-click ISP receipt — copies a paste-ready outage timeline to your clipboard that defeats the standard "we ran a line test, everything looks fine" response.

Happy to answer questions about:
- Why $4.99 (and why not free or $19.99)
- Event-driven CoreWLAN architecture (zero polling, zero battery)
- Privacy by design (zero outbound network requests, no analytics)
- The 1.0.2 roadmap (scanner + signal graphs in v1.1)

Promo codes available for the first 20 PH'ers who want to try before buying.
```

---

## #10 — Hacker News "Show HN"

**Timing:** Tuesday-Thursday, between 6 AM and 9 AM Pacific.
**Title:** Show HN posts must start with "Show HN:" exactly. Tagline brevity matters — front-page survival depends on the title hook.

Title options (test which lands):
```
Show HN: SignalDrop – macOS WiFi disconnect notifier with ISP outage receipts
```
OR
```
Show HN: I built the Mac WiFi notification Apple forgot for 27 years
```

First comment:
```
Author here. Built this because I was tired of arguing with my ISP about WiFi outages they didn't believe happened. The killer feature is a one-click ISP receipt that generates a paste-ready timeline — defeats the standard "we ran a line test, everything looks fine" tier-1 deflection.

Some technical bits HN might care about:

- Event-driven CoreWLAN via CWEventDelegate.linkDidChange / ssidDidChange / linkQualityDidChange. Zero polling means zero battery impact between events.
- NWPathMonitor cross-check to distinguish "WiFi disconnected" from "WiFi up, internet unreachable" — most other Mac WiFi tools don't catch the latter.
- Discovered during development that CoreWLAN delegates stop firing across sleep/wake. The 1.0.2 release adds a self-heal that re-registers the event subscriptions on NSWorkspace.didWakeNotification, plus a 30s polling fallback so the menu can't go stale silently.
- Dual-target xcodegen setup: one target for Mac App Store (sandboxed, no Sparkle), one for Direct Distribution (unsandboxed, Sparkle wired in). Discovered the hard way that just stripping Sparkle from a sandboxed-target bundle leaves dangling LC_LOAD_DYLIB entries that prevent dyld from launching the binary. Had to split into actual separate targets.
- $4.99 on the Mac App Store. No IAP, no subscription, no analytics, no outbound requests. The privacy-by-architecture story.

Mac App Store: https://apps.apple.com/app/id6761185430
Source for the SEO content + the writeup of every WiFi failure mode I've categorized: https://jessemeria.com/signaldrop/why-mac-wifi-drops/

Happy to answer technical questions.
```

---

## Tracking template

Copy this into a memory file or note as you send each one:

| # | Target | Sent date | Response | Outcome |
|---|---|---|---|---|
| 1 | MacStories (John Voorhees) | — | — | — |
| 2 | MacRumors (Tim Hardwick) | — | — | — |
| 3 | Daring Fireball (Gruber) | — | — | — |
| 4 | The Loop (Jim Dalrymple) | — | — | — |
| 5 | MacSparky (David Sparks) | — | — | — |
| 6 | Setapp (partnerships) | — | — | — |
| 7 | Indie Hackers post | — | — | — |
| 8 | Reddit r/macapps | — | — | — |
| 9 | Product Hunt | — | — | — |
| 10 | Show HN | — | — | — |

---

## Don't-do list

- Don't send these out before the App Store listing is live at 1.0.2.
- Don't BCC multiple at once. Send individually.
- Don't send to more than 2-3 per day; you want to be able to respond personally if multiple respond fast.
- Don't follow up more than once per target. Two is annoying. Three is desperate.
- Don't include your wife/family details, location specifics, or anything Jesse wouldn't put in front of strangers reading press in public.
- Don't claim "best" or superlatives that can be disproven. "Apple has never had a native WiFi-disconnect notification" is verifiable. "The best Mac WiFi monitor" is not.
- Don't mention competitor brands negatively. Reference them by capability, not by snark.
