# SignalDrop — Resolution Center Reply (2026-05-19)

**Submission referenced by Apple:** `ffab330e-940b-4b68-a8f8-0bcaca52e952`
**Reviewed:** May 19, 2026 · Version 1.1.0 (build 6) · MacBook Pro (14-inch, Nov 2024)
**Guideline cited:** 5.1.1(iv) — Legal / Privacy / Data Collection and Storage
**Drafted:** 2026-05-18 evening

Paste this into App Store Connect → Resolution Center after Jesse approves.

---

Hi App Review,

Thank you for the detailed feedback on the 5.1.1(iv) issue. Rather than
ask for the bug-fix-eligible approval of build 6, we have resolved both
sub-issues in build 7 (now uploaded; same version 1.1.0). Resubmitting
now.

**Sub-issue 1 — "Allow" / "Enable" button label on the pre-permission
explainer**

The Location and Notifications pre-permission screens in build 6 had an
inner call-to-action button labeled "Allow" and "Enable" respectively.
Build 7 removes those inner buttons entirely. The only button on each
explainer screen is now the footer "Continue" button.

**Sub-issue 2 — "Skip" footer button on the pre-permission explainer**

The footer button in build 6 read "Skip" on the permission steps, which
allowed the user to dismiss the explainer without ever seeing the
CoreLocation / UNUserNotificationCenter authorization prompt. Build 7
removes that path. The footer button now always reads "Continue", and
tapping it directly triggers the system permission request:

- On the Location step: `CLLocationManager.requestAlwaysAuthorization()`
  fires immediately, surfacing the macOS Location prompt with our
  `NSLocationUsageDescription` text.
- On the Notifications step: `UNUserNotificationCenter.requestAuthorization`
  fires immediately, surfacing the macOS Notifications prompt.

After the user responds in the system prompt (Allow or Don't Allow), the
onboarding window advances to the next step. The user always proceeds
to the OS prompt after seeing the explainer, with no escape path.

**Per Apple's guidance**, the post-onboarding "done" step still
explains, in plain text only (no directional CTA), how the user can
change either permission later in System Settings → Privacy & Security
if they declined the OS prompt.

**Files changed in build 7:**

- `Sources/SignalDrop/OnboardingView.swift` — pre-permission step UI,
  primary-footer-button label logic, advance() state machine.
- `Sources/SignalDrop/OnboardingController.swift` — removed the now-unused
  `openSystemSettings(for:)` helper and the corresponding closure parameter
  on `OnboardingView`.

No other surfaces in the app touch user-permission flows or display
custom pre-permission messages. We grep'd the project for any other
"Allow" / "Enable" / "Skip" strings tied to permission requests and
found only the OnboardingView occurrences (now fixed).

Build 7 also keeps the existing privacy posture intact:

- SignalDrop reads the current Wi-Fi network's SSID via Apple's CoreWLAN
  framework (`CWWiFiClient.interface()?.ssid()`). On macOS 14 (Sonoma)
  and later, CoreWLAN requires Location Services permission for SSID
  access.
- The location data is never recorded or transmitted. The app makes
  zero outbound network requests, has no analytics, and stores all
  WiFi event data in a local SQLite database on the user's Mac.
- `NSLocationUsageDescription` in Info.plist is unchanged from build 6.

Thank you for the re-review. Please reply here or via the contact info
on the submission if you need anything else.

Best,
Jesse Meria
jrmeria@gmail.com

---

**Self-check before sending:**
- [ ] Length: within Resolution Center limits
- [ ] Acknowledges Apple's offer to bug-fix-approve build 6 and explicitly
      declines in favor of resubmitting a clean build 7
- [ ] Addresses BOTH sub-issues (button label + Skip path) by name
- [ ] No claims that aren't verifiable from the codebase (grep'd before drafting)
- [ ] Confirms no other permission UI elsewhere in the app
- [ ] Build 7 uploaded + processed + attached to version + submission
      queued (verify state = WAITING_FOR_REVIEW before sending this reply)
