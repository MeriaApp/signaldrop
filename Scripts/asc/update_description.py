#!/usr/bin/env python3
"""
PATCH App Store description to soften the false 'zero polling' claim and add the
new Receipt feature to the bullet list. Also bumps the WHAT'S NEW for v1.0.1.
"""
import json, time, subprocess, sys
from pathlib import Path
import jwt

ISSUER = subprocess.check_output("grep -E '^(export )?ASC_API_ISSUER_ID=' ~/.keys | cut -d= -f2-", shell=True, text=True).strip().strip('"').strip("'")
KEY = (Path.home() / ".private_keys/AuthKey_5RDJ5SQ5LK.p8").read_text()
KID = "5RDJ5SQ5LK"

def tok():
    return jwt.encode({"iss": ISSUER, "iat": int(time.time()), "exp": int(time.time())+1200, "aud": "appstoreconnect-v1"},
                      KEY, algorithm="ES256", headers={"kid": KID, "typ": "JWT"})

def asc(method, path, data=None):
    cmd = ["curl","-sS","-X", method, "https://api.appstoreconnect.apple.com"+path, "-H", f"Authorization: Bearer {tok()}"]
    if data is not None:
        tf = Path(f"/tmp/asc_payload_{int(time.time()*1000)}.json")
        tf.write_text(json.dumps(data))
        cmd += ["-H", "Content-Type: application/json", "--data-binary", f"@{tf}"]
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    return json.loads(r.stdout) if r.stdout.strip() else {}


LOC_ID = "eec93188-8fb7-4a96-bc46-a6891ddd815f"

DESCRIPTION = """macOS doesn't notify you when your WiFi disconnects. The icon changes to empty bars and hopes you notice. You don't — you find out minutes later when your video call freezes or your download fails.

SignalDrop fixes that. It sits in your menu bar and sends an instant notification the moment your WiFi connection changes. Disconnect, reconnect, signal degradation, network switches — you'll know immediately.

WHAT IT DOES:

- Instant disconnect and reconnect notifications with exact downtime duration
- Signal degradation warnings before your connection drops
- "Connected but no internet" detection — catches dead networks
- "ISP outage suspected" labeling when WiFi works but the internet doesn't
- Disconnect cause classification — was it weak signal, internet failure first, or sudden?
- SSID change alerts when your Mac silently switches networks
- Connection quality grade (A through F) based on 24-hour stability
- Per-network reliability tracking with uptime percentages
- ISP troubleshooting report with outage timeline and daily breakdown
- Copy Receipt for Support — paste-ready downtime summary for ISP support chats
- Event log with CSV export for sharing with your internet provider
- Daily stats showing total disconnects and downtime at a glance
- Launch at login — set it and forget it

HOW IT WORKS:

SignalDrop uses Apple's CoreWLAN framework for event-driven monitoring. The OS notifies the app the instant WiFi state changes — there's no signal polling, so the impact on your battery is minimal.

PRIVACY:

SignalDrop makes zero outbound network requests. No analytics. No telemetry. No data leaves your Mac. WiFi events are stored in a local database that you control. Your location (required by macOS for WiFi network names) is never recorded or transmitted."""

WHATS_NEW = """v1.0.1 — The Receipt update.

NEW: Copy Receipt for Support. One click copies a paste-ready summary of your WiFi reliability — perfect for ISP support chats that go somewhere instead of in circles.

NEW: ISP-suspected labeling. When WiFi stays connected but the internet drops, SignalDrop flags it as a likely ISP-side issue.

NEW: Disconnect cause classification. Every drop is now annotated with a likely cause — weak signal, internet failure first, or sudden disconnect.

FIXED: Signal-degraded warning could fail to fire after reconnecting to a strong network.

POLISHED: Honest copy in About dialog. Cleaner sandbox surface."""

print(f"Description length: {len(DESCRIPTION)} chars")
print(f"Whats new length: {len(WHATS_NEW)} chars")

r = asc("PATCH", f"/v1/appStoreVersionLocalizations/{LOC_ID}", {
    "data": {
        "type": "appStoreVersionLocalizations",
        "id": LOC_ID,
        "attributes": {
            "description": DESCRIPTION,
            # whatsNew not writable on first-ever-submission versions
        }
    }
})

if "errors" in r:
    print("ERROR:")
    print(json.dumps(r, indent=2)[:1500])
    sys.exit(1)

# Verify
v = asc("GET", f"/v1/appStoreVersionLocalizations/{LOC_ID}")
attrs = v["data"]["attributes"]
print(f"\nVerified:")
print(f"  description (head): {attrs['description'][:140]!r}")
print(f"  whatsNew (head):    {attrs.get('whatsNew', '')[:140]!r}")
print(f"  description chars:  {len(attrs['description'])}")
print(f"  whatsNew chars:     {len(attrs.get('whatsNew', ''))}")
