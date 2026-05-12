import Foundation

/// Computes a connection quality grade from recent event history.
/// Displayed in the menu bar as a letter grade with trend arrow.
///
/// Phantom-drop filter: disconnect→connect pairs shorter than
/// `notificationSettings.minDisconnectDurationSeconds` are excluded from the
/// outage count + downtime sum. This keeps the menu-bar grade aligned with
/// the user's "phantom drops don't count" expectation — same threshold as
/// the notification suppression.
final class ConnectionQuality {
    private let eventLog: EventLog
    private let notificationSettings: NotificationSettings

    init(eventLog: EventLog, notificationSettings: NotificationSettings) {
        self.eventLog = eventLog
        self.notificationSettings = notificationSettings
    }

    enum Grade: String {
        case excellent = "A"
        case good = "B"
        case fair = "C"
        case poor = "D"
        case terrible = "F"

        var description: String {
            switch self {
            case .excellent: return "Excellent — rock solid"
            case .good: return "Good — minor drops"
            case .fair: return "Fair — occasional issues"
            case .poor: return "Poor — frequent drops"
            case .terrible: return "Terrible — constant drops"
            }
        }

        var color: String {
            switch self {
            case .excellent: return "green"
            case .good: return "green"
            case .fair: return "yellow"
            case .poor: return "orange"
            case .terrible: return "red"
            }
        }
    }

    struct Report {
        let grade: Grade
        let score: Int           // 0-100
        let disconnects24h: Int
        let downtime24h: TimeInterval
        let avgDowntime: TimeInterval
        let longestOutage: TimeInterval
        let trend: Trend         // vs previous 24h
        let peakDropHour: Int?   // hour of day with most drops (0-23)

        var trendArrow: String {
            switch trend {
            case .improving: return "\u{2191}" // ↑
            case .stable: return "\u{2192}"    // →
            case .declining: return "\u{2193}" // ↓
            }
        }

        var summaryLine: String {
            if disconnects24h == 0 {
                return "Connection: \(grade.rawValue) — No drops in 24h"
            }
            let dtStr = formatDuration(downtime24h)
            return "Connection: \(grade.rawValue)\(trendArrow) — \(disconnects24h) drop\(disconnects24h == 1 ? "" : "s"), \(dtStr) down"
        }
    }

    enum Trend {
        case improving, stable, declining
    }

    /// Compute the current connection quality report
    func currentReport() -> Report {
        let now = Date()
        let oneDayAgo = now.addingTimeInterval(-86400)
        let twoDaysAgo = now.addingTimeInterval(-172800)

        let recentEvents = eventLog.eventsInRange(from: oneDayAgo, to: now)
        let previousEvents = eventLog.eventsInRange(from: twoDaysAgo, to: oneDayAgo)

        let threshold = notificationSettings.minDisconnectDurationSeconds

        // Calculate downtime + counts from disconnect/connect pairs, with the
        // phantom-drop filter applied so the grade matches the user's
        // notification-level expectation.
        let (totalDowntime, longestOutage, avgDowntime, disconnectCount) = computeDowntime(
            events: recentEvents, periodStart: oneDayAgo, periodEnd: now,
            minOutageDuration: threshold
        )

        // Previous period for trend — also filtered so the trend comparison
        // doesn't whip on phantom-drop noise.
        let (_, _, _, prevDisconnects) = computeDowntime(
            events: previousEvents, periodStart: twoDaysAgo, periodEnd: oneDayAgo,
            minOutageDuration: threshold
        )

        // Score (0-100): penalize disconnects and downtime
        var score = 100
        score -= disconnectCount * 8         // -8 per disconnect
        score -= Int(totalDowntime / 60) * 3 // -3 per minute of downtime
        score = max(0, min(100, score))

        let grade = gradeFromScore(score)

        // Trend
        let trend: Trend
        if disconnectCount < prevDisconnects - 1 {
            trend = .improving
        } else if disconnectCount > prevDisconnects + 1 {
            trend = .declining
        } else {
            trend = .stable
        }

        // Peak drop hour — only consider disconnects whose outage duration
        // crossed the phantom threshold, so a flood of brief roams during
        // commute time doesn't spuriously become "peak drop hour."
        let realDisconnects = realDisconnectsAboveThreshold(
            events: recentEvents, minOutageDuration: threshold
        )
        let peakHour = findPeakHour(disconnects: realDisconnects)

        return Report(
            grade: grade,
            score: score,
            disconnects24h: disconnectCount,
            downtime24h: totalDowntime,
            avgDowntime: avgDowntime,
            longestOutage: longestOutage,
            trend: trend,
            peakDropHour: peakHour
        )
    }

