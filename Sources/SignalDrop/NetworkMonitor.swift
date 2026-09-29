import Foundation
import Network
import SystemConfiguration

/// Reports whether the internet actually answers, not just whether a route exists.
///
/// `NWPathMonitor` only knows the Mac has a usable interface and gateway: a router
/// whose ISP link is down, or a captive portal, still yields a satisfied path. So
/// while the path is satisfied, reachability is confirmed with a small request to
/// Apple's captive-portal check, the same endpoint macOS itself uses. The request
/// carries no user data.
///
/// On a Mac whose internet runs over Ethernet, CoreWLAN reports nothing, so
/// wired outages are inferred here from the same path and check.
final class NetworkMonitor {
    /// A change in an Ethernet connection that was carrying the Mac's internet.
    enum WiredChange {
        case lost(cause: String)
        case restored
    }

    static let ethernetLabel = "Ethernet"
    static let ispOutageCause = "ISP outage suspected"
    static let linkLostCause = "Ethernet link lost"

    private enum Probe {
        static let url = URL(string: "https://captive.apple.com/hotspot-detect.html")!
        static let expectedBody = "Success"
        static let timeout: TimeInterval = 5
        /// Cadence while the internet answers.
        static let interval: TimeInterval = 30
        /// Cadence on a hotspot or in Low Data Mode, to keep data use down.
        static let meteredInterval: TimeInterval = 120
        /// Quick recheck after a single failure, before declaring an outage.
        static let retryInterval: TimeInterval = 5
        /// Cadence while offline, so recovery is noticed promptly.
        static let offlineInterval: TimeInterval = 10
        /// One lost request is noise; two in a row is an outage.
        static let failuresBeforeOffline = 2
        /// After wake, WiFi needs a few seconds to rejoin before a failure means anything.
        static let wakeGrace: TimeInterval = 10
    }

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.signaldrop.network")
    private let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        config.timeoutIntervalForRequest = Probe.timeout
        config.timeoutIntervalForResource = Probe.timeout
        config.waitsForConnectivity = false
        return URLSession(configuration: config)
    }()

    private(set) var isInternetReachable = true
    /// Non-nil when the satisfied path is NOT routed over WiFi — i.e. Ethernet,
    /// an iPhone or Bluetooth tether, or cellular. Used so the menu header can
    /// say "Online via Ethernet" instead of describing WiFi. Nil whenever the
    /// active path uses WiFi or the path is unsatisfied.
    private(set) var activeNonWifiLabel: String?

    /// `overEthernet` is true when the change is already reported as an
    /// Ethernet outage through `onWiredChange`, so it shouldn't be alerted twice.
    var onInternetStatusChanged: ((_ reachable: Bool, _ overEthernet: Bool) -> Void)?
    var onActiveInterfaceChanged: ((String?) -> Void)?
    var onWiredChange: ((WiredChange) -> Void)?

    // Probe state, touched only on `queue`.
    private var pathSatisfied = false
    private var pathMetered = false
    private var probeSucceeded = true
    private var consecutiveFailures = 0
    private var probeTimer: DispatchSourceTimer?
    private var isPausedForSleep = false
    /// Bumped on every path change so a probe started on the old path can't
    /// report into the new one.
    private var probeGeneration = 0

    // Ethernet outage state, touched only on `queue`.
    /// The last satisfied path ran over Ethernet (not a tether). Kept while the
    /// path is unsatisfied, since that's when a pulled cable shows.
    private var primaryIsEthernet = false
    /// Ethernet has carried the internet since the last baseline.
    private var ethernetTracked = false
    private var ethernetOutageOpen = false

    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.handlePathUpdate(path)
        }
        monitor.start(queue: queue)
    }

    func stop() {
        monitor.cancel()
        queue.async { [weak self] in
            self?.probeTimer?.cancel()
            self?.probeTimer = nil
        }
    }

    /// Call before the Mac sleeps. Background wakes during sleep bring the
    /// network up and down without the user, so nothing is judged until a full wake.
    func systemWillSleep() {
        queue.async { [weak self] in
            guard let self else { return }
            self.isPausedForSleep = true
            self.probeGeneration += 1
            self.probeTimer?.cancel()
            self.probeTimer = nil
        }
    }

    /// Call after the Mac fully wakes: the network needs a moment to come back
    /// before it's judged.
    func systemDidWake() {
        queue.async { [weak self] in
            guard let self else { return }
            self.isPausedForSleep = false
            self.probeGeneration += 1
            self.consecutiveFailures = 0
            self.probeSucceeded = true
            self.scheduleProbe(after: Probe.wakeGrace)
        }
    }

    private func handlePathUpdate(_ path: NWPath) {
        let label = Self.nonWifiLabel(for: path)
        if path.status == .satisfied {
            primaryIsEthernet = label == Self.ethernetLabel
        }
        let prevLabel = activeNonWifiLabel
        activeNonWifiLabel = label
        if label != prevLabel {
            DispatchQueue.main.async {
                self.onActiveInterfaceChanged?(label)
            }
        }

        pathSatisfied = path.status == .satisfied
        pathMetered = path.isExpensive || path.isConstrained
        probeGeneration += 1
        consecutiveFailures = 0
        // Assume a fresh path works until two probes say otherwise, so a
        // reconnect isn't reported as an outage while the first probe runs.
        probeSucceeded = true

        guard !isPausedForSleep else { return }

        if pathSatisfied {
            scheduleProbe(after: 0)
        } else {
            probeTimer?.cancel()
            probeTimer = nil
        }
        publishReachability()
    }

    private func scheduleProbe(after delay: TimeInterval) {
        probeTimer?.cancel()
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + delay)
        timer.setEventHandler { [weak self] in self?.runProbe() }
        probeTimer = timer
        timer.resume()
    }

    private func runProbe() {
        guard pathSatisfied else {
            publishReachability()
            return
        }
        let generation = probeGeneration
        var request = URLRequest(url: Probe.url)
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

        session.dataTask(with: request) { [weak self] data, response, _ in
            let status = (response as? HTTPURLResponse)?.statusCode
            let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
            let succeeded = status == 200 && body.contains(Probe.expectedBody)
            self?.queue.async {
                self?.handleProbeResult(succeeded, generation: generation)
            }
        }.resume()
    }

    private func handleProbeResult(_ succeeded: Bool, generation: Int) {
        guard generation == probeGeneration, pathSatisfied, !isPausedForSleep else { return }

        if succeeded {
            consecutiveFailures = 0
            probeSucceeded = true
            scheduleProbe(after: pathMetered ? Probe.meteredInterval : Probe.interval)
        } else {
            consecutiveFailures += 1
            if consecutiveFailures >= Probe.failuresBeforeOffline {
                probeSucceeded = false
                scheduleProbe(after: Probe.offlineInterval)
            } else {
                scheduleProbe(after: Probe.retryInterval)
            }
        }
        publishReachability()
    }

    private func publishReachability() {
        let reachable = pathSatisfied && probeSucceeded
        // Covered when Ethernet was already carrying the connection or an
        // Ethernet outage is open; tracking that only starts now covers nothing.
        let wasOverEthernet = ethernetTracked || ethernetOutageOpen
        evaluateEthernet(online: reachable)
        let overEthernet = wasOverEthernet || ethernetOutageOpen
        guard reachable != isInternetReachable else { return }
        isInternetReachable = reachable
        DispatchQueue.main.async {
            self.onInternetStatusChanged?(reachable, overEthernet)
        }
    }

    /// An Ethernet outage opens when the Mac loses the internet while Ethernet
    /// carries it, and closes when the Mac is back online. Switching to WiFi
    /// with the internet working (a laptop unplugged from its dock) isn't an
    /// outage; it just stops Ethernet tracking until Ethernet carries it again.
    private func evaluateEthernet(online: Bool) {
        if ethernetOutageOpen {
            guard online else { return }
            ethernetOutageOpen = false
            ethernetTracked = primaryIsEthernet
            publishWired(.restored)
        } else if ethernetTracked {
            if !online {
                ethernetOutageOpen = true
                publishWired(.lost(cause: pathSatisfied ? Self.ispOutageCause : Self.linkLostCause))
            } else if !primaryIsEthernet {
                ethernetTracked = false
            }
        } else if online && primaryIsEthernet {
            ethernetTracked = true
        }
    }

    #if DEBUG
    /// Drives the reachability and Ethernet logic without a real network,
    /// for `-ethernetSelfTest`. `overEthernet` is ignored while unsatisfied,
    /// as a real unsatisfied path carries no interface.
    func simulate(pathSatisfied satisfied: Bool, overEthernet: Bool, probeSucceeded succeeded: Bool) {
        queue.sync {
            if satisfied { primaryIsEthernet = overEthernet }
            pathSatisfied = satisfied
            probeSucceeded = succeeded
            publishReachability()
        }
    }
    #endif

    private func publishWired(_ change: WiredChange) {
        DispatchQueue.main.async {
            self.onWiredChange?(change)
        }
    }

    private static func nonWifiLabel(for path: NWPath) -> String? {
        guard path.status == .satisfied else { return nil }
        if path.usesInterfaceType(.wifi) { return nil }
        if path.usesInterfaceType(.cellular) { return "Cellular" }
        // Bluetooth PAN and USB Personal Hotspot both surface as wiredEthernet.
        if path.usesInterfaceType(.wiredEthernet) {
            guard let name = path.availableInterfaces.first(where: { $0.type == .wiredEthernet })?.name else {
                return ethernetLabel
            }
            return tetherName(bsdName: name) ?? ethernetLabel
        }
        if path.usesInterfaceType(.other) { return "Tether" }
        return "another network"
    }

    /// The system's name for a wired interface when it's a phone or Bluetooth
    /// tether ("iPhone USB", "Bluetooth PAN"); nil for real Ethernet, whose
    /// names vary too much ("Ethernet Adapter (en4)", "Thunderbolt 1") to show.
    private static func tetherName(bsdName: String) -> String? {
        guard let all = SCNetworkInterfaceCopyAll() as? [SCNetworkInterface],
              let iface = all.first(where: { SCNetworkInterfaceGetBSDName($0) as String? == bsdName }),
              let display = SCNetworkInterfaceGetLocalizedDisplayName(iface) as String? else {
            return nil
        }
        let tetherMarkers = ["iPhone", "iPad", "Bluetooth"]
        return tetherMarkers.contains(where: display.contains) ? display : nil
    }
}
