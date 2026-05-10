#!/usr/bin/env python3
"""
Submit SignalDrop v1.0.1 for App Review.

Uses the reviewSubmissions API:
  1. POST /v1/reviewSubmissions to create a submission for the platform
  2. POST /v1/reviewSubmissionItems linking the appStoreVersion
  3. PATCH /v1/reviewSubmissions/{id} with submitted=true to send to Apple
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
    cmd = ["curl","-sS","-X", method, BASE + path, "-H", f"Authorization: Bearer {tok()}"]
    if data is not None:
        tf = Path(f"/tmp/asc_payload_{int(time.time()*1000)}.json")
        tf.write_text(json.dumps(data))
        cmd += ["-H", "Content-Type: application/json", "--data-binary", f"@{tf}"]
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    return json.loads(r.stdout) if r.stdout.strip() else {}

APP_ID = "6761185430"
VER_ID = "6b3b62d3-9d2d-41fb-8e13-7715471d9920"

# 1. Check current state — is the version ready to submit?
print("→ Checking current version state")
v = asc("GET", f"/v1/appStoreVersions/{VER_ID}?include=build,appStoreVersionPhasedRelease,appStoreReviewDetail")
attrs = v["data"]["attributes"]
print(f"  versionString: {attrs['versionString']}")
print(f"  appStoreState: {attrs['appStoreState']}")
print(f"  usesIdfa: {attrs.get('usesIdfa')}")

# 2. Check existing reviewSubmissions for the app
print("\n→ Checking existing reviewSubmissions")
r = asc("GET", f"/v1/reviewSubmissions?filter%5Bapp%5D={APP_ID}&filter%5Bplatform%5D=MAC_OS&limit=10")
existing_submission = None
for s in r.get("data", []):
    sa = s["attributes"]
    print(f"  Submission {s['id']} state={sa.get('state')} platform={sa.get('platform')} submittedDate={sa.get('submittedDate')}")
    if sa.get("state") in ("READY_FOR_REVIEW",):
        existing_submission = s

# 3. Set usesIdfa to false (we don't use IDFA)
if attrs.get('usesIdfa') is None:
    print("\n→ Setting usesIdfa=false")
    r = asc("PATCH", f"/v1/appStoreVersions/{VER_ID}", {
        "data": {"type": "appStoreVersions", "id": VER_ID, "attributes": {"usesIdfa": False}}
    })
    if "errors" in r:
        print("PATCH usesIdfa:", json.dumps(r, indent=2)[:1000])

# 4. Create a new reviewSubmission if none in READY_FOR_REVIEW
if not existing_submission:
    print("\n→ Creating reviewSubmission")
    r = asc("POST", "/v1/reviewSubmissions", {
        "data": {
            "type": "reviewSubmissions",
            "attributes": {"platform": "MAC_OS"},
            "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}}
        }
    })
    if "errors" in r:
        print("Create submission failed:")
        print(json.dumps(r, indent=2)[:2000])
        sys.exit(1)
    sub_id = r["data"]["id"]
    print(f"  Submission id={sub_id}")
else:
    sub_id = existing_submission["id"]
    print(f"  Reusing existing submission id={sub_id}")

# 5. Add the version as an item
print("\n→ Adding v1.0.1 to submission")
r = asc("POST", "/v1/reviewSubmissionItems", {
    "data": {
        "type": "reviewSubmissionItems",
        "relationships": {
            "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sub_id}},
            "appStoreVersion": {"data": {"type": "appStoreVersions", "id": VER_ID}}
        }
    }
})
if "errors" in r:
    err = r["errors"][0]
    if "ENTITY_ERROR.RELATIONSHIP" in err.get("code", "") and "duplicate" in err.get("detail", "").lower():
        print("  Already linked — proceeding")
    else:
        print("Add item failed:")
        print(json.dumps(r, indent=2)[:1500])
        # Continue — might already be linked
else:
    print(f"  Item linked: {r['data']['id']}")

# 6. Submit
print("\n→ Submitting for review")
r = asc("PATCH", f"/v1/reviewSubmissions/{sub_id}", {
    "data": {
        "type": "reviewSubmissions",
        "id": sub_id,
        "attributes": {"submitted": True}
    }
})
if "errors" in r:
    print("Submit failed:")
    print(json.dumps(r, indent=2)[:2000])
    sys.exit(1)

print("\n✓ Submitted!")
print(f"  state: {r['data']['attributes'].get('state')}")
print(f"  submittedDate: {r['data']['attributes'].get('submittedDate')}")

# Verify version state
v = asc("GET", f"/v1/appStoreVersions/{VER_ID}")
print(f"  appStoreState: {v['data']['attributes']['appStoreState']}")
