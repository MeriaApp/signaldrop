import SwiftUI

/// Notification preferences window. Apple System Settings-style Form layout
/// with three sections: When to notify (per-event toggles), Rules (minimum
/// disconnect duration + quiet hours), and Sound.
struct SettingsView: View {
    @ObservedObject var settings: NotificationSettings

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
                        Text(thresholdLabel)
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

                Toggle("Quiet hours", isOn: $settings.quietHoursEnabled)
                if settings.quietHoursEnabled {
                    HStack(spacing: 8) {
                        Text("From")
                        Picker("", selection: $settings.quietHoursStartHour) {
                            ForEach(0..<24) { hour in
                                Text(formatHour(hour)).tag(hour)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 90)
                        Text("to")
                        Picker("", selection: $settings.quietHoursEndHour) {
                            ForEach(0..<24) { hour in
                                Text(formatHour(hour)).tag(hour)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 90)
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
        }
        .formStyle(.grouped)
        .frame(minWidth: 520, idealWidth: 560, minHeight: 720, idealHeight: 760)
    }

    private var thresholdLabel: String {
        let v = Int(settings.minDisconnectDurationSeconds.rounded())
        if v == 0 { return "notify every drop" }
        return "\(v) second\(v == 1 ? "" : "s")"
    }

    private func formatHour(_ hour: Int) -> String {
        let f = DateFormatter()
        f.dateFormat = "h a"
        var comps = DateComponents()
        comps.hour = hour
        let date = Calendar.current.date(from: comps) ?? Date()
        return f.string(from: date)
    }
}
