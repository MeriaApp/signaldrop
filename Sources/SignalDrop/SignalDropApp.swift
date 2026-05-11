import AppKit
import UserNotifications

final class SignalDropApp: NSObject, NSApplicationDelegate {
    private let wifiMonitor = WiFiMonitor()
    private let networkMonitor = NetworkMonitor()
    private let notificationService = NotificationService()
    private let eventLog = EventLog()
    private let menuBar = MenuBarController()
    private let locationManager = LocationManager()
    private let onboarding = OnboardingController()
    private lazy var connectionQuality = ConnectionQuality(eventLog: eventLog)
    private lazy var ispReport = ISPReport(eventLog: eventLog, connectionQuality: connectionQuality)
    private lazy var ispReceipt = ISPReceipt(eventLog: eventLog, connectionQuality: connectionQuality)

    #if !APPSTORE
    private let webhookService = WebhookService()
    private let updater = UpdaterService()
    #endif

    private var refreshTimer: Timer?

    #if !APPSTORE
    private var deadNetworkTimer: Timer?
    private var deadNetworkSSID: String?
    private let deadNetworkTimeout: TimeInterval = 15
    #endif

    // Recent-event window used by disconnect-cause classifier
    private var lastSignalDegradedAt: Date?
    private var lastInternetLostAt: Date?
    private let causeWindow: TimeInterval = 60

    // Throttling: prevent notification spam during WiFi flapping
    private var lastNotificationTime: [WiFiEventType: Date] = [:]
    private let throttleIntervals: [WiFiEventType: TimeInterval] = [
        .disconnected: 5,
        .connected: 5,
        .signalDegraded: 30,
        .signalRecovered: 30,
        .internetLost: 10,
        .internetRestored: 10,
        .ssidChanged: 5,
        .powerOn: 5,
        .powerOff: 5,
    ]

    // MARK: - App Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        registerDefaults()

        // Location Services (required for SSID on macOS 14+).
        // The onboarding window does the first-launch prompt; this callback
        // refreshes the menu when the user grants or revokes permission
        // later via System Settings.
        locationManager.onAuthorizationChanged = { [weak self] authorized in
            guard let self else { return }
            self.menuBar.updateLocationAuthorized(authorized)
            let state = self.wifiMonitor.currentState()
            self.menuBar.updateWiFiState(state)
        }

        // First launch: show the SwiftUI onboarding window and let it
        // sequence the location → notifications prompts. On returning
        // launches we skip the window and silently re-read the status.
        let isFirstLaunch = !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        if isFirstLaunch {
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            onboarding.onComplete = { [weak self] in
                self?.notificationService.refreshAuthorizationStatus()
            }
            onboarding.show()
        } else {
            // Returning user — no prompts; if location was previously
            // denied, the menu will show "Disconnected" until they fix it.
            locationManager.requestAuthorization()
        }

