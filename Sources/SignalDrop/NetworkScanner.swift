import Foundation
import CoreWLAN

// MARK: - Models

/// A WiFi network discovered by a scan. Snapshot at scan time — does not
/// auto-update; re-run the scan to refresh.
struct ScannedNetwork: Identifiable, Hashable {
    /// BSSID (router MAC). Stable per access point; the right identity key
    /// when the same SSID is broadcast by multiple APs (mesh, enterprise).
    let bssid: String
    let ssid: String?
    let rssi: Int                  // dBm. -30 excellent → -90+ unusable
    let noise: Int                 // dBm noise floor
    let channel: Int
    let channelBand: ChannelBand
    let channelWidth: Int          // 20 / 40 / 80 / 160 / 320 MHz
    let security: Security
    let countryCode: String?

    var id: String { bssid }

    /// Signal-to-noise ratio in dB. Higher is better. Below ~10 dB is poor.
    var snr: Int { rssi - noise }

    var signalQuality: SignalQuality { SignalQuality.from(rssi: rssi) }

    enum ChannelBand: String {
        case band2_4GHz = "2.4 GHz"
        case band5GHz = "5 GHz"
        case band6GHz = "6 GHz"
        case unknown = "?"

        static func from(channel: Int) -> ChannelBand {
            switch channel {
            case 1...14: return .band2_4GHz
            case 36...177: return .band5GHz   // 5 GHz UNII bands
            case 1...233 where channel >= 1: return .band6GHz  // 6 GHz Wi-Fi 6E
            default: return .unknown
            }
        }
    }

    enum Security: String {
        case none = "Open"
        case wep = "WEP"
        case wpaPersonal = "WPA"
        case wpa2Personal = "WPA2"
        case wpa3Personal = "WPA3"
        case wpaEnterprise = "WPA Enterprise"
        case wpa2Enterprise = "WPA2 Enterprise"
        case wpa3Enterprise = "WPA3 Enterprise"
        case enterprise = "Enterprise"
        case unknown = "?"

        static func from(_ network: CWNetwork) -> Security {
            if network.supportsSecurity(.none) { return .none }
            if network.supportsSecurity(.WEP) { return .wep }
            if network.supportsSecurity(.wpa3Personal) { return .wpa3Personal }
            if network.supportsSecurity(.wpa3Enterprise) { return .wpa3Enterprise }
            if network.supportsSecurity(.wpa2Personal) { return .wpa2Personal }
            if network.supportsSecurity(.wpa2Enterprise) { return .wpa2Enterprise }
            if network.supportsSecurity(.personal) { return .wpaPersonal }
            if network.supportsSecurity(.enterprise) { return .wpaEnterprise }
            if network.supportsSecurity(.dynamicWEP) { return .wep }
            return .unknown
        }

        var isSecure: Bool { self != .none && self != .wep }
    }
}

// MARK: - Scanner

/// Scans for nearby WiFi networks via CoreWLAN. The scan call is synchronous
/// and blocks the calling thread for ~2-3 seconds, so we always dispatch off
/// the main queue and deliver results back on main.
///
/// Works in the Mac App Store sandbox given the existing entitlements
/// (com.apple.developer.networking.wifi-info + Location Services).
final class NetworkScanner {
    private let client = CWWiFiClient.shared()
    private let scanQueue = DispatchQueue(label: "com.signaldrop.scanner", qos: .userInitiated)

    /// Most recent scan result, kept in memory between scans.
    private(set) var lastResults: [ScannedNetwork] = []
    private(set) var lastScanDate: Date?
    private(set) var lastScanError: String?
    private(set) var isScanning: Bool = false

    /// Fires on main thread when scan finishes (success or failure).
    var onScanComplete: (() -> Void)?

    /// Trigger a scan. Returns immediately; observe via `onScanComplete` or
    /// poll `lastResults` after the callback fires. Multiple concurrent
    /// calls are coalesced — only one scan runs at a time.
    func scan() {
        if isScanning { return }
        isScanning = true

        scanQueue.async { [weak self] in
            guard let self else { return }
            let result = self.performScan()
            DispatchQueue.main.async {
                self.lastResults = result.networks
                self.lastScanDate = Date()
                self.lastScanError = result.error
                self.isScanning = false
                self.onScanComplete?()
            }
        }
    }

    private struct ScanResult {
        let networks: [ScannedNetwork]
        let error: String?
    }

    private func performScan() -> ScanResult {
        guard let iface = client.interface() else {
            return ScanResult(networks: [], error: "No WiFi interface available")
        }
        guard iface.powerOn() else {
            return ScanResult(networks: [], error: "WiFi is turned off")
        }

        do {
            // `scanForNetworks(withSSID: nil)` returns all nearby APs.
            // Blocking call; takes ~2-3 seconds. We're on a background queue.
            let networks = try iface.scanForNetworks(withSSID: nil)
            let scanned = networks
                .map(makeScannedNetwork)
                // Sort by signal strength descending (strongest first).
                .sorted { $0.rssi > $1.rssi }
            return ScanResult(networks: scanned, error: nil)
        } catch {
            return ScanResult(networks: [], error: error.localizedDescription)
        }
    }

    private func makeScannedNetwork(from net: CWNetwork) -> ScannedNetwork {
        let channelNum = net.wlanChannel?.channelNumber ?? 0
        let widthRaw = net.wlanChannel?.channelWidth ?? .width20MHz
        let width: Int = {
            switch widthRaw {
            case .width20MHz: return 20
            case .width40MHz: return 40
            case .width80MHz: return 80
            case .width160MHz: return 160
            default: return 20
            }
        }()

        return ScannedNetwork(
            bssid: net.bssid ?? "unknown-\(UUID().uuidString.prefix(8))",
            ssid: net.ssid,
            rssi: net.rssiValue,
            noise: net.noiseMeasurement,
            channel: channelNum,
            channelBand: ScannedNetwork.ChannelBand.from(channel: channelNum),
            channelWidth: width,
            security: ScannedNetwork.Security.from(net),
            countryCode: net.countryCode
        )
    }
}
