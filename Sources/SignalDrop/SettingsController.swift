import AppKit
import SwiftUI

/// Owns the Notification Settings window. Standard menu-bar-app pattern —
/// .accessory while closed, .regular while open so the window can take
/// keyboard focus.
final class SettingsController: NSObject {
    private var window: NSWindow?
    private let settings: NotificationSettings
    /// Wired by `SignalDropApp` so the "Send test notification" button
    /// in `SettingsView` can fire a real macOS notification through the
    /// existing `NotificationService` pipeline (same code path real
    /// disconnects use, so sound/quiet-hours/etc. settings are honored).
    var onTestNotification: (() -> Void)?

    init(settings: NotificationSettings) {
        self.settings = settings
        super.init()
    }

    func show() {
        guard window == nil else {
            window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = SettingsView(
            settings: settings,
            onTestNotification: { [weak self] in self?.onTestNotification?() }
        )
        let hosting = NSHostingController(rootView: view)

        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 760),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        win.title = "Notification Settings"
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
    }
}

extension SettingsController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard window != nil else { return }
        window = nil
        NSApp.setActivationPolicy(.accessory)
    }
}
