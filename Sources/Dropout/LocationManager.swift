import CoreLocation

final class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    var onAuthorizationChanged: ((Bool) -> Void)?

    var isAuthorized: Bool {
        switch manager.authorizationStatus {
        case .authorizedAlways:
            return true
        default:
            return false
        }
    }

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestAuthorization() {
        // macOS requires "Always" for background/agent apps (LSUIElement)
        manager.requestAlwaysAuthorization()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        onAuthorizationChanged?(isAuthorized)
    }
}
