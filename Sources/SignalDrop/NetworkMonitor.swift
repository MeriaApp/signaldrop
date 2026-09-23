import Foundation
import Network

/// Reports whether the internet actually answers, not just whether a route exists.
///
/// `NWPathMonitor` only knows the Mac has a usable interface and gateway: a router
/// whose ISP link is down, or a captive portal, still yields a satisfied path. So
/// while the path is satisfied, reachability is confirmed with a small request to
/// Apple's captive-portal check, the same endpoint macOS itself uses. The request
/// carries no user data.
final class NetworkMonitor {
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
    /// Non-nil when the satisfied path is NOT routed over WiFi — i.e. Bluetooth
    /// tether, USB Personal Hotspot, Ethernet, or cellular. Used so the menu
    /// header can distinguish "Connected to <SSID>" from "Online via Tether
    /// while WiFi is off." Nil whenever the active path uses WiFi or the path
    /// is unsatisfied.
    private(set) var activeNonWifiLabel: String?

    var onInternetStatusChanged: ((Bool) -> Void)?
    var onActiveInterfaceChanged: ((String?) -> Void)?

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
        guard reachable != isInternetReachable else { return }
        isInternetReachable = reachable
        DispatchQueue.main.async {
            self.onInternetStatusChanged?(reachable)
        }
    }

    private static func nonWifiLabel(for path: NWPath) -> String? {
        guard path.status == .satisfied else { return nil }
        if path.usesInterfaceType(.wifi) { return nil }
        if path.usesInterfaceType(.cellular) { return "Cellular" }
        // Bluetooth PAN and USB Personal Hotspot both surface as wiredEthernet.
        if path.usesInterfaceType(.wiredEthernet) { return "Ethernet or Tether" }
        if path.usesInterfaceType(.other) { return "Tether" }
        return "another network"
    }
}
