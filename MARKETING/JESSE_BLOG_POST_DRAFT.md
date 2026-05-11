# Why I built SignalDrop

**Draft date:** 2026-05-11
**Target publication:** jessemeria.com/blog/why-i-built-signaldrop
**Voice:** Jesse, first-person. Honest. No marketing-speak.
**Length:** ~1,200 words
**Pre-publish:** Jesse to read top-to-bottom and edit anything that doesn't sound like him.

---

I run a cafe in Charlevoix, Michigan called Cafe Meria. I also run a few software projects from a desk in the same building. On a normal day, I'll be in the middle of a Zoom call with a customer or partner, or pushing a deploy to production, and the cafe WiFi will just… stop working. No notification. No alert. No popup. Just a slow realization that the audio cut out three minutes ago and nobody on the other end has heard a word I've said.

The Mac's WiFi icon, in case you've never noticed, doesn't tell you when your connection drops. It just goes from full bars to empty bars. There's no sound. There's no banner. The OS has decided that whether or not you have internet is a thing you can figure out for yourself by squinting at a tiny icon in the corner of your screen.

I should be charitable here. WiFi is genuinely fragile. Modern Macs handle network handoffs and reconnection logic in ways that mostly work, most of the time. You're supposed to not notice when something fails because the system papers over the failure. And in fairness — most of the time, it does.

But "most of the time" is doing a lot of work in that sentence. When the WiFi does fail in a way the system can't paper over, the experience is brutal. You're on a video call. The other person stops talking. You ask if they can hear you. Silence. You start typing in the chat. The chat doesn't send. You realize the WiFi has been down for ninety seconds. You frantically Cmd+Tab to find the WiFi menu, which now shows "Looking for networks…" You wait. Eventually it reconnects. You get back on the call and apologize. The other person is gracious. You feel like a moron.

This has happened to me, I am not exaggerating, hundreds of times in the past few years.

## The thing that finally broke me

The actual reason I sat down and built this app was a slightly more specific frustration: arguing with my ISP.

The internet at the cafe used to drop, on average, two or three times per day. Brief drops — twenty seconds to two minutes — but enough to ruin Zoom calls, kill SSH sessions, and break the point-of-sale terminal in the middle of a transaction. I would call the ISP. They would run a "line test" while I was on hold. The line test would come back clean. They would tell me my router was the problem. They would suggest I reboot it. They would charge me $90 if a technician came out and "couldn't find anything wrong."

The problem, as I eventually understood, is information asymmetry. The ISP has all the data. They know when their lines drop. They know when their head-end equipment hiccups. I have nothing — just a fading memory that my Zoom call froze around 10:14 this morning and again around 2:30. I can't prove anything. They can deny everything.

I tried solving this manually. I left a terminal window open running `ping 8.8.8.8` continuously, with output piped to a file. When the WiFi dropped, the timestamps in the log captured it. I sent that log to the ISP. They told me to use their app. I pointed out that their app required an internet connection to load. They sent another technician. The technician charged me $90. He could not find anything wrong.

I needed a tool that:
- Knew the instant my WiFi disconnected, without me having to watch a terminal
- Recorded the exact downtime when it came back
- Built up a history of outages I could hand to the ISP without arguing
- Did all of this passively, in the background, without any setup or maintenance

So I built it.

## What SignalDrop actually does

SignalDrop sits in your Mac's menu bar. It uses Apple's CoreWLAN framework — the same framework macOS itself uses — to monitor the state of your WiFi connection. The framework is *event-driven*, which is a fancy way of saying it tells the app when something changes instead of the app having to ask. That means SignalDrop uses essentially zero CPU and zero battery. It's just listening.

When your WiFi drops, you get an instant macOS notification. When it comes back, you get another notification telling you exactly how long it was down. (*"Back on Home-WiFi-5G — 47s offline."*) If your signal gets weak — below the threshold where things start to drift — you get a heads-up before the drop happens. If you're connected to a network that has WiFi but no actual internet (the dreaded "captive portal not loaded" state), it tells you that too.

It builds up a per-network reliability log. So I can see that the cafe WiFi has had a 96.4% uptime over the last 30 days, with 7 disconnects, and the average outage was 42 seconds. I can see that the apartment WiFi has had 99.7% uptime. I can see exactly which café has the worst WiFi (Cafe Meria, sadly, despite my best efforts).

And the killer feature, the one I actually built it for: a one-click button that copies a paste-ready outage receipt to my clipboard, formatted for ISP support chats. *"3 outages today: 9:47 AM (1m 12s), 11:23 AM (45s), 2:14 PM (2m 8s). Past 7 days: 19 disconnects, 48 minutes of downtime. Connection grade: D."* I paste that into the support chat. The conversation gets noticeably more productive.

## Some design choices I made on purpose

**No tracking. No analytics. No accounts.** SignalDrop makes zero network requests of its own. It can't, because if it did, it wouldn't be able to honestly report on your network. Apple requires the Location Services permission for any app that reads WiFi network names, which trips a lot of people up — I tried for weeks to find a way around it before accepting that there isn't one. The permission is used solely to display your network name in the menu. Your location is never stored, never determined, never transmitted. The app makes literally no outbound connections.

**Local-only data.** Every event lands in a SQLite database on your Mac. You can export it as CSV. You can delete it. You can ignore it. It never leaves the machine.

**Event-driven, not polling.** This is technical but it matters. A lot of "WiFi monitor" apps poll the system every few seconds. That adds up. They drain your battery and your patience. SignalDrop registers for kernel-level WiFi events. macOS sends a message the instant something changes, and SignalDrop reacts. The rest of the time it's doing nothing.

**Paid, not free with tracking.** SignalDrop is $4.99 on the Mac App Store. That's not a small price for a utility but it's not a big price either, and it lets me build the app I want to build instead of the app advertising would force me to build. If you'd rather not pay $5 for it, that's fair — but please don't ask me to add a free tier with ads or "anonymous analytics" or a subscription. The math doesn't work and the soul of the product doesn't work either.

## Where it's going

This is v1.0.2. The next versions will add a nearby network scanner, real-time signal graphs, customizable menu bar display, and channel-conflict detection. The roadmap is public on the App Store description.

If you've ever had a Zoom call die mid-sentence because the Mac decided to stop telling you about your own WiFi — install SignalDrop. It's a small thing that solves a small but persistent frustration. And if the cafe WiFi is anything to go by, you'll probably end up with a few interesting conversations with your ISP.

---

[Download SignalDrop on the Mac App Store →](https://apps.apple.com/app/id6761185430)

---

**Editorial notes for Jesse before publishing:**
- Audit the "ninety seconds" / "hundreds of times" claims — adjust to match what feels honest
- The ISP technician + $90 anecdote: confirm those details are accurate for your situation
- The "96.4% uptime" / "47s offline" specific numbers — sub in actual numbers from your own SignalDrop event log
- If you have a real photo of the cafe (or the bad WiFi router that started this), add it inline — gives the post a non-AI feel
- Suggest adding a 60-second screen recording of SignalDrop in action as an embedded clip
- Tag suggestions: macOS, indie dev, productivity, WiFi, Cafe Meria, SignalDrop
