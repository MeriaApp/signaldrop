import SwiftUI

/// The third tab of the Network Insights window: a visual report of
/// connection reliability over a user-selectable period (24h / 7d / 30d).
///
/// Same data model also feeds the PDF export, so the in-app view and the
/// downloadable receipt can't drift from each other.
struct ConnectionHistoryView: View {
    @ObservedObject var model: ConnectionHistoryModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Picker("", selection: $model.period) {
                    Text("24h").tag(HistoryPeriod.h24)
                    Text("7d").tag(HistoryPeriod.d7)
                    Text("30d").tag(HistoryPeriod.d30)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 200)

                Spacer()

                Button {
                    model.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .controlSize(.small)
                .help("Refresh the report")

                Button {
                    model.exportPDF()
                } label: {
                    Label("Export PDF…", systemImage: "square.and.arrow.up")
                }
                .controlSize(.small)
                .keyboardShortcut("e", modifiers: .command)
                .help("Export this report as a PDF (⌘E)")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HistorySummaryCard(report: model.report)
                    HistoryTimelineStrip(report: model.report)
                    HistoryPerNetworkSection(report: model.report)
                    HistoryOutagesSection(report: model.report)
                }
                .padding(16)
            }
        }
    }
}

// MARK: - Summary card

struct HistorySummaryCard: View {
    let report: ConnectionHistoryReport

    var body: some View {
        HStack(alignment: .center, spacing: 24) {
            VStack(spacing: 2) {
                Text(report.grade.rawValue)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(gradeColor)
                Text(report.grade.description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 150)

            Divider().frame(height: 70)

            HStack(spacing: 28) {
                HistoryStat(value: String(format: "%.2f%%", report.uptimePercent), label: "Uptime")
                HistoryStat(value: "\(report.outageCount)", label: report.outageCount == 1 ? "Outage" : "Outages")
                HistoryStat(value: historyFormatDuration(report.totalDowntimeSeconds), label: "Total down")
                HistoryStat(value: report.longestOutageSeconds > 0 ? historyFormatDuration(report.longestOutageSeconds) : "—", label: "Longest")
            }

            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }

    private var gradeColor: Color {
        switch report.grade {
        case .excellent, .good: return .green
        case .fair:             return .yellow
        case .poor:             return .orange
        case .terrible:         return .red
        }
    }
}

private struct HistoryStat: View {
    let value: String
    let label: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}

// MARK: - Timeline strip

struct HistoryTimelineStrip: View {
    let report: ConnectionHistoryReport

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Timeline")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                HStack(spacing: 10) {
                    LegendDot(color: .green,  label: "100%")
                    LegendDot(color: .yellow, label: "≥95%")
                    LegendDot(color: .orange, label: "≥80%")
                    LegendDot(color: .red,    label: "<80%")
                }
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            }

            HStack(spacing: 2) {
                ForEach(report.buckets) { b in
                    Rectangle()
                        .fill(colorFor(b))
                        .frame(maxWidth: .infinity, minHeight: 30, maxHeight: 30)
                        .help(tooltipFor(b))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 4))

            HStack {
                Text(historyFormatEdgeLabel(report.periodStart, period: report.period))
                Spacer()
                Text("now")
            }
            .font(.system(size: 10))
            .foregroundColor(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }

    private func colorFor(_ b: HistoryBucket) -> Color {
        // No outage starts AND no overlap = "no data either way" — color
        // by uptime calc but at 100%-equivalent it's green.
        let up = b.uptimePercent
        if up >= 99.5 { return .green }
        if up >= 95   { return .yellow }
        if up >= 80   { return .orange }
        return .red
    }

    private func tooltipFor(_ b: HistoryBucket) -> String {
        let pct = String(format: "%.1f%%", b.uptimePercent)
        let when = historyFormatBucketRange(b.start, b.end, period: report.period)
        if b.outageCount == 0 {
            return "\(when) — \(pct) up"
        }
        return "\(when) — \(pct) up, \(b.outageCount) outage\(b.outageCount == 1 ? "" : "s")"
    }
}

private struct LegendDot: View {
    let color: Color
    let label: String
    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label)
        }
    }
}

// MARK: - Per-network breakdown

struct HistoryPerNetworkSection: View {
    let report: ConnectionHistoryReport

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Per network")
                    .font(.system(size: 13, weight: .semibold))
                Text("\(report.perNetwork.count)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(Color.secondary.opacity(0.15)))
            }

