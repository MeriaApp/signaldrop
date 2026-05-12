import Foundation
import SwiftUI

/// User-controlled notification rules. Backed by UserDefaults so settings
/// persist across launches without us managing files.
///
/// The biggest behavior change here vs. the original on/off model is the
/// **minimum disconnect duration threshold** — phantom 1–2s drops (caused
/// by roaming, brief AP handoffs, or sleep-wake bumps) get silenced unless
/// they cross the user-set threshold. This is the single highest-leverage
/// notification rule for a disconnect-notifier app: most 1-star reviews of
/// apps in this category complain about "too many notifications for things
/// that aren't real outages."
final class NotificationSettings: ObservableObject {
    // MARK: - Per-event-type opt-in

    /// User got disconnected from the WiFi network. Default ON — the primary
    /// reason people install this app.
    @AppStorage("notify.disconnected") var notifyDisconnected: Bool = true

    /// User reconnected after a disconnect. Default OFF — most users only
    /// want to know about the bad event, not the recovery.
    @AppStorage("notify.connected") var notifyConnected: Bool = false

    /// User roamed to a different SSID. Default OFF — usually intentional.
    @AppStorage("notify.ssidChanged") var notifySSIDChanged: Bool = false

    /// Signal strength dropped below the warning threshold. Default ON —
    /// gives the user a chance to move closer or change networks before
    /// the connection actually drops.
    @AppStorage("notify.signalDegraded") var notifySignalDegraded: Bool = true

    /// Signal strength recovered. Default OFF — the user already knows
    /// when the situation gets better.
    @AppStorage("notify.signalRecovered") var notifySignalRecovered: Bool = false

    /// WiFi still up but internet is unreachable. Default ON — important
    /// because the user can't tell from the OS WiFi icon that something's wrong.
    @AppStorage("notify.internetLost") var notifyInternetLost: Bool = true

    /// Internet reachability restored. Default OFF.
    @AppStorage("notify.internetRestored") var notifyInternetRestored: Bool = false

    /// WiFi radio turned on. Default OFF — usually intentional.
    @AppStorage("notify.powerOn") var notifyPowerOn: Bool = false

    /// WiFi radio turned off. Default OFF — usually intentional.
    @AppStorage("notify.powerOff") var notifyPowerOff: Bool = false

    // MARK: - Rules

    /// Don't notify about a disconnect unless it lasts at least this many
    /// seconds. Phantom 1–2s drops are common when roaming between APs in
    /// dense WiFi environments (cafes, offices) and the alerts are noise.
    /// Range: 0 (notify every drop) to 60 (only major drops). Default 5s.
    @AppStorage("notify.minDisconnectDuration") var minDisconnectDurationSeconds: Double = 5.0

    /// Don't notify about a signal-degraded event unless the signal stays
    /// below the warning threshold continuously for at least this many
    /// seconds. A 1-second flicker to -76 dBm shouldn't fire "Signal Weak."
    /// Range: 0 (notify on every dip) to 60 (only sustained weakness).
    /// Default 10s — longer than the disconnect threshold because RSSI is
    /// noisier than link state.
    @AppStorage("notify.minSignalDegradedDuration") var minSignalDegradedDurationSeconds: Double = 10.0

    /// When ON, suppress all non-critical notifications during the quiet
    /// hours window. Internet-lost + disconnect notifications still fire
    /// because those are the critical category.
    @AppStorage("notify.quietHoursEnabled") var quietHoursEnabled: Bool = false

    /// Hour-of-day (0-23) when quiet hours begin. Combined with
    /// `quietHoursStartMinute` for minute-precision support added in v1.1.
    @AppStorage("notify.quietHoursStartHour") var quietHoursStartHour: Int = 22  // 10 PM

    /// Minute-of-hour (0-59) when quiet hours begin.
    @AppStorage("notify.quietHoursStartMinute") var quietHoursStartMinute: Int = 0

    /// Hour-of-day (0-23) when quiet hours end.
    @AppStorage("notify.quietHoursEndHour") var quietHoursEndHour: Int = 7  // 7 AM

    /// Minute-of-hour (0-59) when quiet hours end.
    @AppStorage("notify.quietHoursEndMinute") var quietHoursEndMinute: Int = 0

    // MARK: - Sound

    /// Existing key — kept here for unified management.
    @AppStorage("soundEnabled") var soundEnabled: Bool = true

    // MARK: - Helpers

    /// True if `now` falls within the user's configured quiet-hours window.
    /// Handles wrap-around (e.g., 22:30 → 07:15) correctly with
    /// minute-of-hour precision (added in v1.1).
    func isInQuietHours(now: Date = Date()) -> Bool {
        guard quietHoursEnabled else { return false }
        let cal = Calendar.current
        let nowMinutes = cal.component(.hour, from: now) * 60
            + cal.component(.minute, from: now)
        let startMinutes = quietHoursStartHour * 60 + quietHoursStartMinute
        let endMinutes = quietHoursEndHour * 60 + quietHoursEndMinute
        if startMinutes <= endMinutes {
            return nowMinutes >= startMinutes && nowMinutes < endMinutes
        } else {
            // Wraps across midnight (e.g., 22:30 → 07:15)
            return nowMinutes >= startMinutes || nowMinutes < endMinutes
        }
    }

    /// True if the user wants to be notified about this event type right now.
    /// Combines per-event-type opt-in + quiet-hours suppression.
    ///
    /// `isCritical` overrides quiet hours — used for long outages so the
    /// user still finds out about a 30-minute drop at 2am even if quiet
    /// hours are enabled.
    func shouldNotify(for type: WiFiEventType, isCritical: Bool = false, now: Date = Date()) -> Bool {
        let typeEnabled: Bool
        switch type {
        case .disconnected:      typeEnabled = notifyDisconnected
        case .connected:         typeEnabled = notifyConnected
        case .ssidChanged:       typeEnabled = notifySSIDChanged
        case .signalDegraded:    typeEnabled = notifySignalDegraded
        case .signalRecovered:   typeEnabled = notifySignalRecovered
        case .internetLost:      typeEnabled = notifyInternetLost
        case .internetRestored:  typeEnabled = notifyInternetRestored
        case .powerOn:           typeEnabled = notifyPowerOn
        case .powerOff:          typeEnabled = notifyPowerOff
        }
        guard typeEnabled else { return false }
        if !isCritical && isInQuietHours(now: now) { return false }
        return true
    }
}
