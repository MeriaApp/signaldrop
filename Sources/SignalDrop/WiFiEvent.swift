import Foundation

enum WiFiEventType: String, Codable {
    case connected
    case disconnected
    case ssidChanged
    case signalDegraded
    case signalRecovered
    case internetLost
    case internetRestored
    case powerOn
    case powerOff
}

struct WiFiEvent {
    let id: Int64?
    let timestamp: Date
    let type: WiFiEventType
    let ssid: String?
    let bssid: String?
    let rssi: Int?
    let transmitRate: Double?
    let details: String?

    init(
        type: WiFiEventType,
        ssid: String? = nil,
        bssid: String? = nil,
        rssi: Int? = nil,
        transmitRate: Double? = nil,
        details: String? = nil,
        id: Int64? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.ssid = ssid
        self.bssid = bssid
        self.rssi = rssi
        self.transmitRate = transmitRate
        self.details = details
    }

    /// Wired outages are stored as disconnect/connect pairs on a network named
    /// "Ethernet", so History, the grade and the receipt count them like WiFi
    /// drops. The BSSID column carries a marker no real access point can have.
    static let wiredNetworkName = "Ethernet"
    static let wiredMarker = "wired"

    var isWired: Bool { bssid == Self.wiredMarker }

    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: timestamp)
    }

    var displayString: String {
        switch type {
        case .connected where isWired:
            return "Ethernet back online"
        case .disconnected where isWired:
            return details.map { "Ethernet offline \u{2014} \($0)" } ?? "Ethernet offline"
        case .connected:
            return "Connected to \(ssid ?? "Unknown")"
        case .disconnected:
            let base = "Disconnected\(ssid.map { " from \($0)" } ?? "")"
            return details.map { "\(base) — \($0)" } ?? base
        case .ssidChanged:
            return "Switched to \(ssid ?? "Unknown")"
        case .signalDegraded:
            return "Signal weak (\(rssi ?? 0) dBm)"
        case .signalRecovered:
            return "Signal recovered (\(rssi ?? 0) dBm)"
        case .internetLost:
            return details.map { "Internet unreachable — \($0)" } ?? "Internet unreachable"
        case .internetRestored:
            return "Internet restored"
        case .powerOn:
            return "WiFi turned on"
        case .powerOff:
            return "WiFi turned off"
        }
    }

    var symbolName: String {
        switch type {
        case .connected, .signalRecovered, .internetRestored, .powerOn:
            return "checkmark.circle.fill"
        case .disconnected, .internetLost, .powerOff:
            return "xmark.circle.fill"
        case .ssidChanged:
            return "arrow.triangle.swap"
        case .signalDegraded:
            return "exclamationmark.triangle.fill"
        }
    }

    var isNegative: Bool {
        switch type {
        case .disconnected, .signalDegraded, .internetLost, .powerOff:
            return true
        case .connected, .signalRecovered, .internetRestored, .powerOn, .ssidChanged:
            return false
        }
    }
}

/// A disconnect and the reconnect that ended it. `up` is nil while the outage
/// is still open.
struct OutagePair {
    let down: WiFiEvent
    let up: WiFiEvent?
}

extension WiFiEvent {
    /// Pairs each disconnect with the next reconnect on the same kind of
    /// connection, so a WiFi reconnect can't close an Ethernet outage or the
    /// reverse. A second disconnect before any reconnect replaces the first.
    static func outagePairs(_ events: [WiFiEvent]) -> [OutagePair] {
        var pairs: [OutagePair] = []
        var open: [Bool: WiFiEvent] = [:]
        for event in events.sorted(by: { $0.timestamp < $1.timestamp }) {
            switch event.type {
            case .disconnected:
                open[event.isWired] = event
            case .connected:
                if let down = open.removeValue(forKey: event.isWired) {
                    pairs.append(OutagePair(down: down, up: event))
                }
            default:
                break
            }
        }
        pairs += open.values.map { OutagePair(down: $0, up: nil) }
        return pairs.sorted { $0.down.timestamp < $1.down.timestamp }
    }
}
