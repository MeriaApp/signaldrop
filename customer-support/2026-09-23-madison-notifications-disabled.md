# Reply draft: Madison (m@golee.com), "Notifications disabled" in menu

Status: DRAFT, not sent. Send from jesse@jessemeria.com as a reply to her "SignalDrop support" email.

---

Hi Madison,

Thanks for writing, and for the screenshots. They made this easy to track down.

Your settings are correct, and you don't need to change anything. This is a bug in SignalDrop, not in
your setup. The first time the app launches, it checks notification permission before it has asked
you for it. After you allow notifications, the menu never re-checks, so it keeps showing
"Notifications disabled" even though they're on.

To clear it now, quit SignalDrop from its menu (Quit SignalDrop, or Command-Q) and open it again
from your Applications folder. The line will disappear, and alerts will work normally from then on.
If you want to confirm, open Settings in the SignalDrop menu and click "Send test notification".

I've fixed this so the menu re-checks permission every time you open it, and the fix will be in the
next update.

Thanks again for reporting it.

Jesse
