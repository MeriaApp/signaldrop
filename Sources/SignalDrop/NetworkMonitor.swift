import Foundation
import Network

final class NetworkMonitor {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.signaldrop.network")

    private(set) var isInternetReachable = true
    /// Non-nil when the satisfied path is NOT routed over WiFi — i.e. Bluetooth
    /// tether, USB Personal Hotspot, Ethernet, or cellular. Used so the menu
    /// header can distinguish "Connected to <SSID>" from "Online via Tether
    /// while WiFi is off." Nil whenever the active path uses WiFi or the path
    /// is unsatisfied.
    private(set) var activeNonWifiLabel: String?

    var onInternetStatusChanged: ((Bool) -> Void)?
    var onActiveInterfaceChanged: ((String?) -> Void)?

    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let reachable = path.status == .satisfied
            let label = Self.nonWifiLabel(for: path)

            let wasReachable = self.isInternetReachable
            let prevLabel = self.activeNonWifiLabel

            self.isInternetReachable = reachable
            self.activeNonWifiLabel = label

            if reachable != wasReachable {
                DispatchQueue.main.async {
                    self.onInternetStatusChanged?(reachable)
                }
            }
            if label != prevLabel {
                DispatchQueue.main.async {
                    self.onActiveInterfaceChanged?(label)
                }
            }
        }
        monitor.start(queue: queue)
    }

    func stop() {
        monitor.cancel()
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
