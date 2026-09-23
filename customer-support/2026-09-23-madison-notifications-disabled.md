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
