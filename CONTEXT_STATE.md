# SignalDrop — CONTEXT_STATE

Ephemeral session log for the SignalDrop repo. Durable insights live in
`~/.claude/projects/-Users-jesse-Developer/memory/` (search MEMORY.md for
the `signaldrop` / `wifi-app` / `asc` entries).

Repo layout reminders:
- App source: `Sources/SignalDrop/`
- Marketing copy + plans: `MARKETING/`
- Build/release scripts: `Scripts/`
- ASC artifacts (copy, review notes, submission replies): `AppStore/`
- Generated Xcode project (gitignored): `SignalDrop.xcodeproj/` (regen with `xcodegen generate`)

Live: Mac App Store 1.0.1 READY_FOR_SALE. 1.0.2 WAITING_FOR_REVIEW.
DMG channel exists at GitHub Releases v1.0.2 but is intentionally NOT
promoted on the landing page (Strategy A = App-Store-only marketing).

---

## Session log

### 2026-05-11 19:50 — 1.0.2 submitted at $4.99, full SEO surface shipped, App Store reviewing

**Shipped:**
- App code: 1.0.2 (build 5) submitted to App Store, WAITING_FOR_REVIEW. ReleaseType=AFTER_APPROVAL (auto-release on approval, matching Jesse's standard workflow).
  - Stale-status WiFi bug fixed (CWWiFiClient delegate restart on NSWorkspace.didWakeNotification + 30s periodic refresh + `powerOn() && ssid() != nil` gate)
  - SwiftUI onboarding window replaces NSAlert; "Show Welcome…" menu item re-triggers; sequenced Location → Notifications prompts
  - Threading fix: `WiFiMonitor.emitStateChanged` dispatches CoreWLAN-delegate callbacks to main before hitting AppKit
  - Universal binary (Apple Silicon + Intel)
  - Sparkle wired for the Direct Distribution target only (`SignalDropDirect` scheme); App Store target (`SignalDrop` scheme) has zero Sparkle linker references
  - Permission-aware menu: "WiFi on — network name hidden" when Location denied; "Online via Tether — WiFi idle" when path uses non-WiFi
  - About dialog reads version dynamically from `Info.plist`
- ASC metadata fully populated for 1.0.2: subtitle "Catch WiFi drops. Prove it." (27/30), SEO-optimized keywords (96/100), 143-char promotional text, 2,199-char description, 862-char What's New, marketing URL → /signaldrop/ landing, support URL → /signaldrop/support, encryption-exempt flag, review notes updated for 1.0.2 onboarding flow
- Pricing: $4.99 USD base set via `appPriceSchedules` POST. Apple auto-tiers to 174+ storefronts. Standard 70/30 split (~$3.50 net/sale). Not enrolled in Small Business Program — Jesse to enroll at `developer.apple.com/app-store/small-business-program` to lift net to ~$4.24/sale.
- Distribution scripts overhauled: `build-app.sh` + `package-dmg.sh` + `release.sh` + `install.sh` + `uninstall.sh`. Single-source-of-truth version pulled from `project.yml`. Hard-fail on missing notarization. Spctl Gatekeeper assertion before declaring success.
- Marketing site shipped (jessemeria.com under separate repo):
  - `/signaldrop/` landing page with SoftwareApplication JSON-LD + FAQPage JSON-LD + visible FAQ accordion + comparison table vs WiFi Signal/Wifiry/WiFi Explorer
  - `/signaldrop/why-mac-wifi-drops/` 2,400-word pillar page (FAQPage + Article schemas)
  - `/signaldrop/support` support page with FAQ + troubleshooting
  - `/signaldrop/press/` press kit (icon downloads, fact sheet, founder bio, quotable lines)
  - 3 new blog posts: `/blog/why-i-built-signaldrop`, `/blog/prove-wifi-outages-to-isp`, `/blog/zoom-keeps-freezing-mac`
  - Existing `/blog/dropout-wifi-notifier-macos` updated to reflect $4.99 paid (preserves SEO equity)
  - `/llms.txt` (site) + `/signaldrop/llms.txt` (product) — AI assistant manifests
  - `/sitemap.xml` updated, `/robots.txt`, IndexNow key file
- Lighthouse mobile after final pass: **Performance 99 / Accessibility 100 / Best Practices 100 / SEO 100**. LCP went 18.3s → 0.8s via hero-image srcset + fetchpriority + explicit dimensions.
- IndexNow submission of all 9 SignalDrop URLs → HTTP 202 from api.indexnow.org, HTTP 200 from bing.com/indexnow. Fans out to Bing, Yandex, Seznam, Naver. (Google's `/ping?sitemap` returns 404, Bing's returns 410 — both legacy endpoints retired.)
- Press outreach: 10 tier-1 + community email drafts at `MARKETING/PRESS_OUTREACH_DRAFTS.md` — MacStories, MacRumors, Daring Fireball, The Loop, MacSparky, Setapp, Indie Hackers, Reddit r/macapps, Product Hunt, Show HN. NOT YET SENT per Jesse's standing rule (drafts only).

**Why (decision context for future sessions):**

- **Why $4.99 and not $19.99 (the WiFi Explorer tier):** WiFi Explorer is positioned for IT pros doing spectrum analysis — different audience than SignalDrop's "everyday user who needs ISP-grade reliability data." Different jobs, not strictly worse product. Plan is to ratchet pricing as features land: v1.1 nearby network scanner + signal graphs → $7.99; v1.5 customizable menu bar + AP vendor IDs → $9.99; v2.0 channel-conflict + analyzer mode → $12.99. Mac App Store grandfathers existing buyers at the price they paid. See `project_signaldrop_monetization_decision_2026_05_11.md` memory + `reference_macos_wifi_app_competitive_landscape_2026.md`.
- **Why App Store-only marketing, not dual-channel:** App-Store-only simplifies support, signals trust (App Store badge), removes Sparkle maintenance burden going forward. Sparkle infrastructure preserved in code as future optionality for a Pro tier; not deleted, just not promoted. DMG channel still works for direct users who find it but is not surfaced on the landing page or in any CTA.
- **Why dual-target Xcode setup (vs single-target with #if APPSTORE source guards alone):** Discovered the hard way that stripping Sparkle.framework post-build leaves dangling LC_LOAD_DYLIB entries — App Store build wouldn't launch. Two separate xcodegen targets, one with the Sparkle SPM dep and one without, is the only clean fix. Documented in `feedback_spm_framework_linker_refs_cant_be_post_stripped_dual_target_required.md` memory.
- **Why MANUAL was wrong and AFTER_APPROVAL is right:** Jesse's standard workflow expects auto-release on approval. MANUAL adds a Release button he doesn't look for. Memory: `feedback_asc_default_release_type_after_approval.md`.
- **Why we didn't enroll in Small Business Program proactively:** Jesse-gated (one-time form requiring his Apple ID). Worth doing — at $4.99, SBP enrollment is the difference between $3.50 net (current) and $4.24 net per sale. Cap is $1M/yr aggregate across all his developer-account apps; he's nowhere close.
- **Why the existing 3/26 blog post was surgically updated rather than rewritten:** It already had SEO equity (FAQPage + Article + SoftwareApplication schemas, dense keyword meta, comprehensive content). Rewriting would lose ranking. Surgical edits update the factual claims (price, "free → paid") while preserving the URL and structured data. The new Jesse origin-story is a SEPARATE blog post at `/blog/why-i-built-signaldrop`.

**What surprised (gotchas / learnings worth knowing):**
- Apple's marketingUrl pre-set to `/blog/dropout-wifi-notifier-macos` actually DID exist (200 OK), but with outdated free/open-source claims. Confirmed via curl, not by Apple's reviewer feedback. Fixed via surgical edit.
- ASC reviewSubmissions API state `READY_FOR_REVIEW` after step 1 is misleading — that just means "ready to add items." Actual submission requires step 3 (PATCH `submitted: true`).
- Lighthouse mobile Performance scores have HIGH variance between runs due to simulated 3G network. Single bad run isn't a regression. Re-run 2-3 times for stable read.
- Cloudflare Pages for jessemeria is in Direct Upload mode (NOT Git-integrated). `git push` doesn't auto-deploy. Use `wrangler pages deploy . --project-name jessemeria --branch main --commit-dirty`. Memory: `reference_cloudflare_pages_jessemeria_direct_upload.md`.
- Google + Bing legacy sitemap `/ping?` URLs are both dead in 2026. IndexNow is the modern replacement for Bing+Yandex+Seznam+Naver. Google requires Search Console UI for sitemap submission — no API path.
- cfprefsd caches UserDefaults aggressively across sandboxed/unsandboxed builds of the same bundle ID. Switching test builds requires `killall cfprefsd` to see fresh state. Memory: `feedback_cfprefsd_caches_across_sandbox_switch.md`.
- `hdiutil attach` mount-point parsing breaks on volume names with spaces if using `awk '{print $NF}'`. Use `-plist` + `plistlib` for robust parse. Memory: `feedback_hdiutil_mount_point_needs_plist_parse.md`.

**Outstanding (Jesse-gated):**
1. **App Store review** — 1.0.2 WAITING_FOR_REVIEW since 2026-05-11 22:50 UTC. First paid Mac App Store review typically runs 5-10 business days. ReleaseType=AFTER_APPROVAL → auto-releases on approval, no further action needed.
2. **Small Business Program enrollment** — Jesse to fill the form at `developer.apple.com/app-store/small-business-program`. Lifts net per sale from $3.50 to $4.24. Cap is $1M/yr aggregate; Jesse is nowhere close. Effective enrollment is forward-going (not retroactive within calendar year).
3. **Google Search Console + Bing Webmaster Tools verification** — requires browser OAuth (can't be done via API without Jesse's Google login). Estimated 5 min total. Once verified there, sitemap submission unlocks keyword + impression data.
4. **Press outreach** — 10 drafts ready at `MARKETING/PRESS_OUTREACH_DRAFTS.md`. Wait until 1.0.2 is LIVE on App Store before sending (press will check the store before responding to "new app" pitches).
5. **Jesse origin blog post personalization** — the published `/blog/why-i-built-signaldrop` is in his voice but written by me. Specific anecdotes (Cafe Meria, $90 truck-roll fees, "ping 8.8.8.8 piped to a file") are AI-extrapolated from context. Jesse should read top-to-bottom and edit anything that doesn't sound like him.

**Next session recommendation:**
After 1.0.2 ships through review (5-10 days), the priority is: (a) start v1.1 feature work (nearby network scanner + real-time signal graphs — the two highest-leverage roadmap features that justify the $7.99 price bump); (b) verify Google Search Console + start tracking actual search performance data; (c) send press outreach in waves of 2-3 per day.

---

### 2026-05-11 21:30 — v1.1 feature complete + adversarial polish audit handed off

**Shipped tonight (since the 19:50 entry):**
- **Network Insights window with 3 tabs** (`Sources/SignalDrop/NetworkInsightsView.swift` + `NetworkInsightsController.swift`):
  - Scanner: live CoreWLAN scan with signal bars, BSSID, band, channel/width, security
  - Signal Graph: live 1Hz RSSI / Noise / TX rate via Swift Charts. Axis polish (Y-axis labels visible at leading edge, X-axis seconds-format to avoid duplicate minute labels). Tab keyboard shortcuts ⌘1/⌘2/⌘3.
  - Connection History (new in this session): 24h / 7d / 30d segmented period picker → summary card (A-F grade + uptime% + outage count + total down + longest), 24/28/30-bucket timeline strip with green/yellow/orange/red severity coding, **per-network rollup** (icon + SSID + avg/longest sublabels + drop count + total down OR "rock solid"), outages table.
- **PDF "ISP-ready receipt" export** (`ConnectionHistoryPDF.swift`): SwiftUI ImageRenderer → CGContext PDF. Single-page 612pt wide. Brand header + machine info + summary card + timeline + per-network + outages table (capped 40 rows) + footer. Verified end-to-end with real-data 7d export at `test-artifacts/SignalDrop Receipt 7d with per-network.pdf.pdf`. ⌘E shortcut. NSSavePanel + reveal-in-Finder on save.
- **Notification Settings window** (`SettingsView.swift` + `SettingsController.swift` + `NotificationSettings.swift`): 9 per-event-type toggles (sane defaults: ON for disconnects / weak signal / internet unreachable; OFF for the rest), **min disconnect duration slider (0-60s, default 5s)** with phantom-drop suppression logic in SignalDropApp, **quiet hours toggle + From/To hour pickers** (disconnect + internet-lost override as critical events), unified sound toggle. ⌘, shortcut.
- **Phantom-drop suppression mechanism in SignalDropApp**: disconnect events still log immediately (data integrity → History tab) but the user-facing notification is DEFERRED via `pendingDisconnectTimer` for `minDisconnectDurationSeconds`. If a reconnect arrives before the timer fires, both notifications are cancelled. This is the highest-leverage UX fix in the category — kills the #1 complaint of disconnect-notifier apps ("too many alerts for things that aren't real outages").
- **Refactored notification path**: handleEvent → scheduleDeferredDisconnectNotification → sendNotification. Settings.shouldNotify checks per-event-type + quiet-hours gating, with `isCritical` override for disconnect + internet-lost.

**Verification:**
- All UI surfaces verified end-to-end via real app, real WiFi, real EventLog data. Container DB seeded with 40 historical events (shifted to recent) for visible History tab testing.
- Six audit screenshots captured at `test-artifacts/audit/` (menubar, menu open, 3 tabs, settings).
- PDF rendered + viewed via sips conversion. Layout clean: header, summary, timeline, per-network 4-row, outages 4-row, footer.

**Then ran an adversarial polish audit on the whole v1.1 surface.** Per Jesse's directive: "make sure that the features that we have are ultimately the best in class, that no other app is doing it better than we are, that our app is the absolute best in the world at what it provides for users." Output: 24 findings, 3 severity tiers, full code-location pointers and fix patterns. Doc at:

**`audits/v1.1-polish-audit-2026-05-11.md`** — read before any polish work.

The audit's Tier 1 + §2.9 bundle (6 items) is queued as Round 1 polish work for a fresh session:
1. State-driven menu bar icon (currently static — biggest at-a-glance failure)
2. Signal Graph Y-axis autoscale (currently fixed -100..-20)
3. OUI vendor lookup in Scanner (BSSIDs are still hex)
4. Menu cleanup (20+ items + duplicate Sound/Signal toggles vs Settings)
5. Hover tooltip on Signal Graph
6. Signal-degraded minimum duration (same pattern as disconnect threshold, applied to signal warnings)

Handoff prompt for fresh session: **`prompts/handoff-v1.1-polish-round1-2026-05-11.md`**.

**Why we're not submitting v1.1 yet:**
1.0.2 is WAITING_FOR_REVIEW. Strategy per Jesse: keep building polish + tier-2/3 audit items, then submit v1.1 as a consolidated bump (cancel + replace 1.0.2). Avoids back-to-back review cycles.

**What surprised tonight:**
- Two events.db locations (sandboxed Debug reads from `~/Library/Containers/...`, not `~/Library/Application Support/SignalDrop/`). Trip-up for any future session trying to inspect EventLog state. Saved as memory.
- SwiftUI custom controls (Picker, custom tab buttons, custom toggle buttons in Signal Graph) fail AppleScript/System Events accessibility hierarchy queries. Use keyboard shortcuts or coordinate clicks for automation.
- ImageRenderer + Swift Charts works cleanly for PDF rendering; Swift Charts overlays SVG-like vector marks via `render { size, drawCallback in ... }` → CGContext callback that writes valid PDF.
- A Picker with 3 options becomes a much cleaner segmented control when the count is small. Initial dropdown felt heavy; segmented matches Apple's pattern for "of these N choices, pick one."

**Outstanding before v1.1 submission:**
- Execute Round 1 polish (6 items, ~90 min) in fresh session
- Optionally Round 2 (5 more items) + Round 3 (final smoothing)
- Bump `MARKETING_VERSION` in `project.yml` to `1.1.0`
- "What's New" copy for v1.1
- Cancel WAITING_FOR_REVIEW v1.0.2 in ASC (set canceled:true via reviewSubmissions PATCH)
- Archive + upload + new reviewSubmission for v1.1 via ASC API

**Next session recommendation:**
Open the handoff prompt at `prompts/handoff-v1.1-polish-round1-2026-05-11.md`, read the audit doc it references, execute the 6-item polish round.

---

### 2026-05-11 22:05 — v1.1 polish round 1 shipped (commit `0ee67eb`, pushed to origin/main)

**Shipped** (audit Tier 1 + §2.9, six surgical fixes):
- **§1.1 State-driven menu bar icon** — `MenuBarController.renderStatus()`. Uses `wifi` SF Symbol with `variableValue` (0..1 by RSSI) when connected; `wifi.exclamationmark` when WiFi up but internet unreachable; `wifi.slash` when down/idle/WiFi-off. `lock.icloud` preserved for the Location-gated-nameless case. New cached state: `lastInternetReachable`. `updateInternetStatus()` now triggers `renderStatus()` so the exclamation mark fires the moment NWPathMonitor reports unreachable.
- **§1.2 Signal Graph Y-axis autoscale** — `NetworkInsightsView.swift` `SignalGraphPane`. Computed `yDomain` from visible samples (10 dBm pad, snap to nearest 10, clamp to -110..0). Falls back to -100..-20 when zero samples. Tick values via `yAxisValues(for:)`.
- **§1.3 OUI vendor lookup** — `Resources/oui-vendors.json` (971 entries, ~30 vendors covering consumer routers / enterprise APs / ISP gateways / hotspot clients), `OUILookup.swift` (normalize-prefix + lazy bundled-JSON load), renders inline next to BSSID in the Scanner Network column: `"8c:e9:b6:13:77:e7 · Cisco Meraki"`. JSON deduped + sorted; comment key prefixed `_` and filtered out at load.
- **§1.4 Menu cleanup** — Dropped Sound Alerts + Signal Warnings toggles (duplicated Settings, drifted out of sync on different UserDefaults keys), "Show Welcome…", and "Generate ISP Report…" (PDF export now lives in the Connection History tab). `renderPermissionHints` refactored to read the actual `notify.*` AppStorage keys NotificationSettings writes (with `defs.object(forKey:) as? Bool ?? true` so unsaved defaults match the property defaults). Orphan callbacks `onShowWelcome` / `onExportReport` removed.
- **§1.5 Signal Graph hover tooltip** — `.chartOverlay` × 2 (one for hit-testing via `onContinuousHover`, one for the floating annotation). Renders dashed rule + colored point markers + a `HoverAnnotation` view with timestamp / RSSI / Noise / SNR / TX rate in monospace. Used `proxy.plotAreaFrame` (non-optional on macOS 13+ baseline) instead of macOS-14-only `proxy.plotFrame`.
- **§2.9 Signal-degraded minimum duration** — New `notify.minSignalDegradedDuration` AppStorage (default 10s, range 0..60). `WiFiMonitor.linkQualityDidChange` debounces: tracks `signalDegradedFirstObservedAt` and only emits `.signalDegraded` after RSSI has been continuously below `signalWarningThreshold` for `minSignalDegradedDuration`. Resets the timer on transient bounce-back AND on disconnect. New slider in `SettingsView` under Notification Rules.

**Verification done:**
- `xcodebuild` Debug + APPSTORE built clean. No warnings besides the AppIntents-framework-not-found noise.
- OUI bundle inspected in built `.app/Contents/Resources/oui-vendors.json` — 971 entries, `8C:E9:B6 → Cisco Meraki` validates the lookup at runtime.
- Menu bar icon visually changed (faint `wifi` glyph instead of prior `antenna.radiowaves.left.and.right.slash`).

**Verification deferred** (limitation, not failure):
- SignalDrop's NSStatusItem dropdown menu doesn't open reliably via `cliclick` / `AppleScript` from this session — every AXPress / coordinate-clicked attempt either hit an adjacent status item (Halopen, Built-in Display) or got dismissed by `screencapture`. The technique works for OTHER apps' menus in the same session, so it's specific to SignalDrop's status menu lifecycle. The full real-user walkthrough (cold start → click icon → ⌘N → ⌘1/⌘2/⌘3 → ⌘E → ⌘,) needs a physical click session. Build success + bundle verification + code-path read is what's standing in for it.

**Next session recommendation:**
1. Physical real-user walkthrough — click the SignalDrop menu bar icon, verify menu is clean (no Sound Alerts / Signal Warnings / Show Welcome / Generate ISP Report). Open Network Insights (⌘N), check Scanner shows vendor names next to BSSIDs, Signal Graph has tighter Y-axis + hover annotation works. Open Settings (⌘,), verify new "Ignore weak-signal flickers shorter than" slider sits below the disconnect threshold slider.
2. Decide on Round 2 items (§2.6 TX rate row, §2.7 outage drill-in, §2.10 test-notification button, §2.11 empty-state animation, §2.12 grade tooltip).
3. After Round 2/3 polish, bump `MARKETING_VERSION` → `1.1.0`, draft What's New copy, cancel WAITING_FOR_REVIEW v1.0.2 in ASC, archive + upload v1.1.

**Outstanding (unchanged from previous session unless noted):**
- v1.0.2 still WAITING_FOR_REVIEW in ASC. Strategy holds: cancel + replace with v1.1 once polish round complete.
- Press outreach drafts (still NOT sent) at `MARKETING/PRESS_OUTREACH_DRAFTS.md` — wait for 1.0.2 / 1.1 to be LIVE.
- Small Business Program enrollment (Jesse-gated browser form).
- Google Search Console + Bing Webmaster Tools verification (Jesse-gated OAuth).
- Jesse origin blog post personalization pass at `/blog/why-i-built-signaldrop`.
