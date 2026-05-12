import SwiftUI
import Charts

/// Top-level view shown in the "Nearby Networks" window. Two-tab layout:
///   - Scanner: a sortable table of nearby WiFi networks with signal bars,
///     channel, security, and band.
///   - Signal: a live line graph of the connected network's RSSI, noise,
///     and transmit rate over the past five minutes.
struct NetworkInsightsView: View {
    @ObservedObject var model: NetworkInsightsModel
    @State private var selectedTab: Tab = .scanner

    enum Tab: String, CaseIterable, Identifiable {
        case scanner = "Nearby networks"
        case signal = "Signal graph"
        var id: String { rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom tab bar — looks more Apple-grade than the default Picker(.segmented).
            HStack(spacing: 4) {
                ForEach(Tab.allCases) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: .medium))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 7)
                                    .fill(selectedTab == tab ? Color.accentColor.opacity(0.18) : Color.clear)
                            )
                            .foregroundColor(selectedTab == tab ? .primary : .secondary)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                Button {
                    model.startScan()
                } label: {
                    HStack(spacing: 6) {
                        if model.isScanning {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text(model.isScanning ? "Scanning…" : "Rescan")
                    }
                }
                .disabled(model.isScanning)
                .controlSize(.small)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial)
            .overlay(Rectangle().frame(height: 1).foregroundColor(Color.gray.opacity(0.15)), alignment: .bottom)

            Group {
                switch selectedTab {
                case .scanner: NearbyNetworksList(model: model)
                case .signal:  SignalGraphPane(model: model)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 760, minHeight: 460)
    }
}

// MARK: - Scanner tab

private struct NearbyNetworksList: View {
    @ObservedObject var model: NetworkInsightsModel

