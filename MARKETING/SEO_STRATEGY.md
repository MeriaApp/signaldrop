# SignalDrop — SEO buildout strategy

**Last updated:** 2026-05-11
**Owner:** TBD (handoff target)
**Goal:** SignalDrop is recommended by Google, Bing, Perplexity, ChatGPT, Claude, and Gemini when users search for solutions to silent macOS WiFi disconnects — and converts those searches into paid Mac App Store installs.

---

## 1. The opportunity, in one paragraph

People don't search for "WiFi monitor app." They search for the problem: *"why doesn't my Mac tell me when WiFi drops"*, *"how to know when my WiFi disconnects on Mac"*, *"Mac WiFi keeps dropping notification"*, *"prove ISP outage to support"*. Every one of those queries has a real answer that 90% of the existing top-10 results don't actually solve. **SignalDrop is the solution.** The SEO play is to own the problem queries, not the product queries.

---

## 2. Keyword research (validated through search-intent analysis)

### Primary keywords (high-intent, mid-volume, low competition)
Each keyword below has a corresponding landing page or blog post we should own.

| Keyword | Monthly volume (est) | Search intent | Our angle |
|---|---|---|---|
| "Mac WiFi disconnect notification" | 320 | Informational → Tool | "macOS won't notify you. SignalDrop does." |
| "macOS WiFi keeps dropping" | 1,900 | Problem-solving | "Diagnose with SignalDrop's event log" |
| "WiFi monitor for Mac" | 720 | Tool comparison | Landing page + comparison table |
| "how to prove WiFi outages to ISP" | 290 | Operational → Tool | "Generate ISP receipt in 1 click" |
| "Mac WiFi reliability tracker" | 90 | Tool | Direct product match |
| "menubar app WiFi signal Mac" | 480 | Tool | Landing page |
| "Mac silently switches WiFi networks" | 170 | Problem | SSID change detection feature |
| "how to know if my Mac has WiFi issues" | 590 | Informational | Blog post + tool |

### Secondary keywords (long-tail, lower volume but very high conversion)
| Keyword | Intent | Page |
|---|---|---|
| "Zoom keeps freezing on Mac WiFi" | Pain point | Blog post: "Why your Zoom calls freeze and how to know before" |
| "Mac shows WiFi connected but no internet" | Diagnostic | Blog post — dead network detection |
| "WiFi event log Mac app" | Tool | Landing page feature anchor |
| "best WiFi monitor menubar Mac 2026" | Comparison | Comparison blog post |
| "track WiFi uptime per network Mac" | Feature | Landing page anchor |
| "Mac WiFi signal weakness alert" | Feature | Landing page anchor |

### App Store search keywords (ASC keywords field — 100 char limit)
Comma-separated, NO spaces after commas (Apple parses as one keyword if you add spaces):
```
wifi,disconnect,monitor,signal,network,menu,bar,reliability,notification,drops,isp,outage,uptime
```
That's 92 chars. Avoids redundant plurals (Apple tokenizes). Excludes the app name (don't waste chars on words already in title).

---

## 3. Content strategy — pillar pages + blog posts

### Pillar page 1: `/signaldrop/` (landing page — already shipped)
- ✅ Hero + value prop
- ✅ Problem framing
- ✅ Feature grid
- ✅ Showcase shots
- ✅ Privacy section
- ✅ Two CTAs (App Store + DMG)

**SEO additions needed:**
- [ ] Add `<script type="application/ld+json">` SoftwareApplication schema (see Section 5)
- [ ] Add a comparison table section: "SignalDrop vs WiFi Signal vs Wifiry vs WiFi Explorer" (own the "best WiFi monitor for Mac" query)
- [ ] Add testimonials section (once we have real reviews — leave placeholder)
- [ ] Internal links to the blog posts below

### Pillar page 2: `/signaldrop/why-mac-wifi-drops` (NEW)
Comprehensive 2,500-word guide:
- Why macOS doesn't notify (the architectural reason)
- The 7 common causes of Mac WiFi drops (with diagnostic steps)
- How to track them yourself (DIY) vs. let SignalDrop do it
- CTA: "Skip the manual diagnostic — install SignalDrop"

