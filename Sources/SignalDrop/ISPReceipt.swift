import Foundation

/// Generates a short, paste-friendly text "receipt" of WiFi reliability over a
/// rolling window. Designed for users to drop into ISP support chats so the
/// support agent has concrete data instead of "my internet has been bad."
final class ISPReceipt {
    private let eventLog: EventLog
    private let connectionQuality: ConnectionQuality

    init(eventLog: EventLog, connectionQuality: ConnectionQuality) {
        self.eventLog = eventLog
        self.connectionQuality = connectionQuality
    }

    /// Build a 5–8 line summary of the last 14 days of WiFi reliability.
    func generate(days: Int = 14) -> String {
        let now = Date()
        let start = now.addingTimeInterval(-Double(days) * 86400)
        let events = eventLog.eventsInRange(from: start, to: now)
        let disconnects = events.filter { $0.type == .disconnected }
        let internetIssues = events.filter { $0.type == .internetLost && $0.details == "ISP outage suspected" }

        // Disconnect / downtime totals
        let (total, longest, _, longestEvent) = computeDowntime(events: events, periodEnd: now)

        // Per-network reliability (top 3 by event count)
        let networks = Array(eventLog.knownNetworks().prefix(3))
        var reliability: [(ssid: String, uptime: Double, disconnects: Int)] = []
        for ssid in networks {
            let r = connectionQuality.networkReliability(ssid: ssid, days: days)
            reliability.append((ssid: ssid, uptime: r.uptime, disconnects: r.disconnects))
        }

        // Peak time-of-day for drops
        let peakWindow = peakTimeWindow(events: disconnects)

        var lines: [String] = []
        lines.append("SignalDrop Receipt — \(formatDate(now))")
        lines.append("\(machineName()) · macOS \(osVersion())")
        lines.append("Last \(days) days: \(disconnects.count) disconnect\(disconnects.count == 1 ? "" : "s"), \(formatDuration(total)) total downtime")

        if disconnects.count > 0 {
            if let longestEv = longestEvent {
                let when = formatDateTime(longestEv.timestamp)
                let where_ = longestEv.ssid ?? "unknown network"
                lines.append("Longest outage: \(formatDuration(longest)) on \(when) (\(where_))")
            } else {
                lines.append("Longest outage: \(formatDuration(longest))")
            }
        }

        if let window = peakWindow, disconnects.count >= 3 {
            lines.append("Most drops between \(window) (\(disconnects.count) events in window)")
        }

        if internetIssues.count > 0 {
            lines.append("ISP-suspected outages (WiFi up, internet down): \(internetIssues.count)")
        }

        if !reliability.isEmpty {
            let parts = reliability.map { "\($0.ssid) \(Int($0.uptime.rounded()))%" }
            lines.append("Per-network reliability: \(parts.joined(separator: " · "))")
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Internals

    private func computeDowntime(events: [WiFiEvent], periodEnd: Date) -> (total: TimeInterval, longest: TimeInterval, count: Int, longestEvent: WiFiEvent?) {
        var total: TimeInterval = 0
        var longest: TimeInterval = 0
        var longestEv: WiFiEvent?
        var count = 0
        var lastDisc: WiFiEvent?
        let sorted = events.sorted { $0.timestamp < $1.timestamp }
        for ev in sorted {
            if ev.type == .disconnected {
                lastDisc = ev
            } else if ev.type == .connected, let disc = lastDisc {
                let dur = ev.timestamp.timeIntervalSince(disc.timestamp)
                total += dur
                if dur > longest {
                    longest = dur
                    longestEv = disc
                }
                count += 1
                lastDisc = nil
            }
        }
        if let disc = lastDisc {
            let dur = periodEnd.timeIntervalSince(disc.timestamp)
            total += dur
            if dur > longest {
                longest = dur
                longestEv = disc
            }
            count += 1
        }
        return (total, longest, count, longestEv)
    }

    private func peakTimeWindow(events: [WiFiEvent]) -> String? {
        guard !events.isEmpty else { return nil }
        var hourCounts = [Int: Int]()
        let cal = Calendar.current
        for ev in events {
            let h = cal.component(.hour, from: ev.timestamp)
            hourCounts[h, default: 0] += 1
        }
        // Find the 4-hour window with the most disconnects
        var bestStart = 0
        var bestCount = 0
        for start in 0..<24 {
            var c = 0
            for offset in 0..<4 {
                c += hourCounts[(start + offset) % 24] ?? 0
            }
            if c > bestCount {
                bestCount = c
                bestStart = start
            }
        }
        // Only report if the window covers >= 50% of events
        guard bestCount >= max(2, events.count / 2) else { return nil }
        return "\(formatHour(bestStart))–\(formatHour((bestStart + 4) % 24))"
    }

    private func formatHour(_ h: Int) -> String {
        let h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h)
        let suffix = h < 12 ? "am" : "pm"
        return "\(h12)\(suffix)"
    }

    private func formatDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: d)
    }

    private func formatDateTime(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d 'at' h:mm a"
        return f.string(from: d)
    }

    private func formatDuration(_ s: TimeInterval) -> String {
        if s < 60 { return "\(Int(s))s" }
        if s < 3600 {
            let m = Int(s) / 60
            let sec = Int(s) % 60
            return sec > 0 ? "\(m)m \(sec)s" : "\(m)m"
        }
        let h = Int(s) / 3600
        let m = (Int(s) % 3600) / 60
        return m > 0 ? "\(h)h \(m)m" : "\(h)h"
    }

    private func machineName() -> String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var bytes = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &bytes, &size, nil, 0)
        let hwModel = String(cString: bytes)
        return hwModel.isEmpty ? "Mac" : prettyMacName(hwModel)
    }

    private func prettyMacName(_ hwModel: String) -> String {
        // hw.model returns identifiers like "Mac15,3" or "MacBookPro18,1".
        // Map common families; fall back to the raw identifier.
        if hwModel.hasPrefix("MacBookPro") { return "MacBook Pro" }
        if hwModel.hasPrefix("MacBookAir") { return "MacBook Air" }
        if hwModel.hasPrefix("MacBook") { return "MacBook" }
        if hwModel.hasPrefix("iMac") { return "iMac" }
        if hwModel.hasPrefix("Macmini") { return "Mac mini" }
        if hwModel.hasPrefix("MacStudio") { return "Mac Studio" }
        if hwModel.hasPrefix("MacPro") { return "Mac Pro" }
        if hwModel.hasPrefix("Mac") { return "Mac" }
        return hwModel
    }

    private func osVersion() -> String {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        return "\(v.majorVersion).\(v.minorVersion)"
    }
}
