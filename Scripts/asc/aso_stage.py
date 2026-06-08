#!/usr/bin/env python3
"""
SignalDrop ASO overhaul — validate + (gated) stage metadata. 2026-06.

DEFAULT = --dry-run: validates the FINAL strings against every ASO rule
(char limits, cross-field de-duplication, atomization) and prints the exact
PATCH operations that would run. Touches ASC NOT AT ALL.

--execute: creates a new 1.2.0 MAC_OS version (PREPARE_FOR_SUBMISSION),
stages Subtitle (appInfoLocalizations) + Keywords (the new version's
appStoreVersionLocalizations), keeps the strong existing Description, then
READS BACK every field. It NEVER POSTs a submission and NEVER edits the live
1.1.0 promo text. Name is unchanged. Reversible (the draft version is
deletable in ASC).

Why a new version is required: all live versions are READY_FOR_SALE, so Name/
Subtitle/Keywords are indexed fields that can only change by riding the next
binary through review. This overhaul rides 1.2.0 (which also carries the new
ratings prompt). Run --execute alongside the 1.2.0 build, with Jesse's go.
"""
import argparse, json, time, subprocess, sys, re
from pathlib import Path
import jwt

ISSUER = subprocess.check_output(
    "grep -E '^(export )?ASC_API_ISSUER_ID=' ~/.keys | cut -d= -f2-",
    shell=True, text=True).strip().strip('"').strip("'")
KEY = (Path.home() / ".private_keys/AuthKey_5RDJ5SQ5LK.p8").read_text()
KID = "5RDJ5SQ5LK"
APP_ID = "6761185430"
NEW_VERSION = "1.2.0"
PLATFORM = "MAC_OS"

# ── FINAL strings (approved 2026-06-07) ───────────────────────────────────
NAME     = "SignalDrop - WiFi Monitor"            # KEEP (indexed)
SUBTITLE = "Network uptime & outage alerts"       # NEW  (indexed)
KEYWORDS = "disconnect,signal,strength,internet,connection,menubar,drop,isp,latency,ping,speed,status,router"
# Description: keep the strong 2199-char v1.1.0 copy (carried forward by ASC).
# Promo text: NOT touched here (the only live-editable/no-review lever; Jesse
# can refresh it anytime). What's New: set with the 1.2.0 binary.

LIMITS = {"Name": 30, "Subtitle": 30, "Keywords": 100}


# ── validation ────────────────────────────────────────────────────────────
def tokens(s):
    """ASO-relevant word tokens (lowercased, punctuation/short-words dropped)."""
    raw = re.split(r"[\s,/&\-]+", s.lower())
    stop = {"", "the", "a", "an", "&", "and", "to", "for", "of"}
    return [t for t in raw if t and t not in stop]


def validate():
    print("=" * 72)
    print("VALIDATION  (deterministic — no network)")
    ok = True

    # 1. char limits
    for label, val in (("Name", NAME), ("Subtitle", SUBTITLE), ("Keywords", KEYWORDS)):
        n = len(val)
        passed = n <= LIMITS[label]
        ok &= passed
        print(f"  [{'PASS' if passed else 'FAIL'}] {label}: {n}/{LIMITS[label]}  {val!r}")

    # 2. cross-field de-duplication (the load-bearing ASO negative criterion)
    name_t, sub_t, kw_t = tokens(NAME), tokens(SUBTITLE), [k.strip().lower() for k in KEYWORDS.split(",")]
    print(f"\n  Name tokens     : {name_t}")
    print(f"  Subtitle tokens : {sub_t}")
    print(f"  Keyword atoms   : {kw_t}")
    all_sets = {"Name": set(name_t), "Subtitle": set(sub_t), "Keywords": set(kw_t)}
    dup_found = False
    fields = list(all_sets.items())
    for i in range(len(fields)):
        for j in range(i + 1, len(fields)):
            (na, sa), (nb, sb) = fields[i], fields[j]
            inter = sa & sb
            if inter:
                dup_found = True
                print(f"  [FAIL] duplicate token(s) across {na} ↔ {nb}: {sorted(inter)}")
    if not dup_found:
        print("  [PASS] no token duplicated across Name / Subtitle / Keywords")
    ok &= not dup_found

    # 3. keyword hygiene: no spaces, no empties, no dup atoms
    atoms = [k.strip() for k in KEYWORDS.split(",")]
    space_bad = [k for k in atoms if " " in k]
    empty_bad = [k for k in atoms if not k]
    dup_atoms = sorted({k for k in atoms if atoms.count(k) > 1})
    kw_ok = not (space_bad or empty_bad or dup_atoms)
    print(f"\n  [{'PASS' if kw_ok else 'FAIL'}] keyword atoms clean "
          f"(count={len(atoms)}, spaces={space_bad}, empties={len(empty_bad)}, dups={dup_atoms})")
    ok &= kw_ok

    # 4. phrases the algorithm can form (Name+Subtitle+Keywords recombine in-locale)
    print("\n  Indexable phrases formed (sample):")
    for p in ["wifi disconnect", "wifi signal", "signal strength", "wifi strength",
              "internet drop", "wifi drop", "network connection", "menubar monitor",
              "internet speed", "wifi speed", "isp outage", "wifi status",
              "network status", "wifi router", "latency monitor", "ping monitor",
              "network uptime", "outage alerts", "wifi monitor"]:
        print(f"    · {p}")

    print("\n  " + ("ALL VALIDATION PASS ✅" if ok else "VALIDATION FAILED ❌"))
    return ok