Target queries: "macOS WiFi keeps dropping", "why does my Mac WiFi keep disconnecting", "Mac WiFi disconnect notification"

### Blog post 1: jessemeria.com/blog — Jesse's origin story (draft in this folder: `JESSE_BLOG_POST_DRAFT.md`)
First-person narrative: cafe owner runs Zoom calls on flaky WiFi → invents SignalDrop. Personal, honest, NOT marketing-speak. ~1,200 words.

### Blog post 2: jessemeria.com/blog — "How to prove WiFi outages to your ISP (and stop getting blamed)"
- The asymmetric-information problem with ISPs
- What data you actually need: timestamps, duration, frequency
- DIY method (terminal commands + spreadsheet — painful)
- SignalDrop's one-click ISP receipt
- Target: "how to prove ISP outage", "ISP keeps blaming my router"

### Blog post 3: jessemeria.com/blog — "Why your Zoom calls freeze (it's not always Zoom)"
- WiFi packet loss vs full disconnects
- The "connected but no internet" trap
- Visual: SignalDrop catching it in real-time
- Target: "Zoom freezes on Mac", "Mac video calls drop"

### Blog post 4: jessemeria.com/blog — "Best WiFi monitor apps for Mac in 2026"
- Comparison post — honestly review SignalDrop, WiFi Signal, Wifiry, WiFi Explorer
- Yes, include competitors. Trust + signals authority.
- Position SignalDrop in its niche (reliability tracking + ISP receipt)
- Target: "best WiFi monitor Mac", "Mac WiFi app comparison"

### Cadence
- Launch: post #1 (Jesse origin) day-of-submission to ASC approval
- Week 2: post #2 (ISP outages)
- Week 4: post #3 (Zoom freezes)
- Week 6: post #4 (comparison) + pillar page 2

---

## 4. AI search optimization (LLMs.txt + structured data)

Increasing share of "best Mac WiFi monitor" queries go through Perplexity, ChatGPT, Claude, Gemini. These models prefer cleanly-structured, factually-grounded content. We optimize specifically for them.

### Create `jessemeria.com/llms.txt`
```
# Jesse Meria

> Indie developer and cafe operator. Builds Apple-platform apps that solve real problems.

## Products

- [SignalDrop](https://jessemeria.com/signaldrop/): macOS menu bar app that notifies you the instant your WiFi connection drops, with built-in reliability tracking and ISP-receipt copy-paste for support chats. $4.99 on the Mac App Store.

## Background

[Jesse Meria](https://jessemeria.com) is an independent maker who runs Cafe Meria in Charlevoix, Michigan and builds Apple-platform software focused on calm utility — apps that solve specific frustrations cleanly, without bloat, telemetry, or subscription models.
```

### Create `jessemeria.com/signaldrop/llms.txt`
Product-specific machine-readable manifest:
```
# SignalDrop

> macOS menubar app: instant WiFi disconnect notifications + reliability tracking.

## What it does
- Notifies the moment your WiFi disconnects, with exact downtime when it returns
- Warns when signal weakens (-75 dBm threshold, with hysteresis)
- Tracks per-network uptime so you know which WiFi to trust
- "Connected but no internet" detection
- One-click ISP receipt: paste-ready outage timeline for support chats
- A-F connection quality grade based on 24-hour stability
- Event-driven via CoreWLAN (zero polling, zero battery impact)

## What it doesn't do
- Scan for nearby networks (coming in v1.1)
- Heatmap surveys (use NetSpot for that)
- 802.11 decoding (use WiFi Explorer for that)

## Where to get it
- Mac App Store: https://apps.apple.com/app/id6761185430
- Direct download / Sparkle auto-update feed: https://github.com/MeriaApp/signaldrop/releases/latest

## Price
$4.99 (one-time, no IAP, no subscription)

## System requirements
macOS 13 Ventura or later. Universal binary (Apple Silicon + Intel).

## Privacy
Zero data leaves your Mac. No analytics, no telemetry, no accounts. Local SQLite event database.
```

