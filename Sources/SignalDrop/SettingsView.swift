import SwiftUI
import UserNotifications

/// Notification preferences window. Apple System Settings-style Form layout
/// with three sections: When to notify (per-event toggles), Rules (minimum
/// disconnect duration + quiet hours), and Sound.
struct SettingsView: View {
    @ObservedObject var settings: NotificationSettings
    /// Fired when the user clicks "Send test notification". Wired in
    /// `SignalDropApp` to send a sample disconnect notification through
    /// the real `NotificationService` so the user sees exactly what
    /// they'll see in production.
    var onTestNotification: (() -> Void)?

    /// Reflects the OS-level UNUserNotificationCenter authorization. The
    /// "Send test notification" button is disabled (and a hint shown)
    /// when this is `false`, so we don't fire a Send call that silently
    /// no-ops because permission was denied. Polled on `.onAppear` and
    /// when the user returns from System Settings.
    @State private var notificationsAuthorized: Bool = true

    var body: some View {
        Form {
            Section {
                Toggle("Disconnects", isOn: $settings.notifyDisconnected)
                Toggle("Reconnects",   isOn: $settings.notifyConnected)
                Toggle("Network changed", isOn: $settings.notifySSIDChanged)
                Toggle("Weak signal",     isOn: $settings.notifySignalDegraded)
                Toggle("Signal recovered", isOn: $settings.notifySignalRecovered)
                Toggle("Internet unreachable", isOn: $settings.notifyInternetLost)
                Toggle("Internet restored",     isOn: $settings.notifyInternetRestored)
                Toggle("WiFi turned off", isOn: $settings.notifyPowerOff)
                Toggle("WiFi turned on",  isOn: $settings.notifyPowerOn)
            } header: {
                Text("When to notify")
            } footer: {
                Text("Choose which events get pushed as macOS notifications. SignalDrop still records every event for the History tab regardless of these toggles.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Section {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Ignore drops shorter than")
                        Spacer()
                        Text(disconnectThresholdLabel)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $settings.minDisconnectDurationSeconds, in: 0...60, step: 1)
                    Text("Phantom 1–2s drops happen when your Mac roams between access points or wakes from sleep. Anything shorter than this threshold is silenced as a notification, but still appears in the History tab.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Ignore weak-signal flickers shorter than")
                        Spacer()
                        Text(signalDegradedThresholdLabel)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $settings.minSignalDegradedDurationSeconds, in: 0...60, step: 1)
                    Text("RSSI is noisy. A 1-second dip below -75 dBm during a quick roam shouldn't fire a \u{201C}Signal Weak\u{201D} notification. Only sustained dips longer than this threshold are surfaced.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)

                Divider()

                Toggle("Quiet hours", isOn: $settings.quietHoursEnabled)
                if settings.quietHoursEnabled {
                    HStack(spacing: 8) {
                        Text("From")
                        DatePicker(
                            "",
                            selection: quietHoursStartBinding,
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        Text("to")
                        DatePicker(
                            "",
                            selection: quietHoursEndBinding,
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        Spacer()
                    }
                    Text("Non-critical notifications are suppressed during this window. Disconnects and internet-lost still fire because they're the events you actually need to act on.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } header: {
                Text("Notification rules")
            }

            Section {
                Toggle("Play sound with notifications", isOn: $settings.soundEnabled)
            } header: {
                Text("Sound")
            }

            Section {
                Button {
                    onTestNotification?()
                } label: {
                    Label("Send test notification", systemImage: "bell.badge")
                }
                .disabled(!notificationsAuthorized || onTestNotification == nil)
                .help(notificationsAuthorized
                      ? "Fires a sample disconnect notification so you can see what they look like."
                      : "Notifications are turned off in System Settings.")
                if !notificationsAuthorized {
                    Text("Notifications are disabled in System Settings. SignalDrop can record events to the History tab, but pushed alerts won\u{2019}t appear until you grant permission.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } header: {
                Text("Try it")
            } footer: {
                Text("The test notification fires through the same path as a real disconnect, so anything you change above (sound, quiet hours, per-event toggles) reflects in what you see.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 520, idealWidth: 560, minHeight: 720, idealHeight: 760)
        .onAppear(perform: refreshAuthorizationStatus)
    }

    /// Reads the OS notification authorization without prompting. Used
    /// to enable/disable the "Send test notification" button and to
    /// surface a hint when permission has been denied.
    private func refreshAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let granted = settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional
            DispatchQueue.main.async {
                self.notificationsAuthorized = granted
            }
        }
    }

    /// Bridges the (hour, minute) Ints stored in AppStorage to a `Date`
    /// that `DatePicker(.hourAndMinute)` can edit. The date component is
    /// arbitrary — only the time is meaningful.
    private var quietHoursStartBinding: Binding<Date> {
        binding(hour: $settings.quietHoursStartHour, minute: $settings.quietHoursStartMinute)
    }

    private var quietHoursEndBinding: Binding<Date> {
        binding(hour: $settings.quietHoursEndHour, minute: $settings.quietHoursEndMinute)
    }

    private func binding(hour: Binding<Int>, minute: Binding<Int>) -> Binding<Date> {
        Binding(
            get: {
                var comps = DateComponents()
                comps.hour = hour.wrappedValue
                comps.minute = minute.wrappedValue
                return Calendar.current.date(from: comps) ?? Date()
            },
            set: { newValue in
                let cal = Calendar.current
                hour.wrappedValue = cal.component(.hour, from: newValue)
                minute.wrappedValue = cal.component(.minute, from: newValue)
            }
        )
    }

    private var disconnectThresholdLabel: String {
        let v = Int(settings.minDisconnectDurationSeconds.rounded())
        if v == 0 { return "notify every drop" }
        return "\(v) second\(v == 1 ? "" : "s")"
    }

    private var signalDegradedThresholdLabel: String {
        let v = Int(settings.minSignalDegradedDurationSeconds.rounded())
        if v == 0 { return "notify on every dip" }
        return "\(v) second\(v == 1 ? "" : "s")"
    }

}
