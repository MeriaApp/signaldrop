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
