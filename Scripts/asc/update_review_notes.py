#!/usr/bin/env python3
"""
Update App Review Information notes for SignalDrop's macOS v1.0 submission.
Addresses all 3 rejection items in the notes so the reviewer has context up
front. Also lists the test plan explicitly.
"""
import json, time, subprocess, sys
from pathlib import Path
import jwt

ISSUER = subprocess.check_output("grep -E '^(export )?ASC_API_ISSUER_ID=' ~/.keys | cut -d= -f2-", shell=True, text=True).strip().strip('"').strip("'")
KEY = (Path.home() / ".private_keys/AuthKey_5RDJ5SQ5LK.p8").read_text()
KID = "5RDJ5SQ5LK"
BASE = "https://api.appstoreconnect.apple.com"

def tok():
    return jwt.encode({"iss": ISSUER, "iat": int(time.time()), "exp": int(time.time())+1200, "aud": "appstoreconnect-v1"},
                      KEY, algorithm="ES256", headers={"kid": KID, "typ": "JWT"})

def asc(method, path, data=None):
    cmd = ["curl", "-sS", "-X", method, BASE + path, "-H", f"Authorization: Bearer {tok()}"]
    if data is not None:
        cmd += ["-H", "Content-Type: application/json"]
        tf = Path(f"/tmp/asc_payload_{int(time.time()*1000)}.json")
        tf.write_text(json.dumps(data))
        cmd += ["--data-binary", f"@{tf}"]
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    return json.loads(r.stdout) if r.stdout.strip() else {}


REVIEW_DETAIL_ID = "22d25fcb-da61-4cc2-b448-d0e5f3f0ada8"

NOTES = """SignalDrop is a menu bar utility for macOS — it has no main window and no Dock icon. After install and launch, look for the WiFi icon at the right end of the macOS menu bar (near the system clock). Click that icon to open the status dropdown.

LOCATION SERVICES PERMISSION
SignalDrop requires Location Services permission because Apple's CoreWLAN framework requires it on macOS 14 (Sonoma) and later for any app that reads the current Wi-Fi network's SSID. SignalDrop uses the SSID to display which network you are on and to track per-network reliability statistics in the menu. Without Location permission, network names appear as "Unknown."

SignalDrop never records or transmits your location. The app makes zero outbound network requests — all data is stored in a local SQLite database on the user's Mac and never leaves the device.

NOTE ON 2.1(a) — "QUIT AND OPEN SAFARI EXTENSIONS PREFERENCES" BUTTON
The previous review reported that a "Quit and Open Safari Extensions Preferences" button was unresponsive. SignalDrop does not contain a Safari Extension and has no UI elements related to Safari Extensions. The codebase has zero references to Safari Extensions; there is no extension target in the Xcode project. The only Quit affordance in the entire app is the "Quit SignalDrop" item at the bottom of the menu bar dropdown, which we have verified works correctly across macOS 13, 14, and 15.

We respectfully believe the 2.1(a) feedback may have been intended for a different submission. If we have misunderstood, please tell us which screen or menu item exhibits this button and we will reproduce and resolve it immediately.

UPDATED SCREENSHOTS (2.3.3)
We have replaced all five App Store screenshots. The new screenshots show SignalDrop's actual menu bar dropdown UI in five real states: connected with excellent signal, weak signal warning, disconnected, "connected but no internet" detection, and the per-network reliability log. Each shot is captured from the running app on macOS, with surrounding chrome (menu bar) showing the app's natural runtime context.

HOW TO TEST
1. Launch SignalDrop. Grant Location Services when prompted.
2. The WiFi icon appears at the right end of the menu bar.
3. Click the icon to open the dropdown. The first section shows live connection state.
4. Toggle Wi-Fi off in System Settings → Wi-Fi to observe the "Disconnected" state in the menu and the macOS notification.
5. Toggle "Sound Alerts," "Signal Warnings," and "Launch at Login" via the dropdown to confirm preferences persist.
6. Use "Quit SignalDrop" at the bottom of the dropdown to exit.

Thank you for the re-review. Please reach out via the contact info on this submission if you need anything further.
"""

print(f"Updating notes on review detail {REVIEW_DETAIL_ID}")
print(f"New notes length: {len(NOTES)} chars\n")

r = asc("PATCH", f"/v1/appStoreReviewDetails/{REVIEW_DETAIL_ID}", {
    "data": {
        "type": "appStoreReviewDetails",
        "id": REVIEW_DETAIL_ID,
        "attributes": {"notes": NOTES}
    }
})

if "errors" in r:
    print("ERROR:")
    print(json.dumps(r, indent=2)[:2000])
    sys.exit(1)

# Verify
v = asc("GET", f"/v1/appStoreReviewDetails/{REVIEW_DETAIL_ID}")
attrs = v["data"]["attributes"]
print(f"Updated notes (first 400):")
print(repr(attrs.get('notes', '')[:400]))
print(f"\nFull length: {len(attrs.get('notes', ''))}")
print(f"Contact: {attrs.get('contactFirstName')} {attrs.get('contactLastName')}, {attrs.get('contactEmail')}, {attrs.get('contactPhone')}")
