import SwiftUI
import Charts

/// Top-level view shown in the "Network Insights" window. Three-tab layout:
///   - Scanner: a sortable table of nearby WiFi networks with signal bars,
///     channel, security, and band.
///   - Signal:  a live line graph of the connected network's RSSI, noise,
///     and transmit rate over the past five minutes.
///   - History: a visual report of connection reliability over the past
///     24h / 7d / 30d, with an Export PDF button.
struct NetworkInsightsView: View {
    @ObservedObject var model: NetworkInsightsModel
    @ObservedObject var historyModel: ConnectionHistoryModel
    @State private var selectedTab: Tab = .scanner

    enum Tab: String, CaseIterable, Identifiable {
        case scanner = "Nearby networks"
        case signal  = "Signal graph"
        case history = "Connection history"
        var id: String { rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom tab bar — looks more Apple-grade than the default Picker(.segmented).
            HStack(spacing: 4) {
                ForEach(Array(Tab.allCases.enumerated()), id: \.element) { idx, tab in
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
                    .keyboardShortcut(KeyEquivalent(Character("\(idx + 1)")), modifiers: .command)
                }
                Spacer()
                // Rescan only applies to the Scanner tab.
                if selectedTab == .scanner {
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
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial)
            .overlay(Rectangle().frame(height: 1).foregroundColor(Color.gray.opacity(0.15)), alignment: .bottom)

            Group {
                switch selectedTab {
                case .scanner: NearbyNetworksList(model: model)
                case .signal:  SignalGraphPane(model: model)
                case .history: ConnectionHistoryView(model: historyModel)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 820, minHeight: 540)
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
                            HStack(spacing: 6) {
                                Text(net.bssid)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.secondary)
                                if let vendor = OUILookup.vendor(for: net.bssid) {
                                    Text("·")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary.opacity(0.6))
                                    Text(vendor)
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                }
                .width(min: 220, ideal: 300)

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
            // While scanning, the `wifi` glyph pulses its variable-color
            // arcs in sequence so the user can read "active scan in
            // progress" at a glance — same motion Apple uses for the
            // Wi-Fi indicator during connection. Static glyph for the
            // error / idle states.
            symbolView
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

    @ViewBuilder
    private var symbolView: some View {
        let name = model.scanError != nil ? "wifi.exclamationmark" : "wifi"
        let image = Image(systemName: name)
        if #available(macOS 14.0, *), model.isScanning, model.scanError == nil {
            image.symbolEffect(.variableColor.iterative, options: .repeating)
        } else {
            image
        }
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
    @State private var hoverSample: SignalSample?

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
                stackedCharts
                    .padding(.leading, 36)
                    .padding(.trailing, 16)
                    .padding(.vertical, 16)
            }
        }
    }

    /// dBm chart on top + TX-rate chart below when toggled visible. Two
    /// independent `Chart` views share the same X domain so their time
    /// axes align column-for-column — same pattern Apple Stocks uses
    /// for price + volume. Single-axis fakery (mapping Mbps onto dBm)
    /// produced visually misleading lines; this layout is honest.
    @ViewBuilder
    private var stackedCharts: some View {
        let showTX = visibleSeries.contains("TX rate")
        let xDomain = sharedXDomain
        VStack(spacing: 8) {
            dBmChart(xDomain: xDomain, hideXAxis: showTX)
                .frame(maxHeight: .infinity)
            if showTX {
                txRateChart(xDomain: xDomain)
                    .frame(height: 90)
            }
        }
    }

