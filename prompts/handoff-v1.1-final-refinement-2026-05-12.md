# SignalDrop v1.1 — Final refinement + launch session (handoff)

**Date issued:** 2026-05-12
**Issued from session:** b8e5ae39 (Round 1 → Round 2/3 verification + sign-off pass)
**Project:** `~/Developer/dropout/`
**Remote:** `MeriaApp/signaldrop`
**Branch:** `main` (clean, 7 v1.1 commits already pushed, latest `6a3e79b`)

## Your mission

This is the FINAL polish + verification session before SignalDrop v1.1.0 build 6 ships to App Store Connect. The previous session shipped Rounds 1–3 of the polish audit, staged the version bump, and verified ~18 surfaces end-to-end. **Your job is not to add features.** Your job is to take the v1.1 binary and walk it through every reviewer-visible surface and every physical-state edge case the previous session could not reach — then, when (and only when) Jesse approves, run the ASC cancel + upload + resubmit sequence.

**No new features. No refactors. No scope creep.** If you find a bug, fix it; if you find a polish miss, fix it; otherwise leave the code alone.

## Current ASC state (verified 2026-05-12 via API)

- App: `SignalDrop - WiFi Monitor` (id `6761185430`), platform `MAC_OS`
- Live: **v1.0.1** state=READY_FOR_SALE
- Pending: **v1.0.2** state=`WAITING_FOR_REVIEW`, releaseType=AFTER_APPROVAL, created 2026-05-11
- Pending RS: `ab1a06cd-93e1-4d10-8053-2150036a88ab` submitted 2026-05-11T22:50 UTC
- Stale RS (READY_FOR_REVIEW, never submitted): `7e5de1f5-6679-4a48-9f12-9ac1975f106b` — investigate + clean up

**Jesse's instruction is explicit:** if 1.0.2 is still WAITING_FOR_REVIEW → cancel it and replace with 1.1.0 build 6. If it has flipped to IN_REVIEW → do not touch it, hold 1.1.0 staged until 1.0.2 completes one way or another.

Verify state via the JWT pattern at `~/.claude/playbooks/asc-api-patterns.md` BEFORE any submit action.

## Read first (in this order)

1. **`CONTEXT_STATE.md`** — full session arc + what's staged
2. **`audits/v1.1-polish-audit-2026-05-11.md`** — original 24-item Tier 1/2/3 audit (all shipped — verify nothing regressed)
3. **`AppStore/whats-new-1.1.0.md`** — the staged What's New + submission mechanics
4. **`test-artifacts/verification-pass/`** — 18 screenshots proving Tier A surfaces (your baseline)
5. Memory: `project_signaldrop_v1_1_round_2_3_shipped_2026_05_11.md`, `reference_swiftui_table_macos_14_4_conditional_columns.md`, `reference_oui_vendor_lookup_pattern.md`, `idea_signaldrop_remote_host_availability_alerts.md`
6. Rule files: `~/.claude/rules/real-user-testing.md`, `~/.claude/rules/asc-pre-submission-visual-audit.md`, `~/.claude/rules/top-tier-agents-only.md`, `~/.claude/rules/verify-agent-output.md`

## Build + run first

```bash
cd ~/Developer/dropout
xcodegen
xcodebuild -project SignalDrop.xcodeproj -scheme SignalDrop -configuration Release build
open ./build/Release/SignalDrop.app
```

Confirm About dialog shows **1.1.0 (6)** before doing anything else.

## Tier C — Physical-state verifications (must happen on Jesse's machine)

These could not be verified in the previous session because they require physical hardware state changes. Walk each one, capture a screenshot, file under `test-artifacts/launch-readiness/`.

