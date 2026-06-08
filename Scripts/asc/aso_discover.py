#!/usr/bin/env python3
"""
READ-ONLY ASC discovery for SignalDrop's 2026-06 ASO overhaul.
Prints the current Name/Subtitle/Keywords/Description/Promo, the editable-version
state, category set, and all the IDs needed to stage edits. Stages NOTHING.
"""
import json, time, subprocess, sys
from pathlib import Path
import jwt

ISSUER = subprocess.check_output(
    "grep -E '^(export )?ASC_API_ISSUER_ID=' ~/.keys | cut -d= -f2-",
    shell=True, text=True).strip().strip('"').strip("'")
KEY = (Path.home() / ".private_keys/AuthKey_5RDJ5SQ5LK.p8").read_text()
KID = "5RDJ5SQ5LK"
APP_ID = "6761185430"


def tok():
    return jwt.encode(
        {"iss": ISSUER, "iat": int(time.time()), "exp": int(time.time()) + 1200,
         "aud": "appstoreconnect-v1"},
        KEY, algorithm="ES256", headers={"kid": KID, "typ": "JWT"})


def asc(method, path, data=None):
    cmd = ["curl", "-sS", "-X", method,
           "https://api.appstoreconnect.apple.com" + path,
           "-H", f"Authorization: Bearer {tok()}"]
    if data is not None:
        tf = Path(f"/tmp/asc_payload_{int(time.time()*1000)}.json")
        tf.write_text(json.dumps(data))
        cmd += ["-H", "Content-Type: application/json", "--data-binary", f"@{tf}"]
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    return json.loads(r.stdout) if r.stdout.strip() else {}


def show(label, val, cap=None):
    if isinstance(val, str):
        n = len(val)
        head = val if cap is None else (val[:cap] + ("…" if len(val) > cap else ""))
        print(f"  {label} ({n} chars): {head!r}")
    else:
        print(f"  {label}: {val}")


print("=" * 70)
print("APP")
app = asc("GET", f"/v1/apps/{APP_ID}")
if "errors" in app:
    print(json.dumps(app, indent=2)[:1500]); sys.exit(1)
a = app["data"]["attributes"]
print(f"  name={a.get('name')!r} bundleId={a.get('bundleId')!r} sku={a.get('sku')!r} "
      f"primaryLocale={a.get('primaryLocale')!r}")

print("=" * 70)
print("APP INFOS  (Name, Subtitle, Categories)")
infos = asc("GET", f"/v1/apps/{APP_ID}/appInfos")
for info in infos.get("data", []):
    iid = info["id"]
    iattr = info["attributes"]
    print(f"\n  appInfo id={iid}  state={iattr.get('appStoreState') or iattr.get('state')}")
    # categories
    rel = info.get("relationships", {})
    for cat_key in ("primaryCategory", "secondaryCategory"):
        c = rel.get(cat_key, {}).get("data")
        print(f"    {cat_key}: {c}")
    locs = asc("GET", f"/v1/appInfos/{iid}/appInfoLocalizations")
    for loc in locs.get("data", []):
        la = loc["attributes"]
        if la.get("locale") not in ("en-US", None):
            continue
        print(f"    loc id={loc['id']} locale={la.get('locale')}")
        show("name", la.get("name") or "")
        show("subtitle", la.get("subtitle") or "")

print("=" * 70)
print("APP STORE VERSIONS")
vers = asc("GET", f"/v1/apps/{APP_ID}/appStoreVersions?limit=10")
for v in vers.get("data", []):
    vid = v["id"]
    va = v["attributes"]
    print(f"\n  version id={vid}  versionString={va.get('versionString')}  "
          f"state={va.get('appStoreState') or va.get('appVersionState')}  "
          f"platform={va.get('platform')}")
    vlocs = asc("GET", f"/v1/appStoreVersions/{vid}/appStoreVersionLocalizations")
    for loc in vlocs.get("data", []):
        la = loc["attributes"]
        if la.get("locale") not in ("en-US",):
            continue
        print(f"    verLoc id={loc['id']} locale={la.get('locale')}")
        show("keywords", la.get("keywords") or "")
        show("promotionalText", la.get("promotionalText") or "")
        show("description", la.get("description") or "", cap=120)
        show("whatsNew", la.get("whatsNew") or "", cap=120)
        show("marketingUrl", la.get("marketingUrl") or "")
        show("supportUrl", la.get("supportUrl") or "")

print("=" * 70)
print("DONE (read-only — nothing staged)")
