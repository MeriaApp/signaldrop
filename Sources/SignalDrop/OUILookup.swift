import Foundation

/// MAC-address prefix → vendor lookup. The first three bytes of any
/// 802.11 BSSID (Basic Service Set ID — i.e., the AP's MAC address) are
/// an IEEE-assigned Organizationally Unique Identifier; we ship the
/// full IEEE MA-L registry (~39,000 entries) in `Resources/oui-vendors.json`
/// so the Scanner tab can show "Cisco" instead of `8c:e9:b6:13:77:e7`
/// for essentially every commercially-shipped 802.11 device.
///
/// Regenerate the bundle from <https://standards-oui.ieee.org/oui/oui.csv>
/// via `Scripts/generate-oui-bundle.py`. Vendor names are normalized to
/// short display forms (e.g. "Cisco" not "Cisco Systems, Inc.") at
/// generation time so the runtime lookup is a single dictionary hit.
enum OUILookup {
    /// What we know about who owns a BSSID's MAC prefix. Distinguishes
    /// a registered IEEE vendor from the locally-administered (privacy-
    /// randomized) MACs that iPhone Personal Hotspots and modern client
    /// devices use — those will never appear in a global OUI registry
    /// by design, so the UI should label them as such rather than
    /// silently show no vendor.
    enum VendorInfo: Equatable {
        case known(String)
        case privateMAC
    }

    /// Returns a `VendorInfo` for any BSSID. `nil` only when the BSSID
    /// isn't parseable — for the unrecognized-globally-administered case
    /// we still return nothing so the UI can choose to hide rather than
    /// guess (some obscure-vendor OUIs do legitimately fall outside the
    /// bundled registry). Input may use either colon or hyphen separators
    /// and either case.
    static func info(for bssid: String) -> VendorInfo? {
        guard let parsed = parse(bssid) else { return nil }
        if parsed.isLocallyAdministered {
            return .privateMAC
        }
        if let known = table[parsed.prefix] {
            return .known(known)
        }
        return nil
    }

    /// Convenience wrapper returning just the display string for a BSSID,
    /// or `nil` when there's nothing meaningful to show. Use this when
    /// the call site doesn't care about the locally-administered case
    /// separately. The default label for a private MAC is "Private MAC"
    /// — the same terminology Apple's own Settings app uses.
    static func vendor(for bssid: String) -> String? {
        switch info(for: bssid) {
        case .known(let name): return name
        case .privateMAC:      return "Private MAC"
        case nil:              return nil
        }
    }

    /// Whether a BSSID is a locally-administered (randomized) MAC. Bit 1
    /// of the first byte is the U/L flag: `1` = locally administered.
    /// Examples: `02:xx:xx`, `06:xx:xx`, `7E:xx:xx`, `62:xx:xx`. These
    /// MACs are issued by software (iPhone Personal Hotspot, Android
    /// private-DNS mode, some VPN apps) and have no vendor identity by
    /// design — the OUI table will never resolve them.
    static func isLocallyAdministered(_ bssid: String) -> Bool {
        parse(bssid)?.isLocallyAdministered ?? false
    }

    // MARK: - Internal

    private struct Parsed {
        let prefix: String   // "XX:XX:XX" uppercase
        let firstByte: UInt8
        var isLocallyAdministered: Bool { (firstByte & 0x02) != 0 }
    }

    private static func parse(_ bssid: String) -> Parsed? {
        let cleaned = bssid.uppercased()
            .replacingOccurrences(of: "-", with: ":")
            .replacingOccurrences(of: ".", with: ":")
        let parts = cleaned.split(separator: ":")
        guard parts.count >= 3,
              parts[0].count == 2, parts[1].count == 2, parts[2].count == 2,
              let firstByte = UInt8(parts[0], radix: 16)
        else { return nil }
        return Parsed(
            prefix: "\(parts[0]):\(parts[1]):\(parts[2])",
            firstByte: firstByte
        )
    }

    /// Decoded once, on first access. The bundled JSON is ~1.1 MB
    /// minified; decoding ~39k entries into a Swift `[String: String]`
    /// takes a few tens of milliseconds on Apple Silicon. Defer to the
    /// first time the Scanner tab actually queries so app launch isn't
    /// paying for a feature the user might never invoke.
    private static let table: [String: String] = {
        guard let url = Bundle.main.url(forResource: "oui-vendors", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let raw = try? JSONSerialization.jsonObject(with: data) as? [String: String]
        else {
            return [:]
        }
        // Drop the `_comment` documentation key so it never accidentally
        // shows up as a vendor for a malformed BSSID.
        return raw.filter { !$0.key.hasPrefix("_") }
    }()
}