            if report.perNetwork.isEmpty {
                Text("No network activity in this period.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 0) {
                    ForEach(report.perNetwork) { net in
                        PerNetworkRow(network: net)
                        if net.id != report.perNetwork.last?.id {
                            Divider().opacity(0.3)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
}

private struct PerNetworkRow: View {
    let network: NetworkSummary

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 14))
                .foregroundColor(iconColor)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 1) {
                Text(network.ssid)
                    .font(.system(size: 13, weight: .medium))
                Text(verdict)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if network.disconnects > 0 {
                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(network.disconnects) drop\(network.disconnects == 1 ? "" : "s")")
                        .font(.system(size: 12, design: .monospaced))
                    Text(historyFormatDuration(network.totalDowntimeSeconds) + " down")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            } else {
                Text("rock solid")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 8)
    }

    private var iconName: String {
        switch network.disconnects {
        case 0:       return "checkmark.circle.fill"
        case 1...2:   return "wifi"
        case 3...5:   return "wifi.exclamationmark"
        default:      return "wifi.slash"
        }
    }

    private var iconColor: Color {
        switch network.disconnects {
        case 0:       return .green
        case 1...2:   return .secondary
        case 3...5:   return .orange
        default:      return .red
        }
    }

    private var verdict: String {
        if network.disconnects == 0 {
            return "No drops in this period"
        }
        let avg = historyFormatDuration(network.averageOutageSeconds)
        let longest = historyFormatDuration(network.longestOutageSeconds)
        return "avg \(avg) · longest \(longest)"
    }
}

// MARK: - Outages list

struct HistoryOutagesSection: View {
    let report: ConnectionHistoryReport

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Outages")
                    .font(.system(size: 13, weight: .semibold))
                Text("\(report.outageCount)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(
                        Capsule().fill(Color.secondary.opacity(0.15))
                    )
            }

            if report.outages.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.green)
                    Text("No disconnects in this period.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                Table(report.outages) {
                    TableColumn("When") { row in
                        Text(historyFormatTimestamp(row.start))
                            .font(.system(size: 12, design: .monospaced))
                    }
                    .width(min: 130, ideal: 150)

                    TableColumn("Duration") { row in
                        Text(historyFormatDuration(row.durationSeconds))
                            .font(.system(size: 12, design: .monospaced))
                    }
                    .width(min: 70, ideal: 90)

                    TableColumn("Network") { row in
                        Text(row.ssid ?? "—")
                            .font(.system(size: 12))
                    }
                    .width(min: 120, ideal: 160)

                    TableColumn("Likely cause") { row in
                        Text(row.cause ?? "—")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(minHeight: 180, idealHeight: 260)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
}

// MARK: - View model

/// Owns the selected period + the freshly-computed report. The window
/// holds the service; this model recomputes whenever the user changes
/// period or hits refresh. PDF export is delegated to the controller
/// (it owns the NSSavePanel + render-to-URL pipeline).
final class ConnectionHistoryModel: ObservableObject {
    @Published var period: HistoryPeriod = .h24 {
        didSet { recompute() }
    }
    @Published private(set) var report: ConnectionHistoryReport

    private let service: ConnectionHistoryService

    /// Set by the controller. Invoked when the user taps "Export PDF…".
    var onExportPDF: ((ConnectionHistoryReport) -> Void)?

    init(service: ConnectionHistoryService) {
        self.service = service
        self.report = service.report(for: .h24)
    }

    func refresh() {
        report = service.report(for: period)
    }

    private func recompute() {
        report = service.report(for: period)
    }

    func exportPDF() {
        onExportPDF?(report)
    }
}

// MARK: - Shared formatters (internal — also used by ConnectionHistoryPDF.swift)

/// Distinct from ConnectionQuality's file-private formatter — that one is
/// scoped to its own file. This one is intentionally module-visible so
/// the PDF view can reuse it without duplication.
func historyFormatDuration(_ s: TimeInterval) -> String {
    if s < 1 { return "<1s" }
    if s < 60 { return "\(Int(s))s" }
    if s < 3600 {
        let m = Int(s) / 60
        let sec = Int(s) % 60
        return sec > 0 ? "\(m)m \(sec)s" : "\(m)m"
    }
    if s < 86_400 {
        let h = Int(s) / 3600
        let m = (Int(s) % 3600) / 60
        return m > 0 ? "\(h)h \(m)m" : "\(h)h"
    }
    let d = Int(s) / 86_400
    let h = (Int(s) % 86_400) / 3600
    return h > 0 ? "\(d)d \(h)h" : "\(d)d"
}

func historyFormatTimestamp(_ d: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "MMM d, h:mm a"
    return f.string(from: d)
}

func historyFormatBucketRange(_ start: Date, _ end: Date, period: HistoryPeriod) -> String {
    let f = DateFormatter()
    switch period {
    case .h24:
        f.dateFormat = "h:mm a"
    case .d7:
        f.dateFormat = "EEE h a"
    case .d30:
        f.dateFormat = "MMM d"
    }
    return "\(f.string(from: start)) – \(f.string(from: end))"
}

func historyFormatEdgeLabel(_ d: Date, period: HistoryPeriod) -> String {
    let f = DateFormatter()
    switch period {
    case .h24: f.dateFormat = "h:mm a"
    case .d7:  f.dateFormat = "EEE MMM d"
    case .d30: f.dateFormat = "MMM d"
    }
    return f.string(from: d)
}
