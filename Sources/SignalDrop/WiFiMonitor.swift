import Foundation
import CoreWLAN

// MARK: - WiFi State

struct WiFiState {
    let ssid: String?
    let bssid: String?
    let rssi: Int
    let transmitRate: Double
    let isConnected: Bool
    let isPoweredOn: Bool

    var signalQuality: SignalQuality {
        SignalQuality.from(rssi: rssi)
    }

    static let disconnected = WiFiState(
        ssid: nil, bssid: nil, rssi: 0, transmitRate: 0,
        isConnected: false, isPoweredOn: true
    )
}

enum SignalQuality: String {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case weak = "Weak"
    case none = "No Signal"

    static func from(rssi: Int) -> SignalQuality {
        switch rssi {
        case _ where rssi >= -50: return .excellent
        case -65 ..< -50: return .good
        case -75 ..< -65: return .fair
        case _ where rssi < -75 && rssi > -100: return .weak
        default: return .none
        }
    }
}

// MARK: - WiFi Monitor

final class WiFiMonitor: NSObject {
    private let client = CWWiFiClient.shared()
    private var previousSSID: String?
    private var previousRSSI: Int = 0
    private var wasConnected = false
    private var disconnectTime: Date?

    private let signalWarningThreshold = -75  // dBm
    private let signalRecoveryThreshold = -65 // dBm — hysteresis to avoid flapping
    private var signalDegraded = false

    /// Set the moment RSSI first drops below `signalWarningThreshold`. The
    /// `signalDegraded` event is only emitted once RSSI has been continuously
    /// below the threshold for `minSignalDegradedDurationSeconds`. A brief
    /// 1-second dip to -76 dBm shouldn't trigger a "Signal Weak" alert.
    private var signalDegradedFirstObservedAt: Date?

    /// User-controlled minimum continuous duration before a weak-signal
    /// event is emitted. Defaults to 10s; readable from UserDefaults so
    /// the monitor doesn't depend on NotificationSettings directly.
    private var minSignalDegradedDuration: TimeInterval {
        let v = UserDefaults.standard.object(forKey: "notify.minSignalDegradedDuration") as? Double
        return v ?? 10.0
    }

    private let monitoredEvents: [CWEventType] = [
        .linkDidChange,
        .ssidDidChange,
        .bssidDidChange,
        .linkQualityDidChange,
        .powerDidChange,
    ]

    // Callbacks
    var onEvent: ((WiFiEvent) -> Void)?
    var onStateChanged: ((WiFiState) -> Void)?

    /// Always dispatch state-change callbacks to main. CoreWLAN delegate
    /// methods don't guarantee main-thread invocation, and downstream
    /// consumers (MenuBarController.renderStatus) touch AppKit.
    private func emitStateChanged(_ state: WiFiState) {
        if Thread.isMainThread {
            onStateChanged?(state)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.onStateChanged?(state)
            }
        }
    }

    // MARK: - Lifecycle

    func start() {
        client.delegate = self
        installEventMonitors()

        // Capture initial state
        let state = currentState()
        wasConnected = state.isConnected
        previousSSID = state.ssid
        previousRSSI = state.rssi
        emitStateChanged(state)
    }

    /// Re-register CoreWLAN event monitoring. CWWiFiClient delegates can stop
    /// firing across sleep/wake and never recover on their own — call this from
    /// NSWorkspace.didWakeNotification to bring them back.
    func restartMonitoring() {
        do {
            try client.stopMonitoringAllEvents()
        } catch {
            print("signaldrop: stop-all failed during restart: \(error)")
        }
        client.delegate = self
        installEventMonitors()
        emitStateChanged(currentState())
    }

    func stop() {
        do {
            try client.stopMonitoringAllEvents()
        } catch {
            print("signaldrop: failed to stop monitoring: \(error)")
        }
    }

    func currentState() -> WiFiState {
        guard let iface = client.interface() else {
            return .disconnected
        }

        let powerOn = iface.powerOn()
        let ssid = iface.ssid()
        // `isConnected` requires BOTH a powered-on radio AND a non-nil SSID.
        // `ssid()` can return a stale or friendly-name string after the radio
        // is logically off, which would otherwise show "Connected to <SSID>"
        // when the user is actually offline or routed over a non-WiFi path.
        return WiFiState(
            ssid: ssid,
            bssid: iface.bssid(),
            rssi: iface.rssiValue(),
            transmitRate: iface.transmitRate(),
            isConnected: powerOn && ssid != nil,
            isPoweredOn: powerOn
        )
    }

    private func installEventMonitors() {
        for event in monitoredEvents {
            do {
                try client.startMonitoringEvent(with: event)
            } catch {
                print("signaldrop: failed to monitor \(event): \(error)")
            }
        }
    }

    #if !APPSTORE
    /// Disconnect from the current network without removing it from saved networks.
    /// macOS will then auto-join the next preferred saved network.
    /// Not available in App Store builds (sandbox blocks disassociate).
    func disconnectFromCurrentNetwork() {
        guard let iface = client.interface() else { return }
        iface.disassociate()
    }

    /// Cycle the WiFi interface: disconnect, brief pause, then macOS reconnects
    /// to the best available saved network automatically.
    func cycleConnection() {
        guard let iface = client.interface() else { return }
        let ssid = iface.ssid()
        iface.disassociate()
        print("signaldrop: disconnected from \(ssid ?? "unknown") — waiting for auto-rejoin")
    }
    #endif
}

