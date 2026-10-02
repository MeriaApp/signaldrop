# Reply: Madison (m@golee.com), "Notifications disabled" in menu

Status: SENT 2026-09-23 19:08 UTC via Resend (id 01a0cfab-30a3-719b-8c4f-b195013d719e, delivered), from
Jesse Meria <jesse@jessemeria.com>, reply-to jesse@jessemeria.com, subject "Re: SignalDrop support".
Sent on Jesse's instruction. Replies land in Jesse's inbox via jessemeria.com forwarding.

---

Hi Madison,

Thanks for writing, and for the screenshots. They made this easy to track down.

Your settings are correct, and you don't need to change anything. This was a bug in SignalDrop, not in your setup. The first time the app launches, it checks notification permission before it has asked you for it. After you allowed notifications, the menu never re-checked, so it kept showing "Notifications disabled" even though they're on.

To clear it now, quit SignalDrop from its menu (Quit SignalDrop, or Command-Q) and open it again from your Applications folder. The line will disappear, and alerts will work normally. If you want to confirm, open Settings in the SignalDrop menu and click "Send test notification".

I've fixed it so the menu re-checks permission every time you open it. The fix is in version 1.2, which I've just submitted to Apple. It will arrive as a normal App Store update once Apple approves it. That update also adds alerts when your WiFi stays connected but the internet stops working.

Thanks again for reporting it.

Jesse

## 2026-09-23 5:13 PM: Madison's reply
Thanked us, said they'd wanted an app like this and are "looking forward to tracking those mysterious drops overnight."

Checked against the code before replying: SignalDrop only monitors while the Mac is awake (it holds no sleep assertion), and background DarkWakes were being logged as fake outages (fixed in 6800d60, not yet in any App Store build). Build 9 with the fix was submitted to replace build 8 in review.

## Second reply
Status: SENT 2026-09-23 22:19 UTC via Resend (id 01a0d05a-260d-75d2-b4b2-445c1b4adc59, delivered), from Jesse Meria <jesse@jessemeria.com>, subject "Re: SignalDrop support". Sent on Jesse's instruction.

---

Hi Madison,

Glad it's what you were looking for. A few things so overnight tracking works well:

1. Install the update when it arrives. Version 1.2 is with Apple for review now and will show up as a normal App Store update once it's approved. Besides the notification fix, it catches the most common overnight problem: your WiFi stays connected, but the internet behind it goes out. It also stops SignalDrop from counting time your Mac spends asleep as an outage.

2. Keep your Mac awake overnight. SignalDrop can only watch your connection while your Mac is awake, so if it sleeps, those hours go unrecorded.
- On a MacBook: keep it plugged in with the lid open, then go to System Settings > Battery > Options and turn on "Prevent automatic sleeping on power adapter when the display is off."
- On an iMac, Mac mini or Mac Studio: go to System Settings > Energy and turn on "Prevent automatic sleeping when the display is off."
The screen can still turn off.

3. In the morning, open History in the SignalDrop menu to see each drop, when it happened and how long it lasted.

Please let me know how it goes after a few nights. And if there's anything you'd want an app like this to do that it doesn't yet, tell me. I'm happy to consider it.

Jesse

**Follow up** when Madison reports back: feature requests go to the work queue.

## 2026-09-29 11:35 AM: Madison's feature request
Asked for Ethernet-only support: their Mac mini is Ethernet-only and they want to compare it with their MacBook Pro on WiFi. Checked against the code: with WiFi off, internet loss is logged to History but the alert is suppressed (`SignalDropApp.sendNotification`), the ISP receipt ignores it, and wired link loss isn't tracked. Queued as `~/.claude/work-queue/dropout/open/P2-2026-09-29-ethernet-only-monitoring.md`.

Third reply SENT 2026-09-29 16:40 UTC via Resend (id 01a0ee0a-65c8-752d-b5ee-535c93451f2f, delivered), on Jesse's instruction: thanks, explains the current Ethernet behavior, commits to Ethernet support with no date, notes one purchase covers both Macs.

Built the same day: 1.3.0 (10) submitted for review with Ethernet support. **Follow up** when it's approved: tell Madison it's live.

## 2026-10-02 11:13 AM: Madison reports the app quitting on its own
"SignalDrop has quit on its own several times. I suppose it may have crashed. Is there a way to collect info and submit it for you to review the next time it happens?"

Checked before drafting:
- 1.3.0 (Ethernet) and 1.2.0 are both READY_FOR_SALE (ASC, 2026-10-02), so Madison has had two App Store updates since 2026-09-23, and the "1.3 is live" note was still owed.
- The 1.3.0 Ethernet path has never run on real wired hardware; Madison's Mac mini is the first. Reading `NetworkMonitor.swift` and `WiFiEvent.outagePairs` found no crash, so the cause is unknown until a report arrives.
- No Apple-delivered crash data for 1.2/1.3 is cached in Xcode on Jesse's Mac. The app has no in-app diagnostics export.
- The `dropout-*.ips` reports on Jesse's Mac are the March prototype at `~/Library/Application Support/Dropout/dropout` (LaunchAgent `com.meria.dropout`), not the App Store app.

Fourth reply: DRAFT, not sent, waiting on Jesse's go.

---

Hi Madison,

Sorry about that, and thank you for offering to send details. Yes, there is a way, and you may already have what I need.

When an app crashes, macOS saves a report on your Mac. To find them:

1. In Finder, open the Go menu and choose Go to Folder.
2. Paste this and press Return: ~/Library/Logs/DiagnosticReports
3. Look for files whose names start with "SignalDrop". Each one is named with the date and time of a crash.

If you see any, attach them to a reply to this email. They describe what the app was doing when it stopped. They don't contain your browsing or your files.

Three things would help me alongside them:

- Which Mac it happened on: the Mac mini on Ethernet, the MacBook Pro, or both.
- The version you're running. Open the SignalDrop menu and choose About SignalDrop.
- Roughly when you noticed it had quit.

If that folder has no SignalDrop files, the app didn't crash. Something closed it. That is useful to know too, so please tell me. One thing that can do this is an App Store update, which closes the app to install the new version and doesn't always reopen it. There have been two updates in the last ten days. Turning on Launch at Login in the SignalDrop menu makes sure it comes back after a restart.

The second of those updates is the one you asked for. Version 1.3 is out now and tracks outages on Ethernet, so your Mac mini can be compared with your MacBook Pro. If the App Store hasn't installed it yet, you'll find it under Updates.

Jesse
