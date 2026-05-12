import AppKit
import SwiftUI

/// Owns the "Nearby Networks" window: scanner table + live signal graph.
/// Standard menu-bar-app pattern — opens a real NSWindow when the user
/// clicks the menu item, drops back to .accessory when closed.
///
/// Sample collection runs ONLY while the window is open. Closing the
/// window stops the 1 Hz polling timer immediately.
final class NetworkInsightsController: NSObject {
    private var window: NSWindow?
    private let scanner = NetworkScanner()
    private let sampleStore = SignalSampleStore()
    private var model: NetworkInsightsModel!
    private let getCurrentState: () -> WiFiState

    init(getCurrentState: @escaping () -> WiFiState) {
        self.getCurrentState = getCurrentState
        super.init()
        self.model = NetworkInsightsModel(
            scanner: scanner,
            sampleStore: sampleStore,
            getCurrentState: getCurrentState
        )
    }

    func show() {
        guard window == nil else {
            window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = NetworkInsightsView(model: model)
        let hosting = NSHostingController(rootView: view)

        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 840, height: 540),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        win.title = "Nearby Networks"
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
        // both tabs have content when the user first inspects them.
        model.startScan()
        model.startGraphSampling()
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