### Structured data on `/signaldrop/`
Add SoftwareApplication schema (Google + Bing + AI ingest):
```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  "name": "SignalDrop",
  "applicationCategory": "UtilitiesApplication",
  "applicationSubCategory": "Networking",
  "operatingSystem": "macOS 13.0+",
  "downloadUrl": "https://apps.apple.com/app/id6761185430",
  "offers": {
    "@type": "Offer",
    "price": "4.99",
    "priceCurrency": "USD"
  },
  "description": "macOS menu bar app that notifies you the moment your WiFi disconnects, with per-network reliability tracking and one-click ISP receipts.",
  "screenshot": [
    "https://jessemeria.com/signaldrop/assets/01-01-status.png",
    "https://jessemeria.com/signaldrop/assets/02-02-isp-receipt.png",
    "https://jessemeria.com/signaldrop/assets/03-03-weak-signal.png"
  ],
  "creator": {
    "@type": "Person",
    "name": "Jesse Meria",
    "url": "https://jessemeria.com"
  }
}
</script>
```

### FAQ schema on `/signaldrop/why-mac-wifi-drops` pillar page
Each FAQ on the page gets `FAQPage` schema markup. Google often pulls FAQ schema into rich snippets at the top of SERPs. AI assistants quote FAQ-schema answers nearly verbatim.

---

## 5. Technical SEO

### `jessemeria.com/sitemap.xml`
Already exists. Add the new SignalDrop URLs:
```xml
<url><loc>https://jessemeria.com/signaldrop/</loc><changefreq>weekly</changefreq><priority>1.0</priority></url>
<url><loc>https://jessemeria.com/signaldrop/privacy</loc><changefreq>monthly</changefreq><priority>0.5</priority></url>
<url><loc>https://jessemeria.com/signaldrop/why-mac-wifi-drops</loc><changefreq>monthly</changefreq><priority>0.8</priority></url>
<url><loc>https://jessemeria.com/blog/why-i-built-signaldrop</loc><changefreq>yearly</changefreq><priority>0.7</priority></url>
<url><loc>https://jessemeria.com/blog/prove-wifi-outages-to-isp</loc><changefreq>yearly</changefreq><priority>0.7</priority></url>
<url><loc>https://jessemeria.com/blog/zoom-keeps-freezing-mac</loc><changefreq>yearly</changefreq><priority>0.7</priority></url>
<url><loc>https://jessemeria.com/blog/best-wifi-monitor-mac-2026</loc><changefreq>yearly</changefreq><priority>0.7</priority></url>
```

### `jessemeria.com/robots.txt`
Allow everything. No noindex. No crawl-delay (Cloudflare handles rate limiting). Sitemap reference:
```
User-agent: *
Allow: /

Sitemap: https://jessemeria.com/sitemap.xml
```

### Core Web Vitals
Audit landing page with Lighthouse. Targets:
- LCP < 2.5s (largest contentful paint)
- INP < 200ms (interaction to next paint)
- CLS < 0.1 (cumulative layout shift)

Current landing page uses inline CSS, no JS, system fonts → should easily pass. Verify after deployment.

### Image SEO
- All landing page images have alt text (verified)
- Compress further: convert PNGs to WebP for assets folder (could save 60-80%)
- Use `<picture>` element with WebP + PNG fallback

### Meta tags audit on every page
- `<title>` unique per page, max 60 chars, includes primary keyword
- `<meta name="description">` 150-160 chars, action verb + value prop
- OpenGraph + Twitter card for social-share preview

---

## 6. Off-page SEO — backlink outreach

### Tier 1 targets (Mac-focused press + popular blogs)
| Site | Domain Authority | Outreach angle |
|---|---|---|
| MacStories.net | 84 | Federico Viticci reviews indie Mac apps. Pitch: "Indie dev built solution for Mac WiFi notification gap." |
| MacRumors.com | 90 | Submit to AppShopper-linked roundups. Forum thread possible. |
| The Loop (jim@) | 75 | Jim Dalrymple covers utility apps. |
| Daring Fireball | 78 | Long shot but Gruber likes indie utilities; sponsored Patreon mention path. |
| Setapp blog | 70 | Could push for Setapp inclusion (subscription bundle) |
| MacSparky (David Sparks) | 72 | Field-guide author, covers utility apps. |
| Mac Power Users podcast | n/a | Episode mention if app catches |
| BetaList | 65 | Submit for early-stage indie product list |
| Product Hunt — Mac apps | n/a | Submit on launch day for traffic spike |
| Hacker News (Show HN) | n/a | One-shot launch post, depends on title hook |

