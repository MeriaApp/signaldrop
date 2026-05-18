# X / Twitter — SignalDrop 1.1 launch post

**Audience target:** Mac developers, remote workers, indie-Mac-app
followers, people who have ever complained about their ISP on the
timeline. Slight crossover with the indie-Mac/Swift/Apple-dev community.

**Posting hand:** @jessemeria

**Posting cadence:** Single launch post + 4 follow-on quote-replies
spaced through the week so the thread keeps surfacing without spam.
The launch post is the high-engagement one; the follow-ons are
feature-deep-dives that get fewer clicks but build the post into a
real thread.

---

## Post 1 — Launch (the headline hook)

```
my mac has dropped wifi on a zoom call hundreds of times.

never once notified me.

so i built signaldrop. menu bar app. notifies you the instant wifi
drops, tracks reliability per network, and exports a PDF receipt
you can hand to your ISP the next time they tell you their "line
test was clean."

v1.1 is live. $4.99. no subscription, no analytics, no telemetry.

https://apps.apple.com/app/id6761185430
```

**Char count:** ~470 (well under the 4000 X premium cap; under 280
for non-premium would need shortening — see Post 1b below).

**Why it works:** Specific user-frustration hook (Zoom + hundreds
of times). Concrete numerical claim ($4.99, no subscription). Single
clear CTA. App Store link as the last line for click-through.

---

## Post 1b — Sub-280 fallback for visibility

```
my mac has dropped wifi on zoom calls hundreds of times.

never once notified me.

so i built signaldrop — a $4.99 menu bar app that catches every drop, tracks reliability, and exports a PDF receipt for your ISP.

v1.1 is live.

https://apps.apple.com/app/id6761185430
```

**Char count:** 268. Safe for everyone.

---

## Post 2 — Reply, the receipt feature (24h after launch)

```
the killer feature is the PDF receipt.

reliability grade (A–F), every outage with timestamps, per-network
rollup. paste into your ISP support chat.

watch how fast the conversation shifts from "we have no record of
any outage" to "let me see what credit we can issue."
```

---

## Post 3 — Reply, the live signal graph (48h after launch)

```
v1.1 also added a live RSSI/Noise/TX-rate graph.

hover any point: exact dBm, noise floor, SNR, link rate at that
moment. apple stocks-grade scrubbing, but for your wifi.

[screenshot of signal graph]
```

(Attach: signaldrop/assets/01-01-status.png or a new signal-graph
screenshot once available.)

---

## Post 4 — Reply, the privacy stance (72h after launch)

```
signaldrop makes zero outbound network requests.

no analytics. no crash reporter that phones home. no account system.
no ad framework.

every event lands in a local SQLite database. you can export it,
delete it, ignore it. it never leaves the machine.

paid utility, no monetization-of-you tax.
```

---

## Post 5 — Reply, the indie-dev pitch (1 week after launch)

```
v1.1 added: nearby networks scanner with 38,000-entry IEEE OUI
vendor lookup, live signal graph, connection history with PDF
export, phantom-drop suppression, notification settings with quiet
hours, accessibility pass.

free update for everyone who bought 1.0.

this is what $4.99 indie utility math looks like.
```

---

## Image attachments (queue for use)

- App Store badge image — official Mac App Store download badge
- `signaldrop/assets/icon-1024.png` — app icon at 1024
- `signaldrop/assets/01-01-status.png` — menu bar live status
- `signaldrop/assets/04-04-event-log.png` — connection history view
- `signaldrop/assets/03-03-weak-signal.png` — weak-signal alert

Pair Post 1 with the **icon + a status screenshot** in a 2-image
carousel. Pair Post 2 with the **event-log screenshot**. Pair Post
3 with a signal-graph screenshot.

---

## Cross-post locations

After X goes well:
- **Hacker News Show HN** — only if Post 1 lands well; otherwise the
  HN cohort smells PR. Title: "Show HN: SignalDrop 1.1 — Mac menu bar
  WiFi notifier with ISP-ready PDF receipts ($4.99)"
- **r/macapps** subreddit — full post, link to blog + App Store
- **r/macsysadmin** — angle on the per-network reliability dashboard
  + accessibility pass
- **Indie Hackers** — short post linking the blog + App Store
- **Mastodon (fosstodon, mastodon.social)** — slightly different
  voice (indie/foss-friendly), emphasize zero-analytics stance
- **Threads** — recycle Post 1b
- **Bluesky** — recycle Post 1b
- **LinkedIn** — formal version: "Today I shipped SignalDrop 1.1.
  It's a small Mac menu bar app I've been building for the very
  specific problem of WiFi outages I can't prove to my ISP…"

---

## Engagement-handling protocol

- **DO** reply to every legit question or comparison-request in the
  first 24h. The X algorithm rewards thread reply velocity.
- **DO** quote-reply with feature breakdowns if anyone asks "but
  what does it do" — drive them to the blog.
- **DO NOT** engage with bad-faith "why would I pay for a free
  feature" comments. Single calm reply if it gets traction; otherwise
  ignore.
- **DO NOT** beg for retweets. The post earns or it doesn't.

---

## Publish checklist

- [ ] Open https://x.com/compose/post
- [ ] Paste Post 1 (or Post 1b)
- [ ] Attach icon + status screenshot
- [ ] Add @jessemeria mention is NOT needed (it's the author account)
- [ ] Schedule follow-on Posts 2-5 at +24h, +48h, +72h, +7d
- [ ] Cross-post to Mastodon/Bluesky/Threads same day
- [ ] r/macapps + r/macsysadmin: schedule for Tuesday morning
- [ ] HN Show HN: judgment call based on Post 1 engagement
