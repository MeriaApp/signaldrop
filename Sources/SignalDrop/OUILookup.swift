import Foundation

/// MAC-address prefix → vendor lookup. The first three bytes of any
/// 802.11 BSSID (Basic Service Set ID — i.e., the AP's MAC address) are
/// an IEEE-assigned Organizationally Unique Identifier; we ship a
/// curated subset of those in `Resources/oui-vendors.json` so the
/// Scanner tab can show "Cisco Meraki" instead of `8c:e9:b6:13:77:e7`.
///
/// The bundled table covers ~30 vendors and ~970 OUIs — picked for the
/// devices a Mac user is most likely to see in 2026 (consumer routers,
/// enterprise APs, ISP gateways, common hotspot clients). Anything not
/// in the table falls through with no vendor row rendered. Refresh by
/// regenerating from <https://standards-oui.ieee.org/oui/oui.txt>.
enum OUILookup {
    /// Returns a human-readable vendor name for a BSSID, or `nil` if
    /// the OUI prefix isn't in the bundled table. Input may use either
    /// colon or hyphen separators and either case.
    static func vendor(for bssid: String) -> String? {
        guard let prefix = normalizedPrefix(from: bssid) else { return nil }
        return table[prefix]
    }

    /// Extract and normalize the leading 3 bytes (`XX:XX:XX`, uppercase)
    /// from an arbitrary BSSID/MAC string. Returns `nil` if the input
    /// doesn't have enough hex characters to form an OUI.
    private static func normalizedPrefix(from bssid: String) -> String? {
        let cleaned = bssid.uppercased()
            .replacingOccurrences(of: "-", with: ":")
            .replacingOccurrences(of: ".", with: ":")
        let parts = cleaned.split(separator: ":")
        guard parts.count >= 3,
              parts[0].count == 2, parts[1].count == 2, parts[2].count == 2
        else { return nil }
        return "\(parts[0]):\(parts[1]):\(parts[2])"
    }

    /// Decoded once, on first access. Reading 970 entries off disk
    /// during app launch isn't worth the cost — defer to the first
    /// time the Scanner tab actually queries.
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