// MARK: - CWEventDelegate

extension WiFiMonitor: CWEventDelegate {
    func linkDidChangeForWiFiInterface(withName interfaceName: String) {
        let state = currentState()
        let isConnected = state.isConnected

        if isConnected && !wasConnected {
            // Reconnected
            var details: String?
            if let disc = disconnectTime {
                let duration = Date().timeIntervalSince(disc)
                details = formatDuration(duration)
            }
            disconnectTime = nil

            let event = WiFiEvent(
                type: .connected,
                ssid: state.ssid,
                bssid: state.bssid,
                rssi: state.rssi,
                transmitRate: state.transmitRate,
                details: details
            )
            emit(event)
        } else if !isConnected && wasConnected {
            // Disconnected
            disconnectTime = Date()
            // Reset signal-degraded flag on disconnect so the next reconnect to
            // a strong network can produce fresh weak-signal warnings later.
            signalDegraded = false
            signalDegradedFirstObservedAt = nil
            let event = WiFiEvent(
                type: .disconnected,
                ssid: previousSSID,
                bssid: state.bssid
            )
            emit(event)
        }

        wasConnected = isConnected
        previousSSID = state.ssid
        emitStateChanged(state)
    }

    func ssidDidChangeForWiFiInterface(withName interfaceName: String) {
        let state = currentState()
        guard let newSSID = state.ssid else { return }

        // Only emit SSID change if we were already connected (not a fresh connect)
        if wasConnected, let oldSSID = previousSSID, oldSSID != newSSID {
            let event = WiFiEvent(
                type: .ssidChanged,
                ssid: newSSID,
                details: "from \(oldSSID)"
            )
            emit(event)
        }

        previousSSID = newSSID
        emitStateChanged(state)
    }

    func bssidDidChangeForWiFiInterface(withName interfaceName: String) {
        // BSSID changes (roaming) — update state silently
        let state = currentState()
        emitStateChanged(state)
    }

    func linkQualityDidChangeForWiFiInterface(
        withName interfaceName: String, rssi: Int, transmitRate: Double
    ) {
        let state = currentState()

        // Signal degradation: only emit once RSSI has been continuously
        // below the warning threshold for `minSignalDegradedDuration`. A
        // 1-second dip while roaming between APs would otherwise trigger
        // a "Signal Weak" notification every time.
        if !signalDegraded {
            if rssi <= signalWarningThreshold {
                let now = Date()
                if signalDegradedFirstObservedAt == nil {
                    signalDegradedFirstObservedAt = now
                }
                let elapsed = now.timeIntervalSince(signalDegradedFirstObservedAt ?? now)
                if elapsed >= minSignalDegradedDuration {
                    signalDegraded = true
                    signalDegradedFirstObservedAt = nil
                    let event = WiFiEvent(
                        type: .signalDegraded,
                        ssid: state.ssid,
                        rssi: rssi,
                        transmitRate: transmitRate
                    )
                    emit(event)
                }
            } else {
                // RSSI bounced back above the threshold before the duration
                // elapsed — reset the timer so the next sustained dip
                // starts a fresh countdown.
                signalDegradedFirstObservedAt = nil
            }
        } else if rssi >= signalRecoveryThreshold {
            signalDegraded = false
            signalDegradedFirstObservedAt = nil
            let event = WiFiEvent(
                type: .signalRecovered,
                ssid: state.ssid,
                rssi: rssi,
                transmitRate: transmitRate
            )
            emit(event)
        }

        previousRSSI = rssi
        emitStateChanged(state)
    }

    // MARK: - Helpers

    private func emit(_ event: WiFiEvent) {
        DispatchQueue.main.async { [weak self] in
            self?.onEvent?(event)
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        if seconds < 60 {
            return "\(Int(seconds))s offline"
        } else if seconds < 3600 {
            let mins = Int(seconds) / 60
            let secs = Int(seconds) % 60
            return secs > 0 ? "\(mins)m \(secs)s offline" : "\(mins)m offline"
        } else {
            let hours = Int(seconds) / 3600
            let mins = (Int(seconds) % 3600) / 60
            return mins > 0 ? "\(hours)h \(mins)m offline" : "\(hours)h offline"
        }
    }
}

// Separate extension to silence "nearly matches" warning for modeDidChange
extension WiFiMonitor {
    func powerDidChangeForWiFiInterface(withName interfaceName: String) {
        let state = currentState()
        let event = WiFiEvent(
            type: state.isPoweredOn ? .powerOn : .powerOff
        )
        emit(event)
        emitStateChanged(state)
    }
}
