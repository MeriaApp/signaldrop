"""Generate a comprehensive OUI lookup bundle from IEEE registry CSV.

Produces a JSON dict mapping `XX:XX:XX` (uppercase, colon-separated) to a
short, clean vendor name. Strips legal-entity boilerplate (`Inc.`, `Corp.`,
`Co., Ltd.`, etc.) so the Scanner UI can show "Cisco" not "Cisco Systems,
Inc.". Output is sorted by key for deterministic diffs.
"""
import csv
import json
import re
import sys

SRC = "/tmp/ieee-oui.csv"
DST = "/Users/jesse/Developer/dropout/Resources/oui-vendors.json"

# Boilerplate to strip from vendor names. Applied as a regex sweep at the
# end of the name. Order matters: longer matches first.
TRAIL_BOILERPLATE = re.compile(
    r"\s*,?\s*(Inc\.?|Incorporated|Corp\.?|Corporation|Co\.?,\s*Ltd\.?|"
    r"Co\.?\s*Ltd\.?|Limited|Ltd\.?|LLC|L\.L\.C\.|GmbH|S\.A\.|S\.A\.S\.|"
    r"AG|Pty\.?\s*Ltd\.?|PLC|N\.V\.|B\.V\.|S\.r\.l\.|S\.p\.A\.|Oy)\.?$",
    re.IGNORECASE,
)