    /// Top chart: RSSI + Noise on a dBm axis. X axis is hidden when the
    /// TX-rate chart is also visible so the time labels appear only on
    /// the bottom chart (Apple Stocks pattern).
    @ViewBuilder
    private func dBmChart(xDomain: ClosedRange<Date>, hideXAxis: Bool) -> some View {
        let domain = yDomain
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
            if let s = hoverSample {
                RuleMark(x: .value("Time", s.timestamp))
                    .foregroundStyle(Color.secondary.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                if visibleSeries.contains("RSSI") {
                    PointMark(
                        x: .value("Time", s.timestamp),
                        y: .value("dBm", s.rssi)
                    )
                    .foregroundStyle(colorFor("RSSI"))
                    .symbolSize(48)
                }
                if visibleSeries.contains("Noise") {
                    PointMark(
                        x: .value("Time", s.timestamp),
                        y: .value("dBm", s.noise)
                    )
                    .foregroundStyle(colorFor("Noise"))
                    .symbolSize(48)
                }
            }
        }
        .chartXScale(domain: xDomain)
        .chartYScale(domain: domain)
        .chartYAxis {
            AxisMarks(position: .leading, values: yAxisValues(for: domain)) { v in
                AxisGridLine()
                AxisValueLabel {
                    if let n = v.as(Int.self) {
                        Text("\(n)").font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .chartXAxis {
            if hideXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                    AxisGridLine()
                }
            } else {
                AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.hour().minute().second())
                }
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .onContinuousHover { phase in
                        switch phase {
                        case .active(let location):
                            hoverSample = sampleNearest(to: location, in: geo, proxy: proxy)
                        case .ended:
                            hoverSample = nil
                        }
                    }
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                if let s = hoverSample {
                    let plot = geo[proxy.plotAreaFrame]
                    let xPos = proxy.position(forX: s.timestamp) ?? 0
                    HoverAnnotation(sample: s)
                        .position(
                            x: plot.origin.x + min(max(xPos, 70), plot.width - 70),
                            y: plot.origin.y + 38
                        )
                }
            }
        }
    }

    /// Bottom chart: TX rate on its own Mbps axis. Shown only when the
    /// legend toggle includes TX rate. Compact (~90pt) and inherits the
    /// same time domain as the dBm chart so the two read as one unit.
    @ViewBuilder
    private func txRateChart(xDomain: ClosedRange<Date>) -> some View {
        let txDomain = txRateDomain
        Chart {
            ForEach(model.samples) { s in
                LineMark(
                    x: .value("Time", s.timestamp),
                    y: .value("Mbps", s.transmitRate),
                    series: .value("Series", "TX rate")
                )
                .foregroundStyle(colorFor("TX rate"))
                .interpolationMethod(.monotone)
            }
            if let s = hoverSample {
                RuleMark(x: .value("Time", s.timestamp))
                    .foregroundStyle(Color.secondary.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                PointMark(
                    x: .value("Time", s.timestamp),
                    y: .value("Mbps", s.transmitRate)
                )
                .foregroundStyle(colorFor("TX rate"))
                .symbolSize(32)
            }
        }
        .chartXScale(domain: xDomain)
        .chartYScale(domain: txDomain)
        .chartYAxis {
            AxisMarks(position: .leading, values: txAxisValues(for: txDomain)) { v in
                AxisGridLine()
                AxisValueLabel {
                    if let n = v.as(Double.self) {
                        Text("\(Int(n))")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour().minute().second())
            }
        }
        // Subtle separator above the TX row so the eye reads it as a
        // distinct panel rather than an axis tail of the dBm chart.
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.secondary.opacity(0.12))
                .frame(height: 1)
        }
    }

    /// Shared X-axis time domain so the dBm and TX-rate charts line up
    /// column-for-column. Width is the full sample window the store has
    /// buffered; falls back to "last 5 minutes ending now" when samples
    /// are missing on either end (typical at first launch).
    private var sharedXDomain: ClosedRange<Date> {
        if let first = model.samples.first?.timestamp,
           let last = model.samples.last?.timestamp,
           first < last {
            return first ... last
        }
        let now = Date()
        return now.addingTimeInterval(-300) ... now
    }

    /// TX-rate Y-axis domain. Floor at 0 (Mbps can't be negative), pad
    /// the top by ~10% so the line never hugs the chart edge. Snap the
    /// upper bound to a clean round number (50 / 100 / 200 / 500 / 1000)
    /// so the tick labels read as natural Wi-Fi link rates.
    private var txRateDomain: ClosedRange<Double> {
        let maxRate = model.samples.map(\.transmitRate).max() ?? 0
        guard maxRate > 0 else { return 0 ... 100 }
        let padded = maxRate * 1.1
        let rounded: Double
        switch padded {
        case ..<60:    rounded = 60
        case ..<120:   rounded = 120
        case ..<240:   rounded = 240
        case ..<540:   rounded = 540
        case ..<1100:  rounded = 1100
        case ..<2200:  rounded = 2200
        default:       rounded = (padded / 500.0).rounded(.up) * 500
        }
        return 0 ... rounded
    }

