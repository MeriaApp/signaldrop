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