# ── ASC plumbing (only used with --execute) ───────────────────────────────
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


def planned_ops():
    print("=" * 72)
    print("PLANNED ASC OPERATIONS  (--execute would run these; --dry-run does NOT)")
    print(f"  1. POST /v1/appStoreVersions  → create {NEW_VERSION} ({PLATFORM}), state PREPARE_FOR_SUBMISSION")
    print(f"  2. PATCH editable appInfoLocalizations(en-US)  attributes.subtitle = {SUBTITLE!r}")
    print(f"     (Name unchanged: {NAME!r})")
    print(f"  3. PATCH new version's appStoreVersionLocalizations(en-US)  attributes.keywords = {KEYWORDS!r}")
    print(f"     (Description carried forward unchanged; promo NOT touched; whatsNew set with the build)")
    print(f"  4. GET read-back of every staged field")
    print(f"  5. STOP. No submission POSTed. Live 1.1.0 untouched.")


def execute():
    print("=" * 72)
    print("EXECUTE — staging to ASC (NO submission will be POSTed)")
    # 1. create version
    r = asc("POST", "/v1/appStoreVersions", {
        "data": {"type": "appStoreVersions",
                 "attributes": {"platform": PLATFORM, "versionString": NEW_VERSION},
                 "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}}}})
    if "errors" in r:
        print("create-version ERROR:", json.dumps(r, indent=2)[:1200]); sys.exit(1)
    vid = r["data"]["id"]
    print(f"  created version id={vid} state={r['data']['attributes'].get('appStoreState') or r['data']['attributes'].get('appVersionState')}")

    # 2. subtitle → editable appInfoLocalization
    infos = asc("GET", f"/v1/apps/{APP_ID}/appInfos")
    sub_loc_id = None
    for info in infos.get("data", []):
        st = info["attributes"].get("appStoreState") or info["attributes"].get("state")
        if st in ("READY_FOR_SALE", "REPLACED_WITH_NEW_INFO"):
            continue
        locs = asc("GET", f"/v1/appInfos/{info['id']}/appInfoLocalizations")
        for loc in locs.get("data", []):
            if loc["attributes"].get("locale") == "en-US":
                sub_loc_id = loc["id"]
    if not sub_loc_id:
        # fall back: any en-US appInfoLocalization editable post-version-create
        for info in infos.get("data", []):
            locs = asc("GET", f"/v1/appInfos/{info['id']}/appInfoLocalizations")
            for loc in locs.get("data", []):
                if loc["attributes"].get("locale") == "en-US":
                    sub_loc_id = loc["id"]
    print(f"  appInfoLocalization(en-US) id={sub_loc_id}")
    r = asc("PATCH", f"/v1/appInfoLocalizations/{sub_loc_id}", {
        "data": {"type": "appInfoLocalizations", "id": sub_loc_id,
                 "attributes": {"subtitle": SUBTITLE}}})
    if "errors" in r:
        print("subtitle PATCH ERROR:", json.dumps(r, indent=2)[:1200]); sys.exit(1)

    # 3. keywords → new version's localization
    vlocs = asc("GET", f"/v1/appStoreVersions/{vid}/appStoreVersionLocalizations")
    kw_loc_id = next((l["id"] for l in vlocs.get("data", [])
                      if l["attributes"].get("locale") == "en-US"), None)
    print(f"  appStoreVersionLocalization(en-US) id={kw_loc_id}")
    r = asc("PATCH", f"/v1/appStoreVersionLocalizations/{kw_loc_id}", {
        "data": {"type": "appStoreVersionLocalizations", "id": kw_loc_id,
                 "attributes": {"keywords": KEYWORDS}}})
    if "errors" in r:
        print("keywords PATCH ERROR:", json.dumps(r, indent=2)[:1200]); sys.exit(1)

    # 4. read-back
    print("\n  READ-BACK:")
    si = asc("GET", f"/v1/appInfoLocalizations/{sub_loc_id}")["data"]["attributes"]
    ki = asc("GET", f"/v1/appStoreVersionLocalizations/{kw_loc_id}")["data"]["attributes"]
    print(f"    name     = {si.get('name')!r}")
    print(f"    subtitle = {si.get('subtitle')!r}  ({'OK' if si.get('subtitle')==SUBTITLE else 'MISMATCH'})")
    print(f"    keywords = {ki.get('keywords')!r}  ({'OK' if ki.get('keywords')==KEYWORDS else 'MISMATCH'})")
    print(f"    desc len = {len(ki.get('description') or '')}")
    print("\n  STAGED. No submission POSTed. Submit 1.2.0 (build + this metadata) only on Jesse's go.")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--execute", action="store_true",
                    help="Actually create the 1.2.0 draft + stage (default is dry-run; never submits).")
    args = ap.parse_args()

    valid = validate()
    planned_ops()
    if args.execute:
        if not valid:
            print("\nRefusing to execute: validation failed."); sys.exit(1)
        execute()
    else:
        print("\n(--dry-run) Nothing was sent to ASC. Re-run with --execute on Jesse's go.")
