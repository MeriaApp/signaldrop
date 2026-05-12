import AppKit
import ServiceManagement

final class MenuBarController {
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!

    // Menu item references
    private var statusMenuItem: NSMenuItem!
    private var signalMenuItem: NSMenuItem!
    private var internetMenuItem: NSMenuItem!
    private var qualityMenuItem: NSMenuItem!
    private var recentHeaderItem: NSMenuItem!
    private var statsMenuItem: NSMenuItem!
    private var reliabilityHeaderItem: NSMenuItem!
    private var loginToggle: NSMenuItem!
    private var recentEventItems: [NSMenuItem] = []
    private var reliabilityItems: [NSMenuItem] = []

    // Cached state so the header can be re-rendered from either a WiFi state
    // change or an active-interface change without re-passing both each time.
    private var lastWiFiState: WiFiState = .disconnected
    private var lastActiveNonWifiLabel: String?
    private var lastLocationAuthorized: Bool = true
    private var lastNotificationsAuthorized: Bool = true
    private var lastInternetReachable: Bool = true

    private var grantLocationMenuItem: NSMenuItem?
    private var notificationsDisabledMenuItem: NSMenuItem?

    #if !APPSTORE
    private var disconnectButton: NSMenuItem!
    private var autoDisconnectToggle: NSMenuItem!
    #endif

    // Callbacks
    var onExportLog: (() -> Void)?
    var onCopyReceipt: (() -> Void)?
    var onShowAbout: (() -> Void)?
    var onShowNetworkInsights: (() -> Void)?
    var onShowSettings: (() -> Void)?
    var onOpenLocationSettings: (() -> Void)?
    var onOpenNotificationSettings: (() -> Void)?
    var onQuit: (() -> Void)?