1. **WiFi off → menu bar icon flips to `wifi.slash`**
2. **Internet unreachable → `wifi.exclamationmark`** (try: connect to a network with no upstream — or block on your firewall briefly)
3. **USB tether mode → "Online via USB — WiFi idle"** (plug iPhone via USB with Personal Hotspot on)
4. **Location denied → `lock.icloud`** (System Settings → Privacy → Location → uncheck SignalDrop)
5. **Sleep / wake → monitoring cleanly resumes** (close lid 60s, reopen, watch for icon flicker or stuck states)
6. **Real disconnect → notification fires with Focus OFF + History row appears** (toggle WiFi off >5s, on; confirm both)
7. **Phantom-drop suppression at the 5s threshold** (toggle WiFi off+on <5s; confirm NO notification, History tab does NOT log)
8. **Quiet-hours wrap-around (22:30 → 07:15)** (set those times, force a non-critical notification via Settings → Send test, confirm suppressed; test critical→test, confirm fires)
9. **Per-event toggle persistence across relaunch** (disable Reconnect notification, ⌘Q, relaunch, confirm still disabled)
10. **Sound toggle + a real notification** (sound off → toggle, force notification, confirm silent)
11. **SignalDropDirect (Sparkle) update flow** (this is the OTHER build target — install the 1.0.0 DMG first, then run with appcast pointed at 1.1.0, confirm download + relaunch)
12. **VoiceOver narration end-to-end** (Cmd+F5, walk Scanner → Signal Graph → History → Settings, verify every label speaks correctly)

## Tier P — Polish & launch-readiness (fresh eyes)

13. **Cold-start onboarding flow** — delete `~/Library/Containers/com.meria.signaldrop/` AND `~/Library/Application Support/SignalDrop/`, relaunch, walk every welcome screen, screenshot each. Polish anything that feels rough.
14. **PDF export end-to-end** — generate one in the History tab, open in Preview, **print it to paper or to-PDF**, confirm it looks like something an ISP support tier would treat seriously. Does the wordmark sit right? Does the timeline render correctly on letter-size? Is the per-network rollup readable?
15. **Adversarial pass against the running app** — "find 5 ways this will break in production." Use the top-tier agent guidance: spawn a Sonnet 4.6 `general-purpose` agent with the actual binary path + full code context. Cap with zero allowed; quote-verbatim findings. Then fact-check each via primary source before fixing.
16. **App Store screenshots refresh** — current Mac App Store screenshots are from 1.0.x. v1.1 has three brand-new tabs (Network Insights) that aren't shown anywhere. Generate new screenshots heroing Signal Graph, Scanner, and Connection History. Use the scripted screen-recording pipeline from `~/.claude/playbooks/ios-sim-automation.md` adapted for macOS if useful, otherwise hand-shot at 2880×1800.
17. **Marketing site refresh** — does signaldrop.app mention Network Insights, vendor identification (38k OUI entries), pause graph, PDF export, hover tooltips, quiet-hours minute precision? If not, refresh the landing page copy. Check `MARKETING/` for press drafts and SEO strategy that may need a 1.1 sync.
18. **Press / outreach final review** — last-pass on `MARKETING/PRESS_OUTREACH_DRAFTS.md` before sending after launch.
19. **What's New copy critique** — read `AppStore/whats-new-1.1.0.md` aloud. Does it sing or just inform? Tighten any sentence that feels marketing-speak.
20. **Privacy policy + terms** — does the live policy at signaldrop.app/privacy cover the new surfaces (BSSID display in scanner, local-only OUI lookup, PDF export contains your local network history)? If anything is new, draft an update.
21. **Pre-submit visual audit** — every reviewer-visible surface on the smallest supported Mac display in your possession. No content cut off, no scroll-required compliance text. Capture under `test-artifacts/asc-submission-3-visual-audit-2026-05-12/` per `~/.claude/rules/asc-pre-submission-visual-audit.md`.
22. **Demo account in ASC review notes** — does it still match what reviewers will see in v1.1? Confirm Free tier (no IAP gate to hide), confirm credentials work in production.
23. **Apple Guideline re-read** — 3.1.2(a) doesn't apply (no subscriptions in SignalDrop), 5.1.5 (Location for WiFi — verify usage description string still accurate). No new permission strings added in v1.1 — re-verify Info.plist.
24. **⌘N / ⌘, discoverability** — confirm both appear in the menu bar under the right menus + show their shortcuts.

## Tier S — Submission mechanics (only after Jesse approves Tier C + P done)

