import Foundation

/// The user-selectable window for the Connection History tab.
/// Each period drives both the data query range and the bucket
/// granularity used by the timeline strip.
enum HistoryPeriod: String, CaseIterable, Identifiable {
    case h24 = "Last 24 hours"
    case d7  = "Last 7 days"
    case d30 = "Last 30 days"

    var id: String { rawValue }

    var seconds: TimeInterval {
        switch self {
        case .h24: return 86_400
        case .d7:  return 86_400 * 7
        case .d30: return 86_400 * 30
        }
    }

    /// Number of buckets to slice the period into for the timeline strip.
    /// Picked to give comparable visual density: 24h → 24 hourly buckets,
    /// 7d → 28 four-hour buckets, 30d → 30 daily buckets.
    var bucketCount: Int {
        switch self {
        case .h24: return 24
        case .d7:  return 28
        case .d30: return 30
        }
    }
}

/// One outage reconstructed from a disconnect→connect pair in EventLog.
/// `end` is nil if the outage was still ongoing at the end of the report
/// window (typically only for "right now" reports).
struct OutageRecord: Identifiable, Hashable {
    let id = UUID()
    let start: Date
    let end: Date?
    let ssid: String?
    let durationSeconds: TimeInterval
    /// The cause label SignalDropApp attached at disconnect time:
    /// "Internet went out first" / "Weak signal preceded drop" / "Sudden disconnect".
    let cause: String?
}

/// One slice of the timeline strip. Computed by summing the portion of
/// every outage that overlaps the bucket's [start, end) range.
struct HistoryBucket: Identifiable, Hashable {
    let id = UUID()
    let start: Date
    let end: Date
    let downtimeSeconds: TimeInterval
    let outageCount: Int

    var uptimePercent: Double {
        let total = end.timeIntervalSince(start)
        guard total > 0 else { return 100 }
        let down = min(downtimeSeconds, total)
        return ((total - down) / total) * 100
    }
}

/// Per-network rollup for the History tab. Identifies which specific
/// networks are responsible for the outages in the report — turns
/// "your connection has been bad" into "this network specifically is
/// the problem." Networks the user touched with zero drops still appear
/// (as "rock solid") so the user can compare reliability across cafes.
struct NetworkSummary: Identifiable, Hashable {
    let ssid: String
    let disconnects: Int
    let totalDowntimeSeconds: TimeInterval
    let longestOutageSeconds: TimeInterval

    var id: String { ssid }

    var averageOutageSeconds: TimeInterval {
        disconnects > 0 ? totalDowntimeSeconds / Double(disconnects) : 0
    }
}

/// A fully-computed history report for a given period. View-layer
/// consumes this; PDF renderer consumes the same struct.
struct ConnectionHistoryReport {
    let period: HistoryPeriod
    let periodStart: Date
    let periodEnd: Date
    let grade: ConnectionQuality.Grade
    let score: Int
    let uptimePercent: Double
    let outageCount: Int
    let totalDowntimeSeconds: TimeInterval
    let longestOutageSeconds: TimeInterval
    let buckets: [HistoryBucket]
    /// Sorted newest-first for the table.
    let outages: [OutageRecord]
    let knownNetworks: [String]
    /// Per-SSID rollup of disconnects/downtime within the period.
    /// Sorted worst-first (most disconnects, then most downtime).
    let perNetwork: [NetworkSummary]
    /// Number of disconnect→connect pairs that fell below the user's
    /// `minDisconnectDurationSeconds` threshold and were excluded from the
    /// grade math, outage count, timeline, and per-network rollup. Surfaced
    /// to the user as a footnote so the History tab agrees with the
    /// notification-level "phantom drops are silenced" expectation.
    let filteredBriefRoamCount: Int
    /// Threshold (in seconds) used to filter `filteredBriefRoamCount`. Carried
    /// alongside the count so the footnote can name the cutoff.
    let filterThresholdSeconds: TimeInterval
}