    /// Generate a multi-day reliability summary for a specific network.
    /// Phantom-drop filter applied so per-network uptime reflects only
    /// outages the user would have been notified about.
    func networkReliability(ssid: String, days: Int = 7) -> (uptime: Double, disconnects: Int, avgDowntime: TimeInterval) {
        let now = Date()
        let start = now.addingTimeInterval(-Double(days) * 86400)
        let events = eventLog.eventsInRange(from: start, to: now)
            .filter { $0.ssid == ssid }

        let threshold = notificationSettings.minDisconnectDurationSeconds
        let (totalDowntime, _, avgDowntime, disconnects) = computeDowntime(
            events: events, periodStart: start, periodEnd: now,
            minOutageDuration: threshold
        )

        let totalPeriod = now.timeIntervalSince(start)
        let uptime = totalPeriod > 0 ? ((totalPeriod - totalDowntime) / totalPeriod) * 100 : 100

        return (uptime: min(100, max(0, uptime)), disconnects: disconnects, avgDowntime: avgDowntime)
    }

    // MARK: - Private

    /// Build downtime stats from disconnect/connect pairs.
    /// Pairs whose duration is below `minOutageDuration` are discarded entirely
    /// (zero contribution to totals, count, longest). The trailing still-down
    /// case is kept regardless because we can't yet judge its final length.
    private func computeDowntime(
        events: [WiFiEvent], periodStart: Date, periodEnd: Date,
        minOutageDuration: TimeInterval
    ) -> (total: TimeInterval, longest: TimeInterval, average: TimeInterval, count: Int) {
        var totalDowntime: TimeInterval = 0
        var longestOutage: TimeInterval = 0
        var outageCount = 0
        var lastDisconnect: Date?

        let sorted = events.sorted { $0.timestamp < $1.timestamp }
        for event in sorted {
            if event.type == .disconnected {
                lastDisconnect = event.timestamp
            } else if event.type == .connected, let disc = lastDisconnect {
                let duration = event.timestamp.timeIntervalSince(disc)
                if duration >= minOutageDuration {
                    totalDowntime += duration
                    longestOutage = max(longestOutage, duration)
                    outageCount += 1
                }
                lastDisconnect = nil
            }
        }

        // Still disconnected at the end of the window — count if it's already
        // past the threshold; otherwise the next sample will tell us.
        if let disc = lastDisconnect {
            let duration = periodEnd.timeIntervalSince(disc)
            if duration >= minOutageDuration {
                totalDowntime += duration
                longestOutage = max(longestOutage, duration)
                outageCount += 1
            }
        }

        let avgDowntime = outageCount > 0 ? totalDowntime / Double(outageCount) : 0
        return (totalDowntime, longestOutage, avgDowntime, outageCount)
    }

    /// The subset of `.disconnected` events that survived the phantom-drop
    /// filter — i.e. each one corresponds to an outage that crossed the
    /// `minOutageDuration` threshold. Used by `findPeakHour` so commute-time
    /// roaming bursts don't dominate the peak-hour estimate.
    private func realDisconnectsAboveThreshold(
        events: [WiFiEvent], minOutageDuration: TimeInterval
    ) -> [WiFiEvent] {
        var kept: [WiFiEvent] = []
        var pending: WiFiEvent?
        let sorted = events.sorted { $0.timestamp < $1.timestamp }
        for event in sorted {
            if event.type == .disconnected {
                pending = event
            } else if event.type == .connected, let disc = pending {
                if event.timestamp.timeIntervalSince(disc.timestamp) >= minOutageDuration {
                    kept.append(disc)
                }
                pending = nil
            }
        }
        if let disc = pending {
            // Conservatively include open-ended outages (we don't know yet
            // whether the final length will cross the threshold).
            kept.append(disc)
        }
        return kept
    }

    private func gradeFromScore(_ score: Int) -> Grade {
        switch score {
        case 90...100: return .excellent
        case 75..<90: return .good
        case 55..<75: return .fair
        case 30..<55: return .poor
        default: return .terrible
        }
    }

    private func findPeakHour(disconnects: [WiFiEvent]) -> Int? {
        guard !disconnects.isEmpty else { return nil }
        var hourCounts = [Int: Int]()
        let calendar = Calendar.current
        for event in disconnects {
            let hour = calendar.component(.hour, from: event.timestamp)
            hourCounts[hour, default: 0] += 1
        }
        return hourCounts.max(by: { $0.value < $1.value })?.key
    }
}

private func formatDuration(_ seconds: TimeInterval) -> String {
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