Re-check ASC state via API immediately before each step (don't trust state from earlier in the session — it can change while you work).

**S1. Cancel the pending 1.0.2 reviewSubmission** (only if state is still WAITING_FOR_REVIEW — if it has flipped to IN_REVIEW, STOP and ask Jesse):

```python
PATCH /v1/reviewSubmissions/ab1a06cd-93e1-4d10-8053-2150036a88ab
{"data":{"type":"reviewSubmissions","id":"ab1a06cd-…","attributes":{"canceled":true}}}
```

Then investigate + delete the stale `7e5de1f5-…` READY_FOR_REVIEW that was never submitted.

**S2. Archive + upload 1.1.0 build 6:**

```bash
cd ~/Developer/dropout
xcodebuild -project SignalDrop.xcodeproj -scheme SignalDrop \
  -configuration Release -destination 'generic/platform=macOS' \
  -archivePath build/SignalDrop-1.1.0.xcarchive archive
xcodebuild -exportArchive -archivePath build/SignalDrop-1.1.0.xcarchive \
  -exportPath build/SignalDrop-1.1.0 -exportOptionsPlist ExportOptions.plist
xcrun altool --upload-app -f build/SignalDrop-1.1.0/SignalDrop.pkg \
  -t macos --apiKey 5RDJ5SQ5LK --apiIssuer "$ASC_API_ISSUER_ID"
```

Wait for the build to appear in ASC + finish processing (5–20 min). Verify via API.

**S3. Create new reviewSubmission, attach v1.1.0 version, submit:**

Use the 3-step pattern from `~/.claude/playbooks/asc-api-patterns.md` and the verbatim "What's New" from `AppStore/whats-new-1.1.0.md`. Default `releaseType=AFTER_APPROVAL` per Jesse's standing preference.

Confirm state = `WAITING_FOR_REVIEW` after submission.

## Hard rules for this session

- **Never submit to ASC without explicit Jesse approval.** Even if Tier C + P all pass green. Final submit is Jesse's button.
- **Never modify the in-review 1.0.2 submission if its state has flipped to IN_REVIEW.** Hold 1.1.0 staged.
- **Never bump `MARKETING_VERSION` or `CURRENT_PROJECT_VERSION` in `project.yml` for any other reason.** The 1.1.0/6 bump is staged in `6a3e79b`. Leave it.
- **Never strip Sparkle from SignalDropDirect target.** Dual-target structure is intentional.
- **Banned language unchanged** — no "100% verified", "production-ready", "best in class" without real-user evidence. Replace with "X verified, Y/Z edges known."
- **Top-tier agents only** for any audit or review (`general-purpose` Sonnet 4.6 minimum — never `Explore` Haiku).
- **Primary-source fact-check** every consequential agent finding before acting.
- **Stage commits by file name explicitly.** Never `git add -A`. Never amend. Never force-push.
- **Push to MeriaApp/signaldrop:main** after every verified batch — main shouldn't sit >10 commits ahead of origin.

## Success criteria

You're done when ALL of these are true:

- [ ] Every Tier C item walked end-to-end on Jesse's machine + screenshotted
- [ ] Every Tier P polish item shipped (or explicitly deferred to v1.2 with Jesse's sign-off)
- [ ] Pre-submit visual audit complete on smallest supported Mac display
- [ ] App Store screenshots refreshed to show v1.1 surfaces (or explicitly confirmed unchanged)
- [ ] Marketing site refreshed (or explicitly confirmed unchanged)
- [ ] What's New copy reviewed + tightened
- [ ] Privacy policy + Terms reviewed + updated if needed
- [ ] Demo account state confirmed
- [ ] Jesse signs off explicitly: "ship it"
- [ ] 1.0.2 RS canceled (if state still permits)
- [ ] 1.1.0 build 6 uploaded + processed + attached to new RS + submitted
- [ ] State verified `WAITING_FOR_REVIEW` post-submit
- [ ] Commit + push the submission state to MeriaApp/signaldrop:main

## When you finish

1. Append session log to `CONTEXT_STATE.md`
2. Save 2–5 new memory files capturing durable insights (Tier C state-transition behaviors, any polish discoveries, the submission cycle outcome)
3. Update `MEMORY.md` index
4. If 1.1.0 lands in review safely → fire press outreach drafts (Jesse-gated approval per draft)
5. Tag the commit `v1.1.0` (annotated, with What's New copy in tag message) + push the tag

## The bar

Same as last session. Apple-level. Linear-level. Stripe-level. Every surface is one you'd be proud to demo to a senior product designer at Linear, a principal engineer at Apple, and a CMO at Stripe in the same room. If anything falls short of that bar, fix it before submit.

Begin by reading the files in the order above, then running the build + run, then walking Tier C surface-by-surface.
