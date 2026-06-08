import AppKit

#if DEBUG
// Deterministic gating verification for the App Store review prompt.
// Run headless: `SignalDrop -reviewSelfTest`. The actual system dialog is
// Apple-rendered only in Mac App Store builds, so this proves the *trigger
// gating* (the part we own), not Apple's UI.
if CommandLine.arguments.contains("-reviewSelfTest") {
    runReviewSelfTest()
    exit(0)
}

func runReviewSelfTest() {
    var failures = 0

    func scenario(
        _ name: String,
        firstLaunchDaysAgo: Double,
        version: String,
        seed: [String: Any] = [:],
        drops: Int,
        expectAsks: Bool
    ) {
        let suite = "review.selftest.\(UUID().uuidString)"
        let d = UserDefaults(suiteName: suite)!
        let base = Date(timeIntervalSince1970: 1_800_000_000)
        d.set(base.addingTimeInterval(-firstLaunchDaysAgo * 86_400), forKey: "review.firstLaunchDate")
        for (k, v) in seed { d.set(v, forKey: k) }

        var asks = 0
        let svc = ReviewPromptService(
            defaults: d,
            now: { base },
            appVersion: { version },
            requestReviewImpl: { asks += 1 }
        )
        for _ in 0..<drops { svc.recordCaughtDropAndMaybeAsk() }

        let asked = asks > 0
        let ok = asked == expectAsks
        if !ok { failures += 1 }
        print("  [\(ok ? "PASS" : "FAIL")] \(name): asked=\(asked) (expected \(expectAsks)), prompts=\(asks)")
        UserDefaults.standard.removePersistentDomain(forName: suite)
    }

    print("=== ReviewPromptService gating self-test ===")
    scenario("brand-new user, 3 drops, day 0 → too early (time gate)",
             firstLaunchDaysAgo: 0, version: "1.2.0", drops: 3, expectAsks: false)
    scenario("engaged user, only 2 drops → too few",
             firstLaunchDaysAgo: 5, version: "1.2.0", drops: 2, expectAsks: false)
    scenario("engaged user, 3rd drop after 5 days → ASKS once",
             firstLaunchDaysAgo: 5, version: "1.2.0", drops: 3, expectAsks: true)
    scenario("engaged user, 6 drops in one session → asks exactly once",
             firstLaunchDaysAgo: 5, version: "1.2.0", drops: 6, expectAsks: true)
    scenario("already asked on THIS version → never re-asks",
             firstLaunchDaysAgo: 30, version: "1.2.0",
             seed: ["review.lastPromptVersion": "1.2.0"],
             drops: 5, expectAsks: false)
    scenario("new version but inside 120-day cool-down → blocked",
             firstLaunchDaysAgo: 200, version: "1.3.0",
             seed: ["review.lastPromptVersion": "1.2.0",
                    "review.lastPromptDate": Date(timeIntervalSince1970: 1_800_000_000 - 30 * 86_400)],
             drops: 5, expectAsks: false)
    scenario("new version AFTER 120-day cool-down → ASKS",
             firstLaunchDaysAgo: 300, version: "1.3.0",
             seed: ["review.lastPromptVersion": "1.2.0",
                    "review.lastPromptDate": Date(timeIntervalSince1970: 1_800_000_000 - 200 * 86_400)],
             drops: 5, expectAsks: true)

    print(failures == 0 ? "ALL PASS ✅" : "\(failures) FAILURE(S) ❌")
}
#endif

let app = NSApplication.shared
app.setActivationPolicy(.accessory)  // No Dock icon — menu bar only

let delegate = SignalDropApp()
app.delegate = delegate
app.run()
