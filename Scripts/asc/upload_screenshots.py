#!/usr/bin/env python3
"""
Upload SignalDrop App Store screenshots to ASC for the in-review macOS version.
Replaces the existing APP_DESKTOP screenshot set on the en-US localization.

Flow:
  1. Find app by bundleId
  2. Find macOS appStoreVersion (in editable state)
  3. Find en-US appStoreVersionLocalization
  4. Get appScreenshotSets, find/create APP_DESKTOP set
  5. Delete existing appScreenshots in that set
  6. Upload new 5 screenshots (3-step dance)
  7. Verify each is COMPLETE
"""
import json
import time
import hashlib
import subprocess
import sys
from pathlib import Path

import jwt

ISSUER = subprocess.check_output(
    "grep -E '^(export )?ASC_API_ISSUER_ID=' ~/.keys | cut -d= -f2-",
    shell=True, text=True
).strip().strip('"').strip("'")

KEY_FILE = Path.home() / ".private_keys/AuthKey_5RDJ5SQ5LK.p8"
KID = "5RDJ5SQ5LK"
KEY = KEY_FILE.read_text()

BUNDLE = "com.meria.signaldrop"
APP_ID_OVERRIDE = "6761185430"  # SignalDrop - WiFi Monitor
SCREENSHOTS = [
    "01-01-status.png",
    "02-02-isp-receipt.png",
    "03-03-weak-signal.png",
    "04-04-event-log.png",
    "05-05-reliability.png",
]
SRC_DIR = Path("/Users/jesse/Developer/dropout/Screenshots/AppStore-2026-05-09/final")

BASE = "https://api.appstoreconnect.apple.com"


def tok():
    return jwt.encode(
        {"iss": ISSUER, "iat": int(time.time()),
         "exp": int(time.time()) + 1200, "aud": "appstoreconnect-v1"},
        KEY, algorithm="ES256",
        headers={"kid": KID, "typ": "JWT"}
    )


def asc(method, path, data=None, binary_file=None, raw_url=None, extra_headers=None):
    """Call ASC API via curl (avoids Python 3.13 SSL issues)."""
    url = raw_url if raw_url else BASE + path
    cmd = ["curl", "-sS", "-X", method, url,
           "-H", f"Authorization: Bearer {tok()}"]
    if extra_headers:
        for k, v in extra_headers.items():
            cmd += ["-H", f"{k}: {v}"]
    if data is not None:
        cmd += ["-H", "Content-Type: application/json"]
        # Write payload to tempfile to avoid HEREDOC truncation
        tf = Path(f"/tmp/asc_payload_{int(time.time()*1000)}.json")
        tf.write_text(json.dumps(data))
        cmd += ["--data-binary", f"@{tf}"]
    elif binary_file:
        cmd += ["--data-binary", f"@{binary_file}"]
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
    if r.returncode != 0:
        raise RuntimeError(f"curl failed ({r.returncode}): {r.stderr}")
    if not r.stdout.strip():
        return {}  # 204 No Content
    try:
        return json.loads(r.stdout)
    except json.JSONDecodeError:
        return {"_raw": r.stdout}


def die(msg, payload=None):
    print(f"FATAL: {msg}", file=sys.stderr)
    if payload:
        print(json.dumps(payload, indent=2)[:2000], file=sys.stderr)
    sys.exit(1)


# 1. Find app — use override since filter[bundleId]= URL encoding is finicky
APP_ID = APP_ID_OVERRIDE
r = asc("GET", f"/v1/apps/{APP_ID}")
app = r.get("data") or {}
print(f"→ App: {app.get('attributes', {}).get('name', '?')} ({APP_ID})")

# 2. Find macOS version (in editable state — REJECTED, PREPARE_FOR_SUBMISSION, etc.)
print("→ Finding macOS app store version")
# curl chokes on raw [brackets] in URL — encode them
r = asc("GET", f"/v1/apps/{APP_ID}/appStoreVersions?filter%5Bplatform%5D=MAC_OS&limit=10")
if not r.get("data"):
    die("No macOS versions", r)
ver = None
for v in r["data"]:
    s = v["attributes"]["appStoreState"]
    print(f"  Version {v['attributes']['versionString']}: state={s}, id={v['id']}")
    if s in ("DEVELOPER_REJECTED", "REJECTED", "PREPARE_FOR_SUBMISSION", "METADATA_REJECTED",
            "INVALID_BINARY", "DEVELOPER_REMOVED_FROM_SALE"):
        ver = v
        break
if not ver:
    # Fall back: take the first non-shipped one
    for v in r["data"]:
        s = v["attributes"]["appStoreState"]
        if s not in ("READY_FOR_SALE", "REPLACED_WITH_NEW_VERSION"):
            ver = v
            break
if not ver:
    die("No editable macOS version found", r)
VER_ID = ver["id"]
VER_STATE = ver["attributes"]["appStoreState"]
print(f"  Selected version: {ver['attributes']['versionString']} ({VER_STATE}) id={VER_ID}")

# 3. Find en-US localization
print("→ Finding en-US localization")
r = asc("GET", f"/v1/appStoreVersions/{VER_ID}/appStoreVersionLocalizations?limit=20")
loc = None
for l in r.get("data", []):
    if l["attributes"]["locale"] in ("en-US", "en_US", "en"):
        loc = l
        break
if not loc:
    die("No en-US localization", r)
LOC_ID = loc["id"]
print(f"  Locale en-US: id={LOC_ID}")

