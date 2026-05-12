import AppKit
import SwiftUI

/// Paper-laid-out version of the Connection History report. Reused by
/// the PDF export pipeline so the downloadable file is visually faithful
/// to what the user sees in the History tab.
///
/// Sized for US Letter portrait (612pt wide). Height grows to fit content;
/// the renderer emits a single tall PDF page. Most PDF viewers will
/// print this across multiple letter pages when needed.
struct ConnectionHistoryPDFView: View {
    let report: ConnectionHistoryReport
    let generatedAt: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            Divider()
            HistorySummaryCard(report: report)
            HistoryTimelineStrip(report: report)
            HistoryPerNetworkSection(report: report)
            outagesSection
            footer
        }
        .padding(36)
        .frame(width: 612, alignment: .topLeading)
        .background(Color.white)
        .environment(\.colorScheme, .light)
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center, spacing: 10) {
                if let appIcon = loadAppIcon() {
                    Image(nsImage: appIcon)
                        .resizable()
                        .interpolation(.high)
                        .frame(width: 28, height: 28)
                }
                Text("SignalDrop")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                Spacer()
                Text("Connection Report")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
            Text("\(formatLongDate(report.periodStart)) → \(formatLongDate(report.periodEnd))")
                .font(.system(size: 11))
                .foregroundColor(.gray)
            Text("\(machineName()) · macOS \(osVersion())")
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
    }

    /// Pulls the app icon from the running bundle so the PDF receipt
    /// shows a branded wordmark instead of plain text. The bundle's
    /// `Resources/AppIcon.icns` is loadable via NSImage. Returns nil
    /// when running in unusual contexts (unit tests, etc.); the header
    /// falls back to text-only.
    private func loadAppIcon() -> NSImage? {
        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let img = NSImage(contentsOf: url) {
            return img
        }
        // Fallback path: NSApp icon (matches the running app's icon
        // even if AppIcon.icns isn't a discoverable resource).
        return NSApp?.applicationIconImage
    }

    private var outagesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Outages")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.black)
                Text("\(report.outageCount)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.gray)
            }

            if report.outages.isEmpty {
                Text("No disconnects in this period.")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                    .padding(.vertical, 12)
            } else {
                outageTable
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(white: 0.97))
        )
    }

    /// Lay outages out as a plain VStack of rows (SwiftUI `Table` doesn't
    /// render reliably through `ImageRenderer` since it bridges to NSTableView).
    /// Cap at 40 rows so the PDF stays a reasonable length — if a user has
    /// >40 outages in a window, they should be sending the CSV anyway.
    private var outageTable: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("When").pdfTableHeader().frame(width: 140, alignment: .leading)
                Text("Duration").pdfTableHeader().frame(width: 80, alignment: .leading)
                Text("Network").pdfTableHeader().frame(width: 140, alignment: .leading)
                Text("Likely cause").pdfTableHeader()
                Spacer(minLength: 0)
            }
            .padding(.vertical, 6)
            Divider()

            ForEach(Array(report.outages.prefix(40))) { row in
                HStack(alignment: .firstTextBaseline) {
                    Text(historyFormatTimestamp(row.start))
                        .pdfTableCell(monospaced: true)
                        .frame(width: 140, alignment: .leading)
                    Text(historyFormatDuration(row.durationSeconds))
                        .pdfTableCell(monospaced: true)
                        .frame(width: 80, alignment: .leading)
                    Text(row.ssid ?? "—")
                        .pdfTableCell()
                        .frame(width: 140, alignment: .leading)
                    Text(row.cause ?? "—")
                        .pdfTableCell()
                        .foregroundColor(.gray)
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 4)
                Divider().opacity(0.4)
            }

            if report.outages.count > 40 {
                Text("…and \(report.outages.count - 40) earlier outage\(report.outages.count - 40 == 1 ? "" : "s"). Export CSV from the menu for the full log.")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                    .padding(.top, 8)
            }
        }
    }

    private var footer: some View {
        HStack {
            Text("Generated by SignalDrop · signaldrop.app")
                .font(.system(size: 9))
                .foregroundColor(.gray)
            Spacer()
            Text(formatGeneratedAt(generatedAt))
                .font(.system(size: 9))
                .foregroundColor(.gray)
        }
        .padding(.top, 8)
    }
}

// MARK: - PDF rendering

/// Renders a SwiftUI view to a single-page PDF at the given URL.
/// Returns true on success. Caller is responsible for showing an error
/// alert if false comes back.
@MainActor
func renderHistoryReportPDF(_ report: ConnectionHistoryReport, to url: URL) -> Bool {
    let view = ConnectionHistoryPDFView(report: report, generatedAt: Date())
    let renderer = ImageRenderer(content: view)
    renderer.proposedSize = ProposedViewSize(width: 612, height: nil)

    var success = true
    renderer.render { size, drawIntoContext in
        var box = CGRect(origin: .zero, size: size)
        guard let consumer = CGDataConsumer(url: url as CFURL),
              let pdfContext = CGContext(consumer: consumer, mediaBox: &box, nil) else {
            success = false
            return
        }
        pdfContext.beginPDFPage(nil)
        drawIntoContext(pdfContext)
        pdfContext.endPDFPage()
        pdfContext.closePDF()
    }
    return success
}

// MARK: - Helpers

private extension View {
    func pdfTableHeader() -> some View {
        self
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.gray)
            .textCase(.uppercase)
    }

    func pdfTableCell(monospaced: Bool = false) -> some View {
        self
            .font(.system(size: 11, design: monospaced ? .monospaced : .default))
            .foregroundColor(.black)
    }
}

private func formatLongDate(_ d: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "MMM d, yyyy h:mm a"
    return f.string(from: d)
}

private func formatGeneratedAt(_ d: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "MMM d, yyyy 'at' h:mm a"
    return f.string(from: d)
}

private func machineName() -> String {
    var size = 0
    sysctlbyname("hw.model", nil, &size, nil, 0)
    var bytes = [CChar](repeating: 0, count: size)
    sysctlbyname("hw.model", &bytes, &size, nil, 0)
    let hwModel = String(cString: bytes)
    if hwModel.hasPrefix("MacBookPro") { return "MacBook Pro" }
    if hwModel.hasPrefix("MacBookAir") { return "MacBook Air" }
    if hwModel.hasPrefix("MacBook")    { return "MacBook" }
    if hwModel.hasPrefix("iMac")       { return "iMac" }
    if hwModel.hasPrefix("Macmini")    { return "Mac mini" }
    if hwModel.hasPrefix("MacStudio")  { return "Mac Studio" }
    if hwModel.hasPrefix("MacPro")     { return "Mac Pro" }
    return hwModel.isEmpty ? "Mac" : hwModel
}

private func osVersion() -> String {
    let v = ProcessInfo.processInfo.operatingSystemVersion
    return "\(v.majorVersion).\(v.minorVersion)"
}