/// Builds a `ConnectionHistoryReport` from the existing EventLog.
/// Lightweight — recomputes from scratch on every call. EventLog already
/// indexes by timestamp so the underlying query is cheap.
///
/// Phantom-drop filter: outages shorter than
/// `notificationSettings.minDisconnectDurationSeconds` are excluded from the
/// grade math, outage count, timeline buckets, and per-network rollup. Their
/// count is surfaced separately so the user can see "we filtered N brief
/// roams" rather than wondering why the receipt doesn't match the raw log.
final class ConnectionHistoryService {
    private let eventLog: EventLog
    private let notificationSettings: NotificationSettings

    init(eventLog: EventLog, notificationSettings: NotificationSettings) {
        self.eventLog = eventLog
        self.notificationSettings = notificationSettings
    }

    /// Events in the 60-second window leading up to and through an
    /// outage's start, filtered to the categories that explain the
    /// drop: signal-degraded, internet-lost, ssid-changed, the
    /// disconnect itself. Used by the outage detail sheet to show
    /// lead-up context.
    func contextEvents(forOutage outage: OutageRecord) -> [WiFiEvent] {
        let windowStart = outage.start.addingTimeInterval(-60)
        let windowEnd = outage.start.addingTimeInterval(1) // include the disconnect itself
        let relevant: Set<WiFiEventType> = [
            .signalDegraded, .signalRecovered, .internetLost,
            .internetRestored, .ssidChanged, .disconnected, .powerOff,
        ]
        return eventLog.eventsInRange(from: windowStart, to: windowEnd)
            .filter { relevant.contains($0.type) }
            .sorted { $0.timestamp < $1.timestamp }
    }

    func report(for period: HistoryPeriod) -> ConnectionHistoryReport {
        let end = Date()
        let start = end.addingTimeInterval(-period.seconds)
        let events = eventLog.eventsInRange(from: start, to: end)
            .sorted { $0.timestamp < $1.timestamp }

        let threshold = notificationSettings.minDisconnectDurationSeconds
        let allOutages = reconstructOutages(events: events, periodEnd: end)
        let (outages, filteredCount) = filterBriefRoams(allOutages, minDuration: threshold)

        let totalDowntime = outages.reduce(0) { $0 + $1.durationSeconds }
        let longestOutage = outages.map(\.durationSeconds).max() ?? 0
        let totalPeriod = end.timeIntervalSince(start)
        let uptime = totalPeriod > 0
            ? max(0, min(100, ((totalPeriod - totalDowntime) / totalPeriod) * 100))
            : 100

        let score = scoreFromOutages(outages: outages, totalDowntime: totalDowntime)
        let grade = gradeFromScore(score)

        let buckets = computeBuckets(
            outages: outages,
            periodStart: start,
            periodEnd: end,
            bucketCount: period.bucketCount
        )

        // Every SSID that appears in any event in the window — connected,
        // disconnected, ssid-changed, etc. This way a network the user
        // touched but never dropped from still shows up in the per-network
        // breakdown as "rock solid."
        let networks = Array(Set(events.compactMap { $0.ssid })).sorted()
        let perNetwork = computePerNetwork(networks: networks, outages: outages)

        return ConnectionHistoryReport(
            period: period,
            periodStart: start,
            periodEnd: end,
            grade: grade,
            score: score,
            uptimePercent: uptime,
            outageCount: outages.count,
            totalDowntimeSeconds: totalDowntime,
            longestOutageSeconds: longestOutage,
            buckets: buckets,
            outages: outages.sorted { $0.start > $1.start },
            knownNetworks: networks,
            perNetwork: perNetwork,
            filteredBriefRoamCount: filteredCount,
            filterThresholdSeconds: threshold
        )
    }

    /// Partition raw outages into the kept set + the count of "brief roams"
    /// dropped below the threshold. Open-ended outages (no `end`) are kept
    /// regardless because we can't yet judge their final length.
    private func filterBriefRoams(
        _ outages: [OutageRecord], minDuration: TimeInterval
    ) -> (kept: [OutageRecord], filtered: Int) {
        if minDuration <= 0 { return (outages, 0) }
        var kept: [OutageRecord] = []
        var filtered = 0
        kept.reserveCapacity(outages.count)
        for outage in outages {
            if outage.end == nil || outage.durationSeconds >= minDuration {
                kept.append(outage)
            } else {
                filtered += 1
            }
        }
        return (kept, filtered)
    }