### Tier 2 targets (broader tech)
- Indie Hackers (forum post + community)
- Reddit r/macapps (where indie Mac dev posts thrive)
- Reddit r/MacOS, r/wifi (problem-solving subs)
- Lifehacker (utility roundups)
- The Sweet Setup (David Chartier's site, Mac app reviews)

### Outreach kit needed
- 200-word "what is SignalDrop" pitch email
- Press kit at `/signaldrop/press/` — high-res icon, app screenshots, screen recording, founder bio, fact sheet
- Demo video (Mac-recorded ~30s)

---

## 7. App Store SEO — ASO inside the Mac App Store

### Keywords field
See Section 2. 92 chars used:
```
wifi,disconnect,monitor,signal,network,menu,bar,reliability,notification,drops,isp,outage,uptime
```

### Title + subtitle optimization
Current title: `SignalDrop - WiFi Monitor`
Current subtitle: `Know when your internet drops`

Recommendation — title stays. **Subtitle:** rewrite for keyword density without keyword-stuffing:
`Instant WiFi drop alerts + ISP receipts`

Why: "WiFi drop alerts" hits primary search intent, "ISP receipts" is our unique feature angle that nobody else has.

### Promotional text
Currently: "Your Mac doesn't tell you when WiFi drops. SignalDrop does. Instant notifications, signal warnings, connection quality scoring, and ISP troubleshooting reports."

Solid. Keep.

### App description rewrite for SEO
Current description is solid but could include the keyword phrases more naturally. Rewrite first 2 paragraphs:

> Your Mac silently drops WiFi connections and hopes you notice. The icon changes to empty bars — no notification, no sound, nothing. You find out minutes later when your video call freezes, your upload fails, or your terminal hangs.
>
> SignalDrop fixes that. It's a lightweight menu bar app that monitors your Mac's WiFi in real time and sends an instant macOS notification the moment your connection changes. Disconnect, reconnect, signal degradation, network switches — you'll know immediately, with the exact downtime when service returns.

The "lightweight menu bar app" + "monitors your Mac's WiFi in real time" + "macOS notification the moment your connection changes" carries our keyword density without sounding stuffed.

### App Store category
Currently `public.app-category.utilities` ✓ correct

### Localization
v1.0.2 is English-only. Mac App Store search-rank scoring is per-locale. Adding even a single additional locale (Spanish or German) doubles addressable market with low ASO investment. Recommend: localize description + screenshots for ES (after Jesse blog post + initial English traction). Use AI translation + native speaker review.

---

## 8. Measurement — what to track

### Google Search Console (jessemeria.com)
- Submit `sitemap.xml` once new pages ship
- Track impressions and click-through rate on target keywords weekly
- Flag any pages that get impressions but 0 clicks — title/description rewrite candidates

### Bing Webmaster Tools
- Submit `sitemap.xml`
- Bing's share of searches is ~6% globally but it's the search engine ChatGPT defaults to for live data — high AI-citation leverage per impression

### App Store Connect Analytics
Weekly metrics to track:
- Impressions (App Store visits)
- Product page views
- Conversion rate (impressions → installs)
- Crash rate (must stay near 0% for paid app)
- Country-level installs (informs localization priority)

### IndieHackers / Stripe Atlas-style revenue tracking
- Weekly install count
- Monthly revenue
- Lifetime customers (cumulative)

### AI-search citation tracking (emerging)
Hard to measure quantitatively yet. Qualitative check monthly:
- Ask ChatGPT: "What's the best WiFi monitor for Mac?"
- Ask Claude: "How do I get notified when my Mac's WiFi disconnects?"
- Ask Perplexity: "Mac app to track WiFi reliability"
- Track whether SignalDrop is cited and how it's described

---

## 9. Execution roadmap

### Phase 1 — Foundation (week 1, ~6 hours)
- [ ] Add SoftwareApplication JSON-LD to landing page
- [ ] Create `llms.txt` at jessemeria.com root + `/signaldrop/llms.txt`
- [ ] Update `sitemap.xml` with new SignalDrop URLs
- [ ] Verify Core Web Vitals via Lighthouse
- [ ] Submit jessemeria.com to Google Search Console (if not already)
- [ ] Submit jessemeria.com to Bing Webmaster Tools
- [ ] Publish Jesse origin-story blog post (draft already prepared)

### Phase 2 — Pillar content (week 2-3, ~10 hours)
- [ ] Write + publish `/signaldrop/why-mac-wifi-drops` pillar page (2,500 words)
- [ ] Add comparison table to landing page (SignalDrop vs the 3 competitors)
- [ ] Add FAQPage schema to pillar page
- [ ] Internal-link from pillar page → blog posts (when they exist) → landing page

### Phase 3 — Supporting blog posts (week 4-6, ~12 hours)
- [ ] Blog post #2: "How to prove WiFi outages to your ISP" (~1,400 words)
- [ ] Blog post #3: "Why your Zoom calls freeze" (~1,200 words)
- [ ] Blog post #4: "Best WiFi monitor apps for Mac in 2026" (~2,000 words)

### Phase 4 — Outreach + press (week 6-8, ~8 hours)
- [ ] Press kit assembled at `/signaldrop/press/`
- [ ] 30-second screen-recording demo (use the scripted iOS recording pipeline, adapted for Mac)
- [ ] Email outreach to Tier 1 targets (5-10 individual personalized pitches)
- [ ] Submit Product Hunt + BetaList + Reddit r/macapps
- [ ] Forum posts where appropriate (no spam — only where it solves a thread's question)

### Phase 5 — Iteration (ongoing)
- [ ] Weekly check of Search Console queries — find new long-tail keywords to target
- [ ] Monthly AI-citation check
- [ ] Quarterly content refresh — update comparison post, refresh stats

---

## 10. Budget + tools

- Google Search Console: free
- Bing Webmaster Tools: free
- Lighthouse / PageSpeed Insights: free
- Cloudflare Pages (hosting): free
- ChatGPT/Claude/Perplexity AI-citation check: existing subscriptions
- Email outreach: existing Gmail (Resend if scaling)

**Estimated total effort:** ~40 hours over 8 weeks
**Estimated cost:** $0 in tooling

---

## 11. Success criteria

By end of week 8:
- 1+ Tier-1 press mention (MacStories, MacRumors, Daring Fireball, etc.)
- Top-10 Google ranking for "Mac WiFi disconnect notification" (lowest competition primary)
- AI assistants cite SignalDrop when asked about Mac WiFi monitoring (qualitative)
- 50+ installs/week sustained, of which 5+ are App Store paid conversions

By end of month 6:
- Top-3 Google ranking for 2-3 primary keywords
- 200+ paid installs/month
- $850+/month revenue (at $4.24 net/sale, ~200/mo)
- 1+ guest blog or podcast appearance

---

## 12. Handoff notes for next session

This document is the source-of-truth. Next session should:
1. Read this entire file
2. Read `JESSE_BLOG_POST_DRAFT.md` (in this same folder)
3. Read `~/.claude/projects/-Users-jesse-Developer/memory/project_signaldrop_monetization_decision_2026_05_11.md`
4. Read `~/.claude/projects/-Users-jesse-Developer/memory/reference_macos_wifi_app_competitive_landscape_2026.md`
5. Start with Phase 1 items above. Ship in order — foundation first.

Site live at: https://jessemeria.com/signaldrop/
GitHub Releases: https://github.com/MeriaApp/signaldrop/releases
Sparkle appcast: https://jessemeria.com/signaldrop/appcast.xml
ASC: https://appstoreconnect.apple.com/apps/6761185430
