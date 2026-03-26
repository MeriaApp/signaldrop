import AppKit

final class DropoutApp: NSObject, NSApplicationDelegate {
    private let wifiMonitor = WiFiMonitor()
    private let networkMonitor = NetworkMonitor()
    private let notificationService = NotificationService()
    private let eventLog = EventLog()
    private let menuBar = MenuBarController()

    private var refreshTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set defaults on first launch
        registerDefaults()

        // Setup menu bar
        menuBar.setup()
        menuBar.onExportLog = { [weak self] in self?.exportLog() }
        menuBar.onQuit = { NSApp.terminate(nil) }

        // Wire up WiFi monitor
        wifiMonitor.onEvent = { [weak self] event in self?.handleEvent(event) }
        wifiMonitor.onStateChanged = { [weak self] state in
            self?.menuBar.updateWiFiState(state)
        }

        // Wire up network monitor
        networkMonitor.onInternetStatusChanged = { [weak self] reachable in
            guard let self else { return }
            self.menuBar.updateInternetStatus(reachable: reachable)

            if !reachable {
                let event = WiFiEvent(type: .internetLost, ssid: self.wifiMonitor.currentState().ssid)
                self.handleEvent(event)
            } else {
                let event = WiFiEvent(type: .internetRestored, ssid: self.wifiMonitor.currentState().ssid)
                self.handleEvent(event)
            }
        }

        // Start monitoring
        wifiMonitor.start()
        networkMonitor.start()

        // Initial UI state
        menuBar.updateInternetStatus(reachable: networkMonitor.isInternetReachable)
        refreshUI()

        // Periodic refresh for stats and recent events (every 30s)
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.refreshUI()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        wifiMonitor.stop()
        networkMonitor.stop()
        refreshTimer?.invalidate()
    }

    // MARK: - Event Handling

    private func handleEvent(_ event: WiFiEvent) {
        // Log to SQLite
        eventLog.log(event)

        // Send notification
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
            guard signalWarningsEnabled else { return }
            notificationService.send(
                title: "WiFi Signal Weak",
                body: "Signal at \(event.rssi ?? 0) dBm — connection may drop",
                sound: soundEnabled
            )

        case .signalRecovered:
            guard signalWarningsEnabled else { return }
            notificationService.send(
                title: "WiFi Signal Recovered",
                body: "Signal improved to \(event.rssi ?? 0) dBm",
                sound: false  // Don't annoy on recovery
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
                body: "WiFi radio enabled — looking for networks",
                sound: false
            )
        }

        // Refresh UI
        refreshUI()
    }

    // MARK: - UI Refresh

    private func refreshUI() {
        let events = eventLog.recentEvents(limit: 8)
        menuBar.updateRecentEvents(events)

        let stats = eventLog.todayStats()
        menuBar.updateStats(disconnects: stats.disconnects, downtime: stats.totalDowntime)
    }

    // MARK: - Export

    private func exportLog() {
        let csv = eventLog.exportCSV()
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.commaSeparatedText]
        savePanel.nameFieldStringValue = "dropout-log.csv"
        savePanel.canCreateDirectories = true

        savePanel.begin { response in
            guard response == .OK, let url = savePanel.url else { return }
            try? csv.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    // MARK: - Defaults

    private func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            "soundEnabled": true,
            "signalWarningsEnabled": true,
        ])
    }
}