        // Menu bar
        menuBar.setup()
        menuBar.onExportLog = { [weak self] in self?.exportLog() }
        menuBar.onExportReport = { [weak self] in self?.ispReport.saveReport() }
        menuBar.onCopyReceipt = { [weak self] in self?.copyReceiptToClipboard() }
        menuBar.onQuit = { NSApp.terminate(nil) }
        menuBar.onShowAbout = { [weak self] in self?.showAbout() }
        menuBar.onShowWelcome = { [weak self] in self?.showOnboardingAgain() }
        menuBar.onOpenLocationSettings = {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices") {
                NSWorkspace.shared.open(url)
            }
        }
        menuBar.onOpenNotificationSettings = {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                NSWorkspace.shared.open(url)
            }
        }

        #if !APPSTORE
        menuBar.onOpenHooksFolder = { [weak self] in self?.openHooksFolder() }
        menuBar.onDisconnect = { [weak self] in self?.disconnectFromDeadNetwork() }
        menuBar.onCheckForUpdates = { [weak self] in self?.updater.checkForUpdates(nil) }
        #else
        menuBar.onOpenWiFiSettings = { self.openWiFiSettings() }
        #endif

        // WiFi monitor
        wifiMonitor.onEvent = { [weak self] event in self?.handleEvent(event) }
        wifiMonitor.onStateChanged = { [weak self] state in
            self?.menuBar.updateWiFiState(state)
        }

        // Network monitor
        networkMonitor.onInternetStatusChanged = { [weak self] reachable in
            guard let self else { return }
            self.menuBar.updateInternetStatus(reachable: reachable)

            if !reachable {
                let wifiState = self.wifiMonitor.currentState()
                let currentSSID = wifiState.ssid

                #if !APPSTORE
                self.deadNetworkSSID = currentSSID
                self.startDeadNetworkTimer()
                #endif

                // If WiFi is still connected when internet drops, that's
                // strong signal it's an ISP-side outage (not a local WiFi issue).
                let details: String? = wifiState.isConnected ? "ISP outage suspected" : nil

                self.lastInternetLostAt = Date()
                let event = WiFiEvent(type: .internetLost, ssid: currentSSID, details: details)
                self.handleEvent(event)
            } else {
                #if !APPSTORE
                self.cancelDeadNetworkTimer()
                #endif

                let event = WiFiEvent(type: .internetRestored, ssid: self.wifiMonitor.currentState().ssid)
                self.handleEvent(event)
            }
        }
        networkMonitor.onActiveInterfaceChanged = { [weak self] label in
            self?.menuBar.updateActiveNonWifiInterface(label)
        }

        // Restart CoreWLAN event monitoring after the Mac wakes — CWWiFiClient
        // delegates can go silent across sleep and stay silent forever otherwise.
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemDidWake(_:)),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        // Start
        wifiMonitor.start()
        networkMonitor.start()

        // Initial state
        menuBar.updateInternetStatus(reachable: networkMonitor.isInternetReachable)
        menuBar.updateActiveNonWifiInterface(networkMonitor.activeNonWifiLabel)
        menuBar.updateLocationAuthorized(locationManager.isAuthorized)
        refreshNotificationsAuthorization()
        refreshUI()

        // Periodic refresh (30s for stats, events, and connection quality)
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.refreshUI()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        wifiMonitor.stop()
        networkMonitor.stop()
        refreshTimer?.invalidate()
    }

    @objc private func systemDidWake(_ notification: Notification) {
        wifiMonitor.restartMonitoring()
    }

    // MARK: - Event Handling

    private func handleEvent(_ event: WiFiEvent) {
        // Track signal-degraded timing for the disconnect-cause classifier.
        if event.type == .signalDegraded {
            lastSignalDegradedAt = Date()
        }

        // Classify a fresh disconnect by looking at the last 60s of events.
        let enriched: WiFiEvent
        if event.type == .disconnected {
            enriched = classifyDisconnect(event)
        } else {
            enriched = event
        }

        eventLog.log(enriched)

        #if !APPSTORE
        webhookService.fire(event: event)
        #endif

        guard shouldNotify(for: event.type) else {
            refreshUI()
            return
        }
        lastNotificationTime[event.type] = Date()

        let soundEnabled = UserDefaults.standard.bool(forKey: "soundEnabled")
        let signalWarningsEnabled = UserDefaults.standard.bool(forKey: "signalWarningsEnabled")

        switch event.type {
        case .disconnected:
            notificationService.send(
                title: "WiFi Disconnected",
                body: event.ssid.map { "Lost connection to \($0)" } ?? "WiFi connection lost",
                sound: soundEnabled,
                critical: true
            )

        case .connected:
            let body: String
            if let details = event.details {
                body = "Back on \(event.ssid ?? "WiFi") — \(details)"
            } else {
                body = "Connected to \(event.ssid ?? "WiFi")"
            }
            notificationService.send(title: "WiFi Connected", body: body, sound: soundEnabled)

        case .ssidChanged:
            let body: String
            if let details = event.details {
                body = "Now on \(event.ssid ?? "Unknown") (\(details))"
            } else {
                body = "Switched to \(event.ssid ?? "Unknown")"
            }
            notificationService.send(title: "Network Changed", body: body, sound: soundEnabled)

        case .signalDegraded:
            guard signalWarningsEnabled else { break }
            notificationService.send(
                title: "WiFi Signal Weak",
                body: "Signal at \(event.rssi ?? 0) dBm — connection may drop",
                sound: soundEnabled
            )

        case .signalRecovered:
            guard signalWarningsEnabled else { break }
            notificationService.send(
                title: "WiFi Signal Recovered",
                body: "Signal improved to \(event.rssi ?? 0) dBm",
                sound: false
            )

        case .internetLost:
            notificationService.send(
                title: "Internet Unreachable",
                body: "WiFi connected but no internet access",
                sound: soundEnabled
            )

        case .internetRestored:
            notificationService.send(
                title: "Internet Restored",
                body: "Back online",
                sound: false
            )

        case .powerOff:
            notificationService.send(
                title: "WiFi Turned Off",
                body: "WiFi radio has been disabled",
                sound: soundEnabled
            )

        case .powerOn:
            notificationService.send(
                title: "WiFi Turned On",
                body: "WiFi radio enabled — searching for networks",
                sound: false
            )
        }

        refreshUI()
    }

    /// Tag a disconnect with a likely-cause label based on the last 60s of events.
    private func classifyDisconnect(_ event: WiFiEvent) -> WiFiEvent {
        let now = Date()
        let cause: String?
        if let t = lastInternetLostAt, now.timeIntervalSince(t) < causeWindow {
            cause = "Internet went out first"
        } else if let t = lastSignalDegradedAt, now.timeIntervalSince(t) < causeWindow {
            cause = "Weak signal preceded drop"
        } else {
            cause = "Sudden disconnect"
        }
        return WiFiEvent(
            type: event.type,
            ssid: event.ssid,
            bssid: event.bssid,
            rssi: event.rssi,
            transmitRate: event.transmitRate,
            details: cause,
            id: event.id,
            timestamp: event.timestamp
        )
    }

    private func shouldNotify(for type: WiFiEventType) -> Bool {
        guard let lastTime = lastNotificationTime[type],
              let interval = throttleIntervals[type] else {
            return true
        }
        return Date().timeIntervalSince(lastTime) >= interval
    }

    // MARK: - Dead Network (Direct distribution only)

    #if !APPSTORE
    private func startDeadNetworkTimer() {
        cancelDeadNetworkTimer()
        let autoDisconnect = UserDefaults.standard.bool(forKey: "autoDisconnectDeadNetworks")
        guard autoDisconnect else { return }

        deadNetworkTimer = Timer.scheduledTimer(withTimeInterval: deadNetworkTimeout, repeats: false) { [weak self] _ in
            self?.handleDeadNetwork()
        }
    }

    private func cancelDeadNetworkTimer() {
        deadNetworkTimer?.invalidate()
        deadNetworkTimer = nil
        deadNetworkSSID = nil
    }

    private func handleDeadNetwork() {
        let state = wifiMonitor.currentState()
        guard state.isConnected, !networkMonitor.isInternetReachable else { return }

        let ssid = state.ssid ?? "current network"
        wifiMonitor.cycleConnection()

        notificationService.send(
            title: "Dead Network — Switching",
            body: "\(ssid) has no internet. Disconnected to find a better network.",
            sound: UserDefaults.standard.bool(forKey: "soundEnabled"),
            critical: false
        )
        deadNetworkSSID = nil
    }

    private func disconnectFromDeadNetwork() {
        let state = wifiMonitor.currentState()
        let ssid = state.ssid ?? "current network"
        wifiMonitor.disconnectFromCurrentNetwork()

        notificationService.send(
            title: "Disconnected",
            body: "Left \(ssid) — macOS will join the next available network.",
            sound: false
        )
    }

    private func openHooksFolder() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        let hooksDir = appSupport.appendingPathComponent("SignalDrop/hooks")
        NSWorkspace.shared.open(hooksDir)
    }
    #endif

    // MARK: - WiFi Settings (App Store builds — can't auto-disconnect, open settings instead)

    private func openWiFiSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.network?Wi-Fi") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - UI Refresh

    private func refreshUI() {
        // Self-heal: re-read CoreWLAN every tick so the status header can't
        // sit stale if delegate events go silent (e.g. across sleep/wake).
        menuBar.updateWiFiState(wifiMonitor.currentState())

        let events = eventLog.recentEvents(limit: 8)
        menuBar.updateRecentEvents(events)

        let stats = eventLog.todayStats()
        menuBar.updateStats(disconnects: stats.disconnects, downtime: stats.totalDowntime)

        // Connection quality grade
        let report = connectionQuality.currentReport()
        menuBar.updateConnectionQuality(report)

        // Network reliability for known networks
        let networks = eventLog.knownNetworks()
        var reliability: [(ssid: String, uptime: Double, disconnects: Int)] = []
        for ssid in networks.prefix(5) {
            let stats = connectionQuality.networkReliability(ssid: ssid)
            reliability.append((ssid: ssid, uptime: stats.uptime, disconnects: stats.disconnects))
        }
        menuBar.updateNetworkReliability(reliability)
    }

    // MARK: - Export

    private func exportLog() {
        let csv = eventLog.exportCSV()
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.commaSeparatedText]
        savePanel.nameFieldStringValue = "signaldrop-log.csv"
        savePanel.canCreateDirectories = true

        savePanel.begin { response in
            guard response == .OK, let url = savePanel.url else { return }
            try? csv.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    /// Copy a short paste-friendly reliability summary to the clipboard so users
    /// can drop it into ISP support chats with concrete data.
    private func copyReceiptToClipboard() {
        let text = ispReceipt.generate()
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)

        notificationService.send(
            title: "Receipt copied",
            body: "Paste it into your ISP support chat for concrete reliability data.",
            sound: false
        )
    }

    // MARK: - About

    private func showAbout() {
        let info = Bundle.main.infoDictionary
        let marketing = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"

        let alert = NSAlert()
        alert.messageText = "SignalDrop"
        alert.informativeText = """
            Version \(marketing) (\(build))

            Event-driven WiFi disconnect notifier for macOS.
            Uses CoreWLAN — the OS pushes events the instant something \
            changes, so SignalDrop adds minimal overhead.

            \u{00A9} 2026 Jesse Meria
            """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
        NSApp.setActivationPolicy(.accessory)
    }

    // MARK: - Onboarding (user-triggered)

    private func showOnboardingAgain() {
        onboarding.onComplete = { [weak self] in
            guard let self else { return }
            self.menuBar.updateLocationAuthorized(self.locationManager.isAuthorized)
            self.refreshNotificationsAuthorization()
            self.notificationService.refreshAuthorizationStatus()
        }
        onboarding.show()
    }

    /// Asks UNUserNotificationCenter for current authorization and propagates
    /// the result to the menu without prompting the user. Used at startup and
    /// after onboarding completes so the menu reflects reality.
    private func refreshNotificationsAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            let authorized = settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional
            DispatchQueue.main.async {
                self?.menuBar.updateNotificationsAuthorized(authorized)
            }
        }
    }

    // MARK: - Defaults

    private func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            "soundEnabled": true,
            "signalWarningsEnabled": true,
            "autoDisconnectDeadNetworks": true,
        ])
    }
}