    #if !APPSTORE
    var onOpenHooksFolder: (() -> Void)?
    var onDisconnect: (() -> Void)?
    var onCheckForUpdates: (() -> Void)?
    #else
    var onOpenWiFiSettings: (() -> Void)?
    #endif

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "dot.radiowaves.left.and.right",
                accessibilityDescription: "SignalDrop — WiFi Monitor"
            )
        }

        menu = NSMenu()
        menu.autoenablesItems = false

        // ── Status Section ──
        statusMenuItem = NSMenuItem(title: "Checking...", action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)

        signalMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        signalMenuItem.isEnabled = false
        menu.addItem(signalMenuItem)

        internetMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        internetMenuItem.isEnabled = false
        menu.addItem(internetMenuItem)

        qualityMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        qualityMenuItem.isEnabled = false
        menu.addItem(qualityMenuItem)

        // Hint items — only visible when the matching permission is denied.
        grantLocationMenuItem = NSMenuItem(
            title: "Grant Location Access\u{2026}",
            action: #selector(openLocationSettingsAction(_:)),
            keyEquivalent: ""
        )
        grantLocationMenuItem?.target = self
        grantLocationMenuItem?.isHidden = true
        menu.addItem(grantLocationMenuItem!)

        notificationsDisabledMenuItem = NSMenuItem(
            title: "Notifications disabled — events won\u{2019}t alert",
            action: #selector(openLocationSettingsAction(_:)),  // wired below to notifications path
            keyEquivalent: ""
        )
        notificationsDisabledMenuItem?.target = self
        notificationsDisabledMenuItem?.isHidden = true
        notificationsDisabledMenuItem?.action = #selector(openNotificationSettingsAction(_:))
        menu.addItem(notificationsDisabledMenuItem!)

        #if !APPSTORE
        disconnectButton = NSMenuItem(
            title: "Disconnect from This Network",
            action: #selector(disconnectAction(_:)),
            keyEquivalent: "d"
        )
        disconnectButton.keyEquivalentModifierMask = .command
        disconnectButton.target = self
        menu.addItem(disconnectButton)
        #else
        let wifiSettingsBtn = NSMenuItem(
            title: "Open WiFi Settings...",
            action: #selector(openWiFiSettingsAction(_:)),
            keyEquivalent: "d"
        )
        wifiSettingsBtn.keyEquivalentModifierMask = .command
        wifiSettingsBtn.target = self
        menu.addItem(wifiSettingsBtn)
        #endif

        let insightsItem = NSMenuItem(
            title: "Network Insights\u{2026}",
            action: #selector(showNetworkInsightsAction(_:)),
            keyEquivalent: "n"
        )
        insightsItem.keyEquivalentModifierMask = .command
        insightsItem.target = self
        menu.addItem(insightsItem)

        let settingsItem = NSMenuItem(
            title: "Settings\u{2026}",
            action: #selector(showSettingsAction(_:)),
            keyEquivalent: ","
        )
        settingsItem.keyEquivalentModifierMask = .command
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        // ── Recent Events ──
        recentHeaderItem = sectionHeader("RECENT EVENTS")
        menu.addItem(recentHeaderItem)

        menu.addItem(NSMenuItem.separator())

        // ── Stats ──
        statsMenuItem = NSMenuItem(title: "No data yet", action: nil, keyEquivalent: "")
        statsMenuItem.isEnabled = false
        menu.addItem(statsMenuItem)

        menu.addItem(NSMenuItem.separator())

        // ── Network Reliability ──
        reliabilityHeaderItem = sectionHeader("NETWORK RELIABILITY")
        reliabilityHeaderItem.isHidden = true
        menu.addItem(reliabilityHeaderItem)

        menu.addItem(NSMenuItem.separator())

        // ── Preferences ──
        // Sound + per-event notification toggles live in the Settings window
        // (⌘,) — keeping duplicate menu toggles drifted out of sync with
        // @AppStorage and made the menu unnecessarily long.

        #if !APPSTORE
        autoDisconnectToggle = NSMenuItem(
            title: "Auto-Leave Dead Networks",
            action: #selector(toggleAutoDisconnect(_:)),
            keyEquivalent: ""
        )
        autoDisconnectToggle.target = self
        autoDisconnectToggle.state = UserDefaults.standard.bool(forKey: "autoDisconnectDeadNetworks") ? .on : .off
        menu.addItem(autoDisconnectToggle)
        #endif

        loginToggle = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLoginItem(_:)),
            keyEquivalent: ""
        )
        loginToggle.target = self
        loginToggle.state = isLoginItemEnabled() ? .on : .off
        menu.addItem(loginToggle)

        menu.addItem(NSMenuItem.separator())

        // ── Export ──
        let exportItem = NSMenuItem(
            title: "Export Log (CSV)...",
            action: #selector(exportLog(_:)),
            keyEquivalent: "e"
        )
        exportItem.keyEquivalentModifierMask = .command
        exportItem.target = self
        menu.addItem(exportItem)

        // The "Generate ISP Report…" PDF is now reachable via the Connection
        // History tab's Export PDF button (⌘E inside Network Insights), which
        // produces a richer report with per-network rollups and the timeline.

        let receiptItem = NSMenuItem(
            title: "Copy Receipt for Support",
            action: #selector(copyReceipt(_:)),
            keyEquivalent: "C"
        )
        receiptItem.keyEquivalentModifierMask = [NSEvent.ModifierFlags.command, .shift]
        receiptItem.target = self
        menu.addItem(receiptItem)

        #if !APPSTORE
        let hooksItem = NSMenuItem(
            title: "Event Hooks...",
            action: #selector(openHooksFolderAction(_:)),
            keyEquivalent: ""
        )
        hooksItem.target = self
        menu.addItem(hooksItem)
        #endif

        menu.addItem(NSMenuItem.separator())

        // ── Footer ──
        #if !APPSTORE
        let checkForUpdatesItem = NSMenuItem(
            title: "Check for Updates...",
            action: #selector(checkForUpdatesAction(_:)),
            keyEquivalent: ""
        )
        checkForUpdatesItem.target = self
        menu.addItem(checkForUpdatesItem)
        #endif

        let aboutItem = NSMenuItem(
            title: "About SignalDrop",
            action: #selector(showAboutAction(_:)),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)

        let quitItem = NSMenuItem(
            title: "Quit SignalDrop",
            action: #selector(quit(_:)),
            keyEquivalent: "q"
        )
        quitItem.keyEquivalentModifierMask = .command
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    // MARK: - State Updates

    func updateWiFiState(_ state: WiFiState) {
        lastWiFiState = state
        renderStatus()
    }

    func updateActiveNonWifiInterface(_ label: String?) {
        lastActiveNonWifiLabel = label
        renderStatus()
    }

    func updateLocationAuthorized(_ authorized: Bool) {
        lastLocationAuthorized = authorized
        renderStatus()
    }

    func updateNotificationsAuthorized(_ authorized: Bool) {
        lastNotificationsAuthorized = authorized
        renderStatus()
    }

    private func renderStatus() {
        let state = lastWiFiState
        let nonWifiLabel = lastActiveNonWifiLabel

        // When the radio is on and the path is satisfied via WiFi but
        // ssid() is nil AND Location is denied, we're in the "Apple won't
        // tell us the network name" state — surface it explicitly rather
        // than falsely showing "Disconnected."
        let locationGatedNameless = state.isPoweredOn
            && state.ssid == nil
            && nonWifiLabel == nil
            && !lastLocationAuthorized

        renderPermissionHints(locationGatedNameless: locationGatedNameless)

        if state.isConnected, let ssid = state.ssid {
            statusMenuItem.title = "Connected to \(ssid)"
            signalMenuItem.title = "Signal: \(state.signalQuality.rawValue) (\(state.rssi) dBm)"
            signalMenuItem.isHidden = false

            if !lastInternetReachable {
                // WiFi is up, internet is down. The router/captive-portal/ISP
                // situation deserves its own icon — Apple's WiFi menu shows
                // the same exclamation glyph in this state.
                statusItem.button?.image = NSImage(
                    systemSymbolName: "wifi.exclamationmark",
                    accessibilityDescription: "WiFi connected — internet unreachable"
                )
            } else {
                // Variable-value wifi symbol renders 0..4 "bars" by intensity.
                // Mapping uses the same dBm cutoffs as SignalQuality so the
                // menu bar matches the dropdown's "Signal: Good (-58 dBm)" line.
                statusItem.button?.image = NSImage(
                    systemSymbolName: "wifi",
                    variableValue: variableValueFor(rssi: state.rssi),
                    accessibilityDescription: "WiFi: \(state.signalQuality.rawValue) (\(state.rssi) dBm)"
                )
            }
        } else if locationGatedNameless {
            statusMenuItem.title = "WiFi on — network name hidden"
            // We have RSSI even without Location; show it so the user
            // sees the app is reading SOMETHING and the header isn't a lie.
            if state.rssi != 0 {
                signalMenuItem.title = "Signal: \(state.signalQuality.rawValue) (\(state.rssi) dBm)"
                signalMenuItem.isHidden = false
            } else {
                signalMenuItem.isHidden = true
            }
            statusItem.button?.image = NSImage(
                systemSymbolName: "lock.icloud",
                accessibilityDescription: "WiFi on — Location permission needed for network name"
            )
        } else if !state.isPoweredOn {
            statusMenuItem.title = nonWifiLabel.map { "WiFi Off — Online via \($0)" } ?? "WiFi Off"
            signalMenuItem.isHidden = true
            statusItem.button?.image = NSImage(
                systemSymbolName: "wifi.slash",
                accessibilityDescription: "WiFi Off"
            )
        } else if let label = nonWifiLabel {
            statusMenuItem.title = "Online via \(label) — WiFi idle"
            signalMenuItem.isHidden = true
            statusItem.button?.image = NSImage(
                systemSymbolName: "wifi.slash",
                accessibilityDescription: "WiFi Idle — Online via \(label)"
            )
        } else {
            statusMenuItem.title = "Disconnected"
            signalMenuItem.isHidden = true
            statusItem.button?.image = NSImage(
                systemSymbolName: "wifi.slash",
                accessibilityDescription: "WiFi Disconnected"
            )
        }
    }

    /// Map RSSI (dBm) onto the variable-value range SF Symbols expects for
    /// the `wifi` glyph: 1.0 fills all four arcs, ~0.66 shows three, ~0.33
    /// shows one, 0 leaves just the dot. Cutoffs mirror SignalQuality.
    private func variableValueFor(rssi: Int) -> Double {
        switch rssi {
        case _ where rssi >= -50:  return 1.0   // excellent: 4 bars
        case -65 ..< -50:          return 0.66  // good: 3 bars
        case -75 ..< -65:          return 0.33  // fair: 2 bars
        case _ where rssi < -75:   return 0.0   // weak: 1 bar / 0 bars
        default:                   return 1.0
        }
    }

    func updateInternetStatus(reachable: Bool) {
        lastInternetReachable = reachable
        internetMenuItem.title = reachable ? "Internet: Reachable" : "Internet: Unreachable"
        internetMenuItem.isHidden = false
        // WiFi-connected-but-internet-down should flip the menubar icon to
        // `wifi.exclamationmark`, which means rerendering whenever reachability
        // changes — not only on WiFi state transitions.
        renderStatus()
    }

    func updateConnectionQuality(_ report: ConnectionQuality.Report) {
        qualityMenuItem.title = report.summaryLine
        qualityMenuItem.isHidden = false
    }

    func updateRecentEvents(_ events: [WiFiEvent]) {
        for item in recentEventItems { menu.removeItem(item) }
        recentEventItems.removeAll()

        let headerIndex = menu.index(of: recentHeaderItem)
        guard headerIndex >= 0 else { return }
        var insertIndex = headerIndex + 1

        if events.isEmpty {
            let item = styledMenuItem("  No events yet", color: .tertiaryLabelColor)
            menu.insertItem(item, at: insertIndex)
            recentEventItems.append(item)
        } else {
            for event in events.prefix(8) {
                let dot = event.isNegative ? "\u{25CF}" : "\u{25CB}"
                let title = "  \(event.timeString)  \(dot) \(event.displayString)"
                let color: NSColor = event.isNegative ? .systemRed : .secondaryLabelColor
                let item = styledMenuItem(title, color: color, mono: true)
                menu.insertItem(item, at: insertIndex)
                recentEventItems.append(item)
                insertIndex += 1
            }
        }
    }

    func updateStats(disconnects: Int, downtime: TimeInterval) {
        if disconnects == 0 {
            statsMenuItem.title = "Today: No disconnects"
        } else {
            let dtStr = formatDowntime(downtime)
            statsMenuItem.title = "Today: \(disconnects) drop\(disconnects == 1 ? "" : "s"), \(dtStr) downtime"
        }
    }

    func updateNetworkReliability(_ networks: [(ssid: String, uptime: Double, disconnects: Int)]) {
        for item in reliabilityItems { menu.removeItem(item) }
        reliabilityItems.removeAll()

        let relevant = networks.filter { $0.disconnects > 0 }
        reliabilityHeaderItem.isHidden = relevant.isEmpty

        guard !relevant.isEmpty else { return }

        let headerIndex = menu.index(of: reliabilityHeaderItem)
        guard headerIndex >= 0 else { return }
        var insertIndex = headerIndex + 1

        for net in relevant.prefix(5) {
            let uptimeStr = String(format: "%.1f%%", net.uptime)
            let title = "  \(net.ssid) — \(uptimeStr) uptime, \(net.disconnects) drops"
            let item = styledMenuItem(title, color: .secondaryLabelColor, mono: false)
            menu.insertItem(item, at: insertIndex)
            reliabilityItems.append(item)
            insertIndex += 1
        }
    }

    // MARK: - Actions

    @objc private func toggleLoginItem(_ sender: NSMenuItem) {
        let enable = sender.state != .on
        setLoginItemEnabled(enable)
        sender.state = enable ? .on : .off
    }

    #if !APPSTORE
    @objc private func toggleAutoDisconnect(_ sender: NSMenuItem) {
        let enabled = sender.state != .on
        sender.state = enabled ? .on : .off
        UserDefaults.standard.set(enabled, forKey: "autoDisconnectDeadNetworks")
    }

    @objc private func disconnectAction(_ sender: NSMenuItem) {
        onDisconnect?()
    }

    @objc private func checkForUpdatesAction(_ sender: NSMenuItem) {
        onCheckForUpdates?()
    }

    @objc private func openHooksFolderAction(_ sender: NSMenuItem) {
        onOpenHooksFolder?()
    }
    #else
    @objc private func openWiFiSettingsAction(_ sender: NSMenuItem) {
        onOpenWiFiSettings?()
    }
    #endif

    @objc private func exportLog(_ sender: NSMenuItem) {
        onExportLog?()
    }

    @objc private func copyReceipt(_ sender: NSMenuItem) {
        onCopyReceipt?()
    }

    @objc private func showAboutAction(_ sender: NSMenuItem) {
        onShowAbout?()
    }

    @objc private func showNetworkInsightsAction(_ sender: NSMenuItem) {
        onShowNetworkInsights?()
    }

    @objc private func showSettingsAction(_ sender: NSMenuItem) {
        onShowSettings?()
    }

    @objc private func openLocationSettingsAction(_ sender: NSMenuItem) {
        onOpenLocationSettings?()
    }

    @objc private func openNotificationSettingsAction(_ sender: NSMenuItem) {
        onOpenNotificationSettings?()
    }

    private func renderPermissionHints(locationGatedNameless: Bool) {
        grantLocationMenuItem?.isHidden = !locationGatedNameless
        // Surface the notifications-denied hint ONLY when the user has
        // opted-in to at least one notification category but the OS-level
        // permission is denied — otherwise the hint is just noise.
        // Keys mirror NotificationSettings' @AppStorage; defaults match too.
        let defs = UserDefaults.standard
        let userExpectsAlerts =
            (defs.object(forKey: "notify.disconnected") as? Bool ?? true)
            || (defs.object(forKey: "notify.signalDegraded") as? Bool ?? true)
            || (defs.object(forKey: "notify.internetLost") as? Bool ?? true)
        notificationsDisabledMenuItem?.isHidden = !(userExpectsAlerts && !lastNotificationsAuthorized)
    }

    @objc private func quit(_ sender: NSMenuItem) {
        onQuit?()
    }

    // MARK: - Login Item

    private func isLoginItemEnabled() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }

    private func setLoginItemEnabled(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("signaldrop: login item toggle failed: \(error)")
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        item.attributedTitle = NSAttributedString(
            string: title,
            attributes: [
                .font: NSFont.systemFont(ofSize: 11, weight: .semibold),
                .foregroundColor: NSColor.secondaryLabelColor,
            ]
        )
        return item
    }

    private func styledMenuItem(_ title: String, color: NSColor, mono: Bool = false) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        let font = mono
            ? NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
            : NSFont.systemFont(ofSize: 12)
        item.attributedTitle = NSAttributedString(
            string: title,
            attributes: [.font: font, .foregroundColor: color]
        )
        return item
    }

    private func formatDowntime(_ seconds: TimeInterval) -> String {
        if seconds < 60 {
            return "\(Int(seconds))s"
        } else if seconds < 3600 {
            let mins = Int(seconds) / 60
            let secs = Int(seconds) % 60
            return secs > 0 ? "\(mins)m \(secs)s" : "\(mins)m"
        } else {
            let hours = Int(seconds) / 3600
            let mins = (Int(seconds) % 3600) / 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
    }
}