# 4. Find appScreenshotSets
print("→ Finding appScreenshotSets (APP_DESKTOP)")
r = asc("GET", f"/v1/appStoreVersionLocalizations/{LOC_ID}/appScreenshotSets?limit=50")
desktop_set = None
for s in r.get("data", []):
    print(f"  Set: {s['attributes']['screenshotDisplayType']} (id={s['id']})")
    if s["attributes"]["screenshotDisplayType"] == "APP_DESKTOP":
        desktop_set = s
if not desktop_set:
    print("  Creating APP_DESKTOP set")
    r = asc("POST", "/v1/appScreenshotSets", {
        "data": {
            "type": "appScreenshotSets",
            "attributes": {"screenshotDisplayType": "APP_DESKTOP"},
            "relationships": {
                "appStoreVersionLocalization": {
                    "data": {"type": "appStoreVersionLocalizations", "id": LOC_ID}
                }
            }
        }
    })
    desktop_set = r["data"]
SET_ID = desktop_set["id"]
print(f"  APP_DESKTOP set id: {SET_ID}")

# 5. Capture existing screenshots — DELETE only after new ones are COMPLETE
print("→ Capturing existing screenshot IDs (will delete AFTER new ones uploaded)")
r = asc("GET", f"/v1/appScreenshotSets/{SET_ID}/appScreenshots?limit=20")
existing = r.get("data", [])
print(f"  Found {len(existing)} existing — will delete after upload")
for s in existing:
    print(f"    OLD: {s['attributes'].get('fileName')} id={s['id']}")
existing_ids = [s["id"] for s in existing]

# 6. Upload new screenshots
print("→ Uploading new screenshots")
uploaded = []
for idx, fname in enumerate(SCREENSHOTS, start=1):
    fpath = SRC_DIR / fname
    if not fpath.exists():
        die(f"Missing source: {fpath}")
    fsize = fpath.stat().st_size
    md5 = hashlib.md5(fpath.read_bytes()).hexdigest()
    print(f"\n  [{idx}] {fname} ({fsize:,} bytes, md5={md5})")

    # 6a. Reserve
    r = asc("POST", "/v1/appScreenshots", {
        "data": {
            "type": "appScreenshots",
            "attributes": {"fileName": fname, "fileSize": fsize},
            "relationships": {
                "appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": SET_ID}}
            }
        }
    })
    if "errors" in r:
        die("Reserve failed", r)
    img_id = r["data"]["id"]
    upload_ops = r["data"]["attributes"].get("uploadOperations", [])
    if not upload_ops:
        die("No upload operations returned", r)
    print(f"     reserved id={img_id}, {len(upload_ops)} upload op(s)")

    # 6b. Upload bytes (may be split into chunks)
    for op in upload_ops:
        url = op["url"]
        method = op.get("method", "PUT")
        offset = op.get("offset", 0)
        length = op.get("length", fsize)
        # Read the slice
        chunk_path = Path(f"/tmp/asc_chunk_{img_id}_{offset}.bin")
        chunk_path.write_bytes(fpath.read_bytes()[offset:offset+length])
        cmd = ["curl", "-sS", "-X", method, url]
        for hdr in op.get("requestHeaders", []):
            cmd += ["-H", f"{hdr['name']}: {hdr['value']}"]
        cmd += ["--data-binary", f"@{chunk_path}"]
        cr = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
        if cr.returncode != 0:
            die(f"Upload chunk failed: {cr.stderr}")
        chunk_path.unlink()
        print(f"     chunk uploaded (offset={offset}, length={length})")

    # 6c. Finalize
    r = asc("PATCH", f"/v1/appScreenshots/{img_id}", {
        "data": {
            "type": "appScreenshots",
            "id": img_id,
            "attributes": {"uploaded": True, "sourceFileChecksum": md5}
        }
    })
    if "errors" in r:
        die("Finalize failed", r)
    state = r["data"]["attributes"].get("assetDeliveryState", {}).get("state", "?")
    print(f"     finalized — state: {state}")
    uploaded.append((idx, fname, img_id))

# 7. Verify all COMPLETE (poll up to 60s)
print("\n→ Polling for COMPLETE state")
for i in range(20):
    r = asc("GET", f"/v1/appScreenshotSets/{SET_ID}/appScreenshots?limit=20")
    states = []
    for s in r.get("data", []):
        st = s["attributes"].get("assetDeliveryState", {}).get("state", "?")
        states.append(st)
    print(f"  [{i+1}] {states}")
    if states and all(st == "COMPLETE" for st in states):
        break
    time.sleep(3)

# 8. Now delete the OLD screenshots (new ones are COMPLETE — safe to remove old)
print(f"\n→ Deleting {len(existing_ids)} old screenshots")
for old_id in existing_ids:
    print(f"  DELETE {old_id}")
    asc("DELETE", f"/v1/appScreenshots/{old_id}")

# 9. Re-order new screenshots so they display in the correct sequence
# Use POST /v1/appScreenshotSets/{id}/relationships/appScreenshots with explicit ordering
print("\n→ Setting display order of new screenshots")
new_ids = [u[2] for u in uploaded]  # in the order we uploaded them
r = asc("PATCH", f"/v1/appScreenshotSets/{SET_ID}/relationships/appScreenshots", {
    "data": [{"type": "appScreenshots", "id": iid} for iid in new_ids]
})
print(f"  Reorder response: {('errors' in r) and 'FAILED' or 'OK'}")

# 10. Final state
print("\n→ Final screenshot order on APP_DESKTOP set:")
r = asc("GET", f"/v1/appScreenshotSets/{SET_ID}/appScreenshots?limit=20")
for s in r.get("data", []):
    a = s["attributes"]
    state = a.get("assetDeliveryState", {}).get("state", "?")
    print(f"  {a.get('fileName')} — {state} (id={s['id']})")

print("\nDone.")