    /// Three ticks for the TX-rate axis: 0, midpoint, max. Compact
    /// enough to fit the ~90pt-tall TX chart without crowding.
    private func txAxisValues(for domain: ClosedRange<Double>) -> [Double] {
        [domain.lowerBound, (domain.upperBound / 2), domain.upperBound]
    }

    /// Y-axis domain derived from visible samples. Pads the data range and
    /// rounds to nearest 10 dBm for clean tick marks. Falls back to the
    /// classic -100..-20 range when there's no data to read.
    private var yDomain: ClosedRange<Int> {
        guard !model.samples.isEmpty else { return -100 ... -20 }
        var lo = Int.max
        var hi = Int.min
        if visibleSeries.contains("RSSI") {
            for s in model.samples {
                if s.rssi < lo { lo = s.rssi }
                if s.rssi > hi { hi = s.rssi }
            }
        }
        if visibleSeries.contains("Noise") {
            for s in model.samples {
                if s.noise < lo { lo = s.noise }
                if s.noise > hi { hi = s.noise }
            }
        }
        guard lo != Int.max else { return -100 ... -20 }
        // Pad 10 dBm each side, snap to nearest 10, never let the span
        // collapse below 20 dBm (otherwise a near-flat trace looks jittery).
        let lower = Int((Double(lo - 10) / 10.0).rounded(.down)) * 10
        let upper = Int((Double(hi + 10) / 10.0).rounded(.up)) * 10
        let snapped = lower ... max(upper, lower + 20)
        // Clamp to physical signal range so a corrupt sample doesn't
        // stretch the scale into nonsense.
        let clampedLo = max(snapped.lowerBound, -110)
        let clampedHi = min(snapped.upperBound, 0)
        return clampedLo ... max(clampedHi, clampedLo + 20)
    }

    private func yAxisValues(for domain: ClosedRange<Int>) -> [Int] {
        let span = domain.upperBound - domain.lowerBound
        // Aim for 4–6 ticks. Step rounded to nearest 5 to keep clean labels.
        let raw = Double(span) / 5.0
        let step = max(5, Int((raw / 5.0).rounded()) * 5)
        var v = (domain.lowerBound / step) * step
        if v < domain.lowerBound { v += step }
        var ticks: [Int] = []
        while v <= domain.upperBound {
            ticks.append(v)
            v += step
        }
        return ticks
    }

    private func sampleNearest(to location: CGPoint, in geo: GeometryProxy, proxy: ChartProxy) -> SignalSample? {
        guard !model.samples.isEmpty else { return nil }
        let plot = geo[proxy.plotAreaFrame]
        let xInPlot = location.x - plot.origin.x
        guard xInPlot >= 0, xInPlot <= plot.width else { return nil }
        guard let hovered: Date = proxy.value(atX: xInPlot) else { return nil }
        return model.samples.min(by: { lhs, rhs in
            abs(lhs.timestamp.timeIntervalSince(hovered)) < abs(rhs.timestamp.timeIntervalSince(hovered))
        })
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

/// Floating annotation shown next to the cursor while hovering the signal
/// graph. Mirrors the Apple Stocks / Health pattern: timestamp on top, key
/// metrics below in monospaced columns.
private struct HoverAnnotation: View {
    let sample: SignalSample

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(timeFormatter.string(from: sample.timestamp))
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(.secondary)
            Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 2) {
                row(label: "RSSI", value: "\(sample.rssi) dBm", color: .green)
                row(label: "Noise", value: "\(sample.noise) dBm", color: .red)
                row(label: "SNR", value: "\(sample.snr) dB", color: .secondary)
                if sample.transmitRate > 0 {
                    row(label: "TX", value: "\(Int(sample.transmitRate)) Mbps", color: .blue)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.regularMaterial)
                .shadow(color: Color.black.opacity(0.12), radius: 6, y: 2)
        )
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func row(label: String, value: String, color: Color) -> some View {
        GridRow {
            HStack(spacing: 5) {
                Circle().fill(color).frame(width: 6, height: 6)
                Text(label).font(.system(size: 11)).foregroundColor(.secondary)
            }
            Text(value)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.primary)
        }
    }

    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "h:mm:ss a"
        return f
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
            // Refresh in case the user roamed networks since the window opened.
            self.connectedSSID = self.getCurrentState().ssid
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
