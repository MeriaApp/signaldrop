import AppKit
import SwiftUI

/// Owns the "Network Insights" window: scanner table + live signal graph
/// + connection-history report. Standard menu-bar-app pattern — opens a
/// real NSWindow when the user clicks the menu item, drops back to
/// .accessory when closed.
///
/// Sample collection runs ONLY while the window is open. Closing the
/// window stops the 1 Hz polling timer immediately.
final class NetworkInsightsController: NSObject {
    private var window: NSWindow?
    private let scanner = NetworkScanner()
    private let sampleStore = SignalSampleStore()
    private var model: NetworkInsightsModel!
    private var historyModel: ConnectionHistoryModel!
    private let getCurrentState: () -> WiFiState

    init(
        eventLog: EventLog,
        getCurrentState: @escaping () -> WiFiState
    ) {
        self.getCurrentState = getCurrentState
        super.init()
        self.model = NetworkInsightsModel(
            scanner: scanner,
            sampleStore: sampleStore,
            getCurrentState: getCurrentState
        )
        let historyService = ConnectionHistoryService(eventLog: eventLog)
        self.historyModel = ConnectionHistoryModel(service: historyService)
        self.historyModel.onExportPDF = { [weak self] report in
            self?.exportPDF(report: report)
        }
        // Outage drill-in's "Show in Signal Graph" button flips the
        // window's selected tab. The timestamp is passed through in
        // case the Signal Graph eventually supports time-range pre-
        // scroll (the audit's full §2.7 wish — for now we just swap
        // the tab and let the user see the most recent data).
        self.historyModel.onJumpToSignalGraph = { [weak self] _ in
            self?.model.selectedTab = .signal
        }
    }

    func show() {
        guard window == nil else {
            window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = NetworkInsightsView(model: model, historyModel: historyModel)
        let hosting = NSHostingController(rootView: view)

        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 880, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        win.title = "Network Insights"
        win.titlebarAppearsTransparent = true
        win.toolbarStyle = .unified
        win.contentViewController = hosting
        win.center()
        win.isReleasedWhenClosed = false
        win.delegate = self

        window = win

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        win.makeKeyAndOrderFront(nil)

        // Kick off the first scan + start graph sampling immediately so
        // both tabs have content when the user first inspects them. The
        // history tab pulls from the EventLog on demand — no warm-up
        // needed.
        model.startScan()
        model.startGraphSampling()
        historyModel.refresh()
    }

    // MARK: - PDF Export

    private func exportPDF(report: ConnectionHistoryReport) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.pdf]
        savePanel.nameFieldStringValue = defaultPDFFilename(for: report)
        savePanel.canCreateDirectories = true
        savePanel.title = "Export Connection Report"
        savePanel.message = "Save the connection report as a PDF you can send to your ISP."

        guard let win = window else { return }

        savePanel.beginSheetModal(for: win) { response in
            guard response == .OK, let url = savePanel.url else { return }
            // beginSheetModal completion fires on the main thread; assert it
            // explicitly so the @MainActor renderer is callable without a hop.
            let success = MainActor.assumeIsolated {
                renderHistoryReportPDF(report, to: url)
            }
            if !success {
                let alert = NSAlert()
                alert.messageText = "Couldn't save the PDF"
                alert.informativeText = "SignalDrop couldn't write to \(url.lastPathComponent). Try a different location."
                alert.alertStyle = .warning
                alert.addButton(withTitle: "OK")
                alert.runModal()
                return
            }
            // Reveal in Finder so the user sees what they just produced.
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }

    private func defaultPDFFilename(for report: ConnectionHistoryReport) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        let date = f.string(from: report.periodEnd)
        let suffix: String
        switch report.period {
        case .h24: suffix = "24h"
        case .d7:  suffix = "7d"
        case .d30: suffix = "30d"
        }
        return "SignalDrop Receipt — \(suffix) — \(date).pdf"
    }

    private func finish() {
        guard let w = window else { return }
        window = nil
        // Stop sampling BEFORE the window tears down so the timer doesn't
        // outlive the controller.
        model.stopGraphSampling()
        w.close()
        NSApp.setActivationPolicy(.accessory)
    }
}

extension NetworkInsightsController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // Two paths: user clicked red close button (we still own `window`),
        // or finish() set window=nil then called close() (short-circuit).
        // Don't call finish() from here — that would re-enter close().
        guard window != nil else { return }
        window = nil
        model.stopGraphSampling()
        NSApp.setActivationPolicy(.accessory)
    }
}