    private func computePerNetwork(networks: [String], outages: [OutageRecord]) -> [NetworkSummary] {
        var byNetwork: [String: (count: Int, total: TimeInterval, longest: TimeInterval)] = [:]
        for outage in outages {
            guard let ssid = outage.ssid else { continue }
            var entry = byNetwork[ssid] ?? (0, 0, 0)
            entry.count += 1
            entry.total += outage.durationSeconds
            entry.longest = max(entry.longest, outage.durationSeconds)
            byNetwork[ssid] = entry
        }
        // Include zero-outage networks so the user sees the full picture.
        for ssid in networks where byNetwork[ssid] == nil {
            byNetwork[ssid] = (0, 0, 0)
        }
        return byNetwork
            .map { ssid, stats in
                NetworkSummary(
                    ssid: ssid,
                    disconnects: stats.count,
                    totalDowntimeSeconds: stats.total,
                    longestOutageSeconds: stats.longest
                )
            }
            // Worst-first: most disconnects, tiebreak by most total downtime,
            // tiebreak again alphabetically for stable ordering.
            .sorted { a, b in
                if a.disconnects != b.disconnects { return a.disconnects > b.disconnects }
                if a.totalDowntimeSeconds != b.totalDowntimeSeconds { return a.totalDowntimeSeconds > b.totalDowntimeSeconds }
                return a.ssid < b.ssid
            }
    }

    // MARK: - Private

    private func reconstructOutages(events: [WiFiEvent], periodEnd: Date) -> [OutageRecord] {
        var out: [OutageRecord] = []
        var pending: WiFiEvent?
        for ev in events {
            if ev.type == .disconnected {
                pending = ev
            } else if ev.type == .connected, let disc = pending {
                let duration = ev.timestamp.timeIntervalSince(disc.timestamp)
                out.append(OutageRecord(
                    start: disc.timestamp,
                    end: ev.timestamp,
                    ssid: disc.ssid,
                    durationSeconds: duration,
                    cause: disc.details
                ))
                pending = nil
            }
        }
        // Still disconnected at the end of the window.
        if let disc = pending {
            let duration = periodEnd.timeIntervalSince(disc.timestamp)
            out.append(OutageRecord(
                start: disc.timestamp,
                end: nil,
                ssid: disc.ssid,
                durationSeconds: duration,
                cause: disc.details
            ))
        }
        return out
    }

    private func computeBuckets(
        outages: [OutageRecord],
        periodStart: Date,
        periodEnd: Date,
        bucketCount: Int
    ) -> [HistoryBucket] {
        let totalSeconds = periodEnd.timeIntervalSince(periodStart)
        guard bucketCount > 0, totalSeconds > 0 else { return [] }
        let bucketSize = totalSeconds / Double(bucketCount)

        var buckets: [HistoryBucket] = []
        buckets.reserveCapacity(bucketCount)
        for i in 0..<bucketCount {
            let bStart = periodStart.addingTimeInterval(Double(i) * bucketSize)
            let bEnd = periodStart.addingTimeInterval(Double(i + 1) * bucketSize)
            var downtime: TimeInterval = 0
            var count = 0
            for outage in outages {
                let outageEnd = outage.end ?? periodEnd
                let overlapStart = max(bStart, outage.start)
                let overlapEnd = min(bEnd, outageEnd)
                if overlapEnd > overlapStart {
                    downtime += overlapEnd.timeIntervalSince(overlapStart)
                }
                if outage.start >= bStart && outage.start < bEnd {
                    count += 1
                }
            }
            buckets.append(HistoryBucket(
                start: bStart,
                end: bEnd,
                downtimeSeconds: downtime,
                outageCount: count
            ))
        }
        return buckets
    }

    /// Same penalty curve as `ConnectionQuality` so the History tab grade
    /// agrees with the menu-bar header for the 24h period.
    private func scoreFromOutages(outages: [OutageRecord], totalDowntime: TimeInterval) -> Int {
        var s = 100
        s -= outages.count * 8
        s -= Int(totalDowntime / 60) * 3
        return max(0, min(100, s))
    }

    private func gradeFromScore(_ score: Int) -> ConnectionQuality.Grade {
        switch score {
        case 90...100: return .excellent
        case 75..<90:  return .good
        case 55..<75:  return .fair
        case 30..<55:  return .poor
        default:       return .terrible
        }
    }
}
