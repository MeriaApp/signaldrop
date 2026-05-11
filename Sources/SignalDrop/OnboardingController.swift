import AppKit
import SwiftUI
import CoreLocation
import UserNotifications

/// First-launch onboarding: a single window that walks the user through
/// what SignalDrop does, then sequences the Location and Notifications
/// permission prompts (one at a time, with context) before handing back
/// to the menu bar app.
///
/// macOS doesn't let us re-prompt for a denied permission, so each step
/// also includes a "Open System Settings" affordance for the denied case.
final class OnboardingController: NSObject {
    private var window: NSWindow?
    private var locationManager: CLLocationManager?

    var onComplete: (() -> Void)?

    func show() {
        guard window == nil else {
            window?.makeKeyAndOrderFront(nil)
            return
        }

        let rootView = OnboardingView(
            requestLocation: { [weak self] completion in
                self?.requestLocation(completion: completion)
            },
            requestNotifications: { completion in
                Self.requestNotifications(completion: completion)
            },
            openSettings: { kind in
                Self.openSystemSettings(for: kind)
            },
            onFinish: { [weak self] in
                self?.finish()
            }
        )

        let hosting = NSHostingController(rootView: rootView)

        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 420),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        win.title = ""
        win.titlebarAppearsTransparent = true
        win.titleVisibility = .hidden
        win.isMovableByWindowBackground = true
        win.center()
        win.contentViewController = hosting
        win.isReleasedWhenClosed = false
        win.delegate = self

        self.window = win

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        win.makeKeyAndOrderFront(nil)
    }

    private func finish() {
        // Set window=nil BEFORE calling close() so the windowWillClose
        // delegate short-circuits and we don't recurse back into finish().
        guard let w = window else { return }
        window = nil
        w.close()
        NSApp.setActivationPolicy(.accessory)
        onComplete?()
    }

    // MARK: - Permissions

    private func requestLocation(completion: @escaping (PermissionResult) -> Void) {
        let mgr = CLLocationManager()
        let delegate = LocationDelegate(completion: completion)
        mgr.delegate = delegate
        // Retain the delegate alongside the manager until the callback fires.
        objc_setAssociatedObject(mgr, &Self.delegateKey, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        self.locationManager = mgr

        switch mgr.authorizationStatus {
        case .notDetermined:
            mgr.requestAlwaysAuthorization()
        case .authorizedAlways, .authorized:
            completion(.granted)
        case .denied, .restricted:
            completion(.denied)
        @unknown default:
            completion(.denied)
        }
    }

    private static var delegateKey: UInt8 = 0

    private static func requestNotifications(completion: @escaping (PermissionResult) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    DispatchQueue.main.async {
                        completion(granted ? .granted : .denied)
                    }
                }
            case .authorized, .provisional, .ephemeral:
                DispatchQueue.main.async { completion(.granted) }
            case .denied:
                DispatchQueue.main.async { completion(.denied) }
            @unknown default:
                DispatchQueue.main.async { completion(.denied) }
            }
        }
    }

    enum PermissionKind { case location, notifications }

    private static func openSystemSettings(for kind: PermissionKind) {
        let urlString: String
        switch kind {
        case .location:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices"
        case .notifications:
            urlString = "x-apple.systempreferences:com.apple.preference.notifications"
        }
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}

extension OnboardingController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // Two paths reach here:
        //   1. User clicked the red close button — we still own `window`,
        //      so do the cleanup directly.
        //   2. finish() set window=nil and called close() — short-circuit.
        // Critically, we must NOT call finish() from here, because finish()
        // calls close() which re-triggers this delegate → stack overflow.
        guard window != nil else { return }
        window = nil
        NSApp.setActivationPolicy(.accessory)
        onComplete?()
    }
}

enum PermissionResult {
    case granted
    case denied
}

private final class LocationDelegate: NSObject, CLLocationManagerDelegate {
    private let completion: (PermissionResult) -> Void
    private var fired = false

    init(completion: @escaping (PermissionResult) -> Void) {
        self.completion = completion
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard !fired else { return }
        switch manager.authorizationStatus {
        case .notDetermined:
            return
        case .authorizedAlways, .authorized:
            fired = true
            completion(.granted)
        case .denied, .restricted:
            fired = true
            completion(.denied)
        @unknown default:
            fired = true
            completion(.denied)
        }
    }
}
