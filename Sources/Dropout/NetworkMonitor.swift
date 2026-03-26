import Foundation
import Network

final class NetworkMonitor {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.dropout.network")

    private(set) var isInternetReachable = true
    private(set) var interfaceType: NWInterface.InterfaceType = .wifi

    var onInternetStatusChanged: ((Bool) -> Void)?

    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let reachable = path.status == .satisfied
            let wasReachable = self.isInternetReachable
            self.isInternetReachable = reachable

            if let wifi = path.availableInterfaces.first(where: { $0.type == .wifi }) {
                self.interfaceType = wifi.type
            }

            if reachable != wasReachable {
                DispatchQueue.main.async {
                    self.onInternetStatusChanged?(reachable)
                }
            }
        }
        monitor.start(queue: queue)
    }

    func stop() {
        monitor.cancel()
    }
}
