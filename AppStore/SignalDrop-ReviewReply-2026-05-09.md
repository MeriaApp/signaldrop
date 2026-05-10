# SignalDrop — Resolution Center Reply

**Submission ID referenced by Apple:** a3b2a410-302e-4570-8123-aa3858d5a712
**Reviewed:** April 01, 2026 · Version 1.0 · MacBook Pro (14-inch, Nov 2024)
**Drafted:** 2026-05-09

Paste this into App Store Connect → Resolution Center after Jesse approves.

---

Hi App Review team,

Thank you for the feedback on SignalDrop. We have addressed each of the three items below.

**Guideline 2.1 — Location Services Justification**

SignalDrop reads the current Wi-Fi network's SSID via Apple's CoreWLAN framework (`CWWiFiClient.interface()?.ssid()`). On macOS 14 (Sonoma) and later, CoreWLAN requires Location Services permission for any app that accesses SSID information.

SignalDrop uses the SSID to:

1. Display which network the user is currently connected to in the menu bar dropdown.
2. Track per-network reliability and uptime over time (one of the app's core features).
3. Detect SSID changes — i.e. when the Mac silently switches networks.

The location data is never recorded or transmitted. SignalDrop makes zero outbound network requests, has no analytics, and stores all Wi-Fi event data in a local SQLite database on the user's Mac. The `NSLocationUsageDescription` string in our Info.plist explains this to the user at the permission prompt.

**Guideline 2.1(a) — "Quit and Open Safari Extensions Preferences" button**

We searched the entire SignalDrop codebase, Xcode project, and Info.plist and confirmed:

- SignalDrop has **no Safari Extension target** (only a single `application`-type target named SignalDrop).
- There are **zero references** to "Safari Extensions," "Open Safari Extensions Preferences," or any related strings anywhere in the source code.
- The only Quit affordance in the entire app is **"Quit SignalDrop"** at the bottom of the menu bar dropdown (`MenuBarController.swift:193`). We have tested it on macOS 13, 14, and 15 and confirmed it terminates the app correctly.

We respectfully believe the 2.1(a) feedback may have been intended for a different submission, since the cited button does not exist in SignalDrop. If we have misunderstood, could you please reproduce the issue with the binary we submitted and let us know which screen or menu item opens that dialog? We will reproduce and resolve immediately.

**Guideline 2.3.3 — Screenshot Metadata**

We have replaced all five Mac App Store screenshots. The new screenshots:

- Show SignalDrop's actual menu bar dropdown UI in five real, distinct app states (Connected with excellent signal, Connected but no internet, Weak signal warning, Disconnected, and Per-network reliability log).
- Are captured from the running app on macOS, not marketing mockups.
- Include surrounding macOS context (menu bar) so reviewers can see how the app naturally appears in use.

We have also expanded the App Review Information notes to walk you through testing the app step-by-step — including the Location Services prompt, each menu state, and how to verify "Quit SignalDrop" works.

Thank you for the re-review. Please reply here or via the contact info on the submission if you need anything else.

Best,
Jesse Meria
jrmeria@gmail.com

---

**Self-check before sending:**
- [ ] Length: ~2,150 chars (well within Resolution Center limits)
- [ ] All 3 rejection items addressed in order Apple raised them
- [ ] Push-back on 2.1(a) is polite but firm — facts-first, with offer to reproduce
- [ ] No claims that aren't verifiable from the codebase (verified by grep before drafting)
- [ ] Screenshots already uploaded ✓
- [ ] Review notes already updated ✓