# Per-OUI shortenings. Maps "long official name" → "short display name" for
# vendors users actually recognize. Applied after boilerplate strip.
PRETTY = {
    "Apple": "Apple",
    "Apple, Inc.": "Apple",
    "Apple Inc.": "Apple",
    "Cisco Systems": "Cisco",
    "Cisco Meraki": "Cisco Meraki",
    "Cisco-Linksys, LLC": "Linksys",
    "Cisco-Linksys": "Linksys",
    "ARRIS Group, Inc.": "Arris",
    "ARRIS Group": "Arris",
    "ARRIS International, Inc.": "Arris",
    "Hon Hai Precision Ind. Co., Ltd.": "Foxconn",
    "Hon Hai Precision Industry": "Foxconn",
    "Foxconn": "Foxconn",
    "TP-LINK TECHNOLOGIES CO.,LTD.": "TP-Link",
    "Tp-Link Technologies Co.,Ltd.": "TP-Link",
    "TP-Link Corporation Limited": "TP-Link",
    "NETGEAR": "Netgear",
    "NETGEAR Inc.": "Netgear",
    "Ubiquiti Networks Inc.": "Ubiquiti",
    "Ubiquiti Networks, Inc.": "Ubiquiti",
    "Ubiquiti Inc": "Ubiquiti",
    "ASUSTek COMPUTER INC.": "ASUS",
    "ASUSTek Computer": "ASUS",
    "AsusTek Computer Inc.": "ASUS",
    "GUANGDONG OPPO MOBILE TELECOMMUNICATIONS CORP.,LTD": "OPPO",
    "Samsung Electronics Co.,Ltd": "Samsung",
    "SAMSUNG ELECTRO-MECHANICS CO., LTD.": "Samsung",
    "Samsung Electronics": "Samsung",
    "Huawei Technologies Co.,Ltd": "Huawei",
    "HUAWEI TECHNOLOGIES CO.,LTD": "Huawei",
    "Xiaomi Communications Co Ltd": "Xiaomi",
    "Xiaomi Inc": "Xiaomi",
    "Sony Corporation": "Sony",
    "SONY CORPORATION": "Sony",
    "LG Electronics": "LG",
    "LG Electronics Inc": "LG",
    "Espressif Inc.": "Espressif",
    "Espressif Systems": "Espressif",
    "Murata Manufacturing Co., Ltd.": "Murata",
    "Aruba Networks": "Aruba",
    "Aruba, a Hewlett Packard Enterprise Company": "Aruba",
    "Aruba a Hewlett Packard Enterprise Company": "Aruba",
    "Hewlett Packard Enterprise": "HPE",
    "Hewlett Packard": "HP",
    "Hewlett-Packard": "HP",
    "Liteon Technology Corporation": "Liteon",
    "Liteon": "Liteon",
    "AzureWave Technology Inc.": "AzureWave",
    "Pegatron Corporation": "Pegatron",
    "Wistron NeWeb Corporation": "Wistron",
    "Wistron InfoComm": "Wistron",
    "Compal Information (Kunshan) Co.,Ltd.": "Compal",
    "Compal Information": "Compal",
    "Inventec Corporation": "Inventec",
    "Quanta Computer Inc.": "Quanta",
    "Espressif": "Espressif",
    "Belkin International Inc.": "Belkin",
    "BELKIN INTERNATIONAL INC.": "Belkin",
    "Aerohive Networks Inc.": "Aerohive",
    "Extreme Networks Headquarters": "Extreme Networks",
    "Extreme Networks": "Extreme Networks",
    "Juniper Networks": "Juniper",
    "Mist Systems, Inc": "Juniper",
    "Cradlepoint": "Cradlepoint",
    "Sercomm Corporation.": "Sercomm",
    "Sercomm Corporation": "Sercomm",
    "Technicolor CH USA Inc.": "Technicolor",
    "Technicolor USA": "Technicolor",
    "Technicolor Delivery Technologies, SAS": "Technicolor",
    "ZyXEL Communications Corporation": "Zyxel",
    "ZYXEL Communications Corporation": "Zyxel",
    "Zyxel Communications Corporation": "Zyxel",
    "Calix Inc.": "Calix",
    "Calix": "Calix",
    "Hitron Technologies. Inc": "Hitron",
    "Hitron Technologies Inc": "Hitron",
    "AVM Audiovisuelles Marketing und Computersysteme GmbH": "AVM (Fritz!Box)",
    "AVM GmbH": "AVM (Fritz!Box)",
    "AVM": "AVM (Fritz!Box)",
    "MikroTikls SIA": "MikroTik",
    "Mikrotikls SIA": "MikroTik",
    "D-Link International": "D-Link",
    "D-Link Corporation": "D-Link",
    "Edimax Technology Co. Ltd.": "Edimax",
    "Edimax Technology": "Edimax",
    "Buffalo.Inc": "Buffalo",
    "Buffalo Inc.": "Buffalo",
    "Vodafone Italia S.p.A.": "Vodafone",
    "Sagemcom Broadband SAS": "Sagemcom",
    "Sagemcom": "Sagemcom",
    "Plume Design Inc.": "Plume",
    "Plume Design Inc": "Plume",
    "Plume Design, Inc.": "Plume",
    "Amazon Technologies Inc.": "Amazon",
    "Amazon.com, Inc.": "Amazon",
    "Amazon Technologies": "Amazon",
    "Roku, Inc.": "Roku",
    "Roku, Inc": "Roku",
    "Roku Inc.": "Roku",
    "Nintendo Co.,Ltd": "Nintendo",
    "Nintendo Co., Ltd.": "Nintendo",
    "Sonos, Inc.": "Sonos",
    "Sonos Inc.": "Sonos",
    "Synology Incorporated": "Synology",
    "Google, Inc.": "Google",
    "Google Inc": "Google",
    "Intel Corporate": "Intel",
    "INTEL CORPORATION": "Intel",
    "Intel Corporation": "Intel",
    "Microsoft Corporation": "Microsoft",
    "Microsoft": "Microsoft",
    "Microsoft Mobile Oy": "Microsoft",
    "Nokia Corporation": "Nokia",
    "Nokia Shanghai Bell Co., Ltd.": "Nokia",
    "Fortinet, Inc.": "Fortinet",
    "Fortinet Inc": "Fortinet",
    "Ruckus Wireless": "Ruckus",
    "CommScope Inc": "CommScope",
    "ARRIS / CommScope": "Arris",
    "Senao Networks, Inc.": "Senao",
    "EnGenius Networks, Inc.": "EnGenius",
    "Datang Mobile Communications Equipment CO.,LTD": "Datang",
    "TCT mobile ltd": "TCL / Alcatel",
    "Cisco Systems": "Cisco",
    "Cisco Systems, Inc": "Cisco",
    "CISCO SYSTEMS, INC.": "Cisco",
    "Huawei Device Co., Ltd.": "Huawei",
    "Huawei Device": "Huawei",
    "ARRIS Group, Inc": "Arris",
    "Arcadyan Corporation": "Arcadyan",
    "Arcadyan Technology Corporation": "Arcadyan",
    "Peplink International Ltd.": "Peplink",
    "Peplink International": "Peplink",
    "Commscope": "CommScope",
    "ZTE Corporation": "ZTE",
    "zte corporation": "ZTE",
    "zte": "ZTE",
    "Liteon Technology Corp.": "Liteon",
    "Fiberhome Telecommunication Technologies Co.,LTD.": "Fiberhome",
    "Fiberhome Telecommunication Technologies": "Fiberhome",
    "TP-Link Systems Inc.": "TP-Link",
    "TP-Link Systems": "TP-Link",
    "Dell Inc.": "Dell",
    "Dell EMC": "Dell",
    "Lenovo Mobile Communication Technology Ltd.": "Lenovo",
    "LENOVO MOBILE COMMUNICATION TECHNOLOGY LTD.": "Lenovo",
    "Lenovo (Beijing) Limited.": "Lenovo",
    "Lenovo Mobile Communication (Wuhan) Company Limited": "Lenovo",
    "Lenovo Connect SAS": "Lenovo",
    "Lenovo Mobile Communication Technology": "Lenovo",
    "vivo Mobile Communication Co., Ltd.": "vivo",
    "VIVO MOBILE COMMUNICATION CO.,LTD.": "vivo",
    "Realme Chongqing MobileTelecommunications Corp.,Ltd.": "Realme",
    "OnePlus Technology (Shenzhen) Co., Ltd": "OnePlus",
    "OnePlus Technology (Shenzhen) Co., Ltd.": "OnePlus",
    "Sagemcom Broadband SAS.": "Sagemcom",
    "TCL Communication Ltd.": "TCL",
}