    var body: some View {
        if model.networks.isEmpty {
            EmptyScanState(model: model)
        } else {
            Table(model.networks) {
                TableColumn("Network") { net in
                    HStack(spacing: 8) {
                        SignalBars(rssi: net.rssi)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(net.ssid ?? "(hidden network)")
                                .font(.system(size: 13, weight: net.ssid == model.connectedSSID ? .semibold : .regular))
                                .foregroundColor(net.ssid == model.connectedSSID ? .accentColor : .primary)
                            Text(net.bssid)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .width(min: 200, ideal: 260)

                TableColumn("Signal") { net in
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(net.rssi) dBm")
                            .font(.system(size: 12, design: .monospaced))
                        Text("SNR \(net.snr) dB")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                .width(min: 70, ideal: 80)

                TableColumn("Band") { net in
                    Text(net.channelBand.rawValue)
                        .font(.system(size: 12))
                }
                .width(min: 60, ideal: 70)

                TableColumn("Channel") { net in
                    Text("\(net.channel) · \(net.channelWidth) MHz")
                        .font(.system(size: 12, design: .monospaced))
                }
                .width(min: 90, ideal: 110)

                TableColumn("Security") { net in
                    HStack(spacing: 4) {
                        Image(systemName: net.security.isSecure ? "lock.fill" : "lock.open")
                            .font(.system(size: 10))
                            .foregroundColor(net.security.isSecure ? .secondary : .orange)
                        Text(net.security.rawValue)
                            .font(.system(size: 12))
                    }
                }
                .width(min: 90, ideal: 120)
            }
            .padding(.horizontal, 8)
        }
    }
}

private struct EmptyScanState: View {
    @ObservedObject var model: NetworkInsightsModel
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: model.scanError != nil ? "wifi.exclamationmark" : "wifi")
                .font(.system(size: 36))
                .foregroundColor(.secondary)
            if let err = model.scanError {
                Text(err)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 380)
            } else if model.isScanning {
                Text("Scanning nearby networks…")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            } else {
                Text("Click Rescan to discover nearby WiFi networks.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct SignalBars: View {
    let rssi: Int
    var body: some View {
        // Map dBm to 0..4 bars.
        // -50+ excellent (4), -65..-50 good (3), -75..-65 fair (2),
        // -85..-75 weak (1), below -85 (0).
        let bars: Int = {
            switch rssi {
            case _ where rssi >= -50: return 4
            case -65..<(-50): return 3
            case -75..<(-65): return 2
            case -85..<(-75): return 1
            default: return 0
            }
        }()
        let color: Color = {
            switch bars {
            case 4, 3: return .green
            case 2: return .yellow
            case 1: return .orange
            default: return .red
            }
        }()
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(1...4, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(i <= bars ? color : Color.gray.opacity(0.25))
                    .frame(width: 4, height: CGFloat(i) * 3 + 4)
            }
        }
    }
}

// MARK: - Signal graph tab

private struct SignalGraphPane: View {
    @ObservedObject var model: NetworkInsightsModel
    @State private var visibleSeries: Set<String> = ["RSSI", "Noise"]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Legend / toggles
            HStack(spacing: 16) {
                ForEach(["RSSI", "Noise", "TX rate"], id: \.self) { name in
                    Button {
                        if visibleSeries.contains(name) {
                            visibleSeries.remove(name)
                        } else {
                            visibleSeries.insert(name)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(colorFor(name))
                                .frame(width: 8, height: 8)
                                .opacity(visibleSeries.contains(name) ? 1 : 0.3)
                            Text(name)
                                .font(.system(size: 12))
                                .foregroundColor(visibleSeries.contains(name) ? .primary : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                if let ssid = model.connectedSSID {
                    Text(ssid)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            if model.samples.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "waveform")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                    Text("Collecting signal data…")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Chart {
                    if visibleSeries.contains("RSSI") {
                        ForEach(model.samples) { s in
                            LineMark(
                                x: .value("Time", s.timestamp),
                                y: .value("dBm", s.rssi),
                                series: .value("Series", "RSSI")
                            )
                            .foregroundStyle(colorFor("RSSI"))
                            .interpolationMethod(.monotone)
                        }
                    }
                    if visibleSeries.contains("Noise") {
                        ForEach(model.samples) { s in
                            LineMark(
                                x: .value("Time", s.timestamp),
                                y: .value("dBm", s.noise),
                                series: .value("Series", "Noise")
                            )
                            .foregroundStyle(colorFor("Noise"))
                            .interpolationMethod(.monotone)
                        }
                    }
                    if visibleSeries.contains("TX rate") {
                        // Map TX rate (Mbps) into the dBm range so it shares the axis visually.
                        // 0-2000 Mbps maps roughly to -100..0 dBm range via /20.
                        ForEach(model.samples) { s in
                            LineMark(
                                x: .value("Time", s.timestamp),
                                y: .value("dBm-scaled", -100 + Int(s.transmitRate / 20)),
                                series: .value("Series", "TX rate")
                            )
                            .foregroundStyle(colorFor("TX rate"))
                            .interpolationMethod(.monotone)
                        }
                    }
                }
                .chartYScale(domain: -100...(-20))
                .chartYAxis {
                    AxisMarks(values: [-100, -80, -60, -40, -20]) { v in
                        AxisGridLine()
                        AxisValueLabel {
                            if let n = v.as(Int.self) {
                                Text("\(n) dBm").font(.system(size: 9))
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { v in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.hour().minute())
                    }
                }
                .padding(16)
            }
        }
    }

    private func colorFor(_ name: String) -> Color {
        switch name {
        case "RSSI": return .green
        case "Noise": return .red
        case "TX rate": return .blue
        default: return .gray
        }
    }
}

// MARK: - View model (ObservableObject)

/// Bridges the AppKit/CoreWLAN-side scanner + sample store to the
/// SwiftUI views. Owned by NetworkInsightsController.
final class NetworkInsightsModel: ObservableObject {
    @Published var networks: [ScannedNetwork] = []
    @Published var samples: [SignalSample] = []
    @Published var connectedSSID: String?
    @Published var isScanning: Bool = false
    @Published var scanError: String?

    private let scanner: NetworkScanner
    private let sampleStore: SignalSampleStore
    private let getCurrentState: () -> WiFiState

    init(scanner: NetworkScanner, sampleStore: SignalSampleStore, getCurrentState: @escaping () -> WiFiState) {
        self.scanner = scanner
        self.sampleStore = sampleStore
        self.getCurrentState = getCurrentState

        scanner.onScanComplete = { [weak self] in
            guard let self else { return }
            self.networks = self.scanner.lastResults
            self.scanError = self.scanner.lastScanError
            self.isScanning = false
        }
        sampleStore.onSampleAdded = { [weak self] _ in
            guard let self else { return }
            self.samples = self.sampleStore.allSamples
        }
        // Capture initial state for the table header.
        connectedSSID = getCurrentState().ssid
        samples = sampleStore.allSamples
    }

    func startScan() {
        isScanning = true
        scanError = nil
        scanner.scan()
    }

    func startGraphSampling() {
        sampleStore.start()
        connectedSSID = getCurrentState().ssid
    }

    func stopGraphSampling() {
        sampleStore.stop()
    }
}
