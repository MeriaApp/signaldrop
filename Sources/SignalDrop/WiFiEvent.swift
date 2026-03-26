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

    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: timestamp)
    }

    var displayString: String {
        switch type {
        case .connected:
            return "Connected to \(ssid ?? "Unknown")"
        case .disconnected:
            return "Disconnected\(ssid.map { " from \($0)" } ?? "")"
        case .ssidChanged:
            return "Switched to \(ssid ?? "Unknown")"
        case .signalDegraded:
            return "Signal weak (\(rssi ?? 0) dBm)"
        case .signalRecovered:
            return "Signal recovered (\(rssi ?? 0) dBm)"
        case .internetLost:
            return "Internet unreachable"
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