# Org names whose presence in the CSV doesn't help the user identify a
# vendor — these are placeholder entries used by IEEE for sub-allocated
# MA-M/MA-S blocks (where the actual vendor isn't determinable from the
# first 3 bytes). Showing "IEEE Registration Authority" next to a BSSID
# would be worse than no vendor at all.
SKIP_ORGS = {"IEEE Registration Authority"}


def clean_name(raw: str) -> str:
    """Strip trailing legal boilerplate, then apply known prettifications.

    Order matters: strip *first* so PRETTY lookups hit the canonical short
    form even when the CSV has a long-form variant we didn't pre-register.
    """
    raw = raw.strip().strip('"')
    # Loop in case multiple suffixes stack (e.g. "Foo, Inc., Ltd.").
    cleaned = raw
    for _ in range(4):
        new = TRAIL_BOILERPLATE.sub("", cleaned).strip().rstrip(",").strip()
        if new == cleaned:
            break
        cleaned = new
    if cleaned in PRETTY:
        return PRETTY[cleaned]
    if raw in PRETTY:
        return PRETTY[raw]
    return cleaned or raw

def fmt_oui(hex6: str) -> str:
    """`286FB9` → `28:6F:B9`."""
    h = hex6.strip().upper()
    if len(h) != 6:
        return ""
    return f"{h[0:2]}:{h[2:4]}:{h[4:6]}"

def main():
    out = {}
    with open(SRC, encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            registry = row.get("Registry", "").strip()
            # MA-L is the standard 24-bit OUI assignment. MA-M / MA-S are
            # smaller sub-allocations that don't share the same first-3-byte
            # semantics, so they'd produce false positives when we lookup by
            # the leading 3 bytes only.
            if registry != "MA-L":
                continue
            assignment = row.get("Assignment", "").strip()
            org = row.get("Organization Name", "").strip()
            oui = fmt_oui(assignment)
            if not oui or not org or org in SKIP_ORGS:
                continue
            out[oui] = clean_name(org)
    # Sort for deterministic JSON output. Add a documentation key.
    sorted_out = {"_comment": (
        "OUI → vendor lookup, generated from "
        "https://standards-oui.ieee.org/oui/oui.csv "
        "via Scripts/generate-oui-bundle.py. Restricted to MA-L registry "
        "entries (24-bit OUI; the only assignment class whose first 3 "
        "bytes uniquely identify the vendor). Vendor names are normalized "
        "to short display forms (e.g. 'Cisco' not 'Cisco Systems, Inc.')."
    )}
    for k in sorted(out.keys()):
        sorted_out[k] = out[k]
    # Minified JSON: 1.3 MB → ~600 KB. The `_comment` key documents the
    # bundle source for anyone inspecting the file directly.
    with open(DST, "w", encoding="utf-8") as f:
        json.dump(sorted_out, f, separators=(",", ":"), ensure_ascii=False)
        f.write("\n")
    print(f"Wrote {len(out)} OUI entries → {DST}")
    # Sanity check: do our test-set BSSIDs now hit?
    test = ["5C:E9:31", "78:8C:B5", "44:A5:6E", "38:06:E6", "E4:5E:1B",
            "10:56:CA", "34:DB:9C"]
    print("\nSanity check:")
    for t in test:
        print(f"  {t} -> {out.get(t, '(MISS)')}")

if __name__ == "__main__":
    main()
