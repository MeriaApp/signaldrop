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

// Ethernet outage detection and WiFi/Ethernet outage pairing.
// Run headless: `SignalDrop -ethernetSelfTest`.
if CommandLine.arguments.contains("-ethernetSelfTest") {
    runEthernetSelfTest()
    exit(0)
}

func runEthernetSelfTest() {
    var failures = 0

    func check(_ name: String, _ ok: Bool, _ detail: String) {
        if !ok { failures += 1 }
        print("  [\(ok ? "PASS" : "FAIL")] \(name): \(detail)")
    }

    /// Each step is (path satisfied, over Ethernet, probe succeeded).
    func scenario(_ name: String, _ steps: [(Bool, Bool, Bool)], expectWired: [String], expectInternet: [String]) {
        let monitor = NetworkMonitor()
        var wired: [String] = []
        var internet: [String] = []
        monitor.onWiredChange = { change in
            switch change {
            case .lost(let cause): wired.append("lost(\(cause))")
            case .restored: wired.append("restored")
            }
        }
        monitor.onInternetStatusChanged = { reachable, overEthernet in
            internet.append("\(reachable ? "up" : "down")\(overEthernet ? "/eth" : "")")
        }
        for (satisfied, ethernet, probe) in steps {
            monitor.simulate(pathSatisfied: satisfied, overEthernet: ethernet, probeSucceeded: probe)
            RunLoop.main.run(until: Date().addingTimeInterval(0.02))
        }
        check(name, wired == expectWired && internet == expectInternet,
              "wired=\(wired) internet=\(internet)")
    }

    let isp = NetworkMonitor.ispOutageCause
    let link = NetworkMonitor.linkLostCause

    print("=== Ethernet outage self-test ===")
    scenario("Ethernet-only Mac, ISP outage → one Ethernet outage, internet change not re-alerted",
             [(true, true, true), (true, true, false), (true, true, true)],
             expectWired: ["lost(\(isp))", "restored"], expectInternet: ["down/eth", "up/eth"])
    scenario("Ethernet-only Mac, cable pulled and replugged → link-lost outage",
             [(true, true, true), (false, false, false), (true, true, true)],
             expectWired: ["lost(\(link))", "restored"], expectInternet: ["down/eth", "up/eth"])
    scenario("Laptop undocked onto working WiFi → no outage; later WiFi ISP outage is WiFi's",
             [(true, true, true), (true, false, true), (true, false, false), (true, false, true)],
             expectWired: [], expectInternet: ["down", "up"])
    scenario("WiFi-only Mac → Ethernet never tracked",
             [(true, false, true), (true, false, false), (true, false, true)],
             expectWired: [], expectInternet: ["down", "up"])
    scenario("Ethernet outage ended by WiFi taking over → closes once, then WiFi owns later drops",
             [(true, true, true), (false, false, false), (true, false, true), (true, false, false)],
             expectWired: ["lost(\(link))", "restored"], expectInternet: ["down/eth", "up/eth", "down"])
    scenario("Launch during an Ethernet outage → no outage invented, tracking starts once online",
             [(true, true, false), (true, true, true), (true, true, false)],
             expectWired: ["lost(\(isp))"], expectInternet: ["down", "up", "down/eth"])

    // Pairing: overlapping WiFi and Ethernet outages must pair per connection.
    let t0 = Date(timeIntervalSince1970: 1_800_000_000)
    func ev(_ type: WiFiEventType, wired: Bool, at seconds: TimeInterval) -> WiFiEvent {
        WiFiEvent(type: type,
                  ssid: wired ? WiFiEvent.wiredNetworkName : "Home",
                  bssid: wired ? WiFiEvent.wiredMarker : "aa:bb:cc:dd:ee:ff",
                  timestamp: t0.addingTimeInterval(seconds))
    }
    let pairs = WiFiEvent.outagePairs([
        ev(.disconnected, wired: false, at: 0),
        ev(.disconnected, wired: true, at: 10),
        ev(.connected, wired: false, at: 20),
        ev(.connected, wired: true, at: 50),
        ev(.disconnected, wired: true, at: 60),
    ])
    let summary = pairs.map { p -> String in
        let end = p.up.map { "\(Int($0.timestamp.timeIntervalSince(t0)))" } ?? "open"
        return "\(p.down.ssid ?? "?"):\(Int(p.down.timestamp.timeIntervalSince(t0)))-\(end)"
    }
    check("Overlapping WiFi and Ethernet outages pair per connection",
          summary == ["Home:0-20", "Ethernet:10-50", "Ethernet:60-open"], "\(summary)")

    let wifiOnly = WiFiEvent.outagePairs([
        ev(.disconnected, wired: false, at: 0),
        ev(.disconnected, wired: false, at: 5),
        ev(.connected, wired: false, at: 30),
        ev(.connected, wired: false, at: 40),
    ]).map { "\(Int($0.down.timestamp.timeIntervalSince(t0)))-\($0.up.map { "\(Int($0.timestamp.timeIntervalSince(t0)))" } ?? "open")" }
    check("WiFi-only history pairs exactly as before (later disconnect replaces earlier)",
          wifiOnly == ["5-30"], "\(wifiOnly)")

    print(failures == 0 ? "ALL PASS ✅" : "\(failures) FAILURE(S) ❌")
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
