#!/bin/bash
# Package the previously-built SignalDrop .app into a signed, notarized,
# stapled DMG. Reads the version from project.yml so the DMG name and the
# bundle inside it never drift.
#
# Requires:
#   - Scripts/build-app.sh to have completed (.build/app/export/SignalDrop.app)
#   - create-dmg installed (brew install create-dmg)
#   - notarytool credentials stored under keychain-profile "notarytool"
#     (override with NOTARIZE_PROFILE env var)
set -euo pipefail

cd "$(cd "$(dirname "$0")/.." && pwd)"

APP_NAME="SignalDrop"
TEAM_ID="36D97ZTP6J"
DEVELOPER_ID="Developer ID Application: JESSE ROBERT MERIA ($TEAM_ID)"
NOTARIZE_PROFILE="${NOTARIZE_PROFILE:-notarytool}"

VERSION=$(awk -F'"' '/^[[:space:]]*MARKETING_VERSION:/{print $2; exit}' project.yml)
[ -n "$VERSION" ] || { echo "ERROR: could not parse MARKETING_VERSION from project.yml"; exit 1; }

BUILD_DIR=".build/app"
APP_BUNDLE="$BUILD_DIR/export/$APP_NAME.app"
DMG_PATH="$BUILD_DIR/$APP_NAME-$VERSION.dmg"

if [ ! -d "$APP_BUNDLE" ]; then
    echo "ERROR: $APP_BUNDLE not found — run ./Scripts/build-app.sh first."
    exit 1
fi

if ! command -v create-dmg &>/dev/null; then
    echo "ERROR: create-dmg not installed. Install with: brew install create-dmg"
    exit 1
fi

echo "=== Packaging $APP_NAME v$VERSION DMG ==="
rm -f "$DMG_PATH"

# 600×400 window, app on the left, /Applications shortcut on the right,
# hidden bundle extension (so the icon reads "SignalDrop" not "SignalDrop.app"),
# no internet-enable (deprecated; would warn on launch).
create-dmg \
    --volname "$APP_NAME $VERSION" \
    --volicon "$APP_BUNDLE/Contents/Resources/AppIcon.icns" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 128 \
    --icon "$APP_NAME.app" 150 200 \
    --hide-extension "$APP_NAME.app" \
    --app-drop-link 450 200 \
    --no-internet-enable \
    --skip-jenkins \
    "$DMG_PATH" \
    "$APP_BUNDLE"

[ -f "$DMG_PATH" ] || { echo "ERROR: DMG creation failed"; exit 1; }

# Sign the DMG itself (Gatekeeper validates the outer DMG too).
echo "Signing DMG..."
codesign --force --sign "$DEVELOPER_ID" --timestamp "$DMG_PATH"

# Notarize the DMG — best-in-class apps ship notarized containers, not just
# notarized .app bundles. Hard-fail if credentials missing.
echo "Notarizing DMG..."
if ! xcrun notarytool submit "$DMG_PATH" \
        --keychain-profile "$NOTARIZE_PROFILE" \
        --wait; then
    echo "ERROR: DMG notarization failed."
    exit 1
fi

echo "Stapling notarization ticket to DMG..."
xcrun stapler staple "$DMG_PATH"
xcrun stapler validate "$DMG_PATH"

# Verify the DMG-mounted .app still passes Gatekeeper assessment.
echo "Verifying Gatekeeper accepts DMG contents..."
# Parse hdiutil's plist output instead of column-splitting — the volume name
# contains a space ("SignalDrop 1.0.2"), which broke a previous awk parse.
MOUNT_PLIST=$(hdiutil attach -nobrowse -noverify -noautoopen -plist "$DMG_PATH")
MOUNT=$(echo "$MOUNT_PLIST" | python3 -c "
import plistlib, sys
plist = plistlib.loads(sys.stdin.buffer.read())
for entity in plist.get('system-entities', []):
    mp = entity.get('mount-point')
    if mp:
        print(mp)
        break
")
[ -d "$MOUNT" ] || { echo "ERROR: could not determine mount point for $DMG_PATH"; exit 1; }
trap "hdiutil detach -quiet \"$MOUNT\" 2>/dev/null || true" EXIT

if ! spctl --assess --type execute --verbose=2 "$MOUNT/$APP_NAME.app" 2>&1 | grep -q "accepted"; then
    echo "ERROR: Gatekeeper rejected the mounted .app"
    exit 1
fi
echo "  accepted"

echo
echo "=== DMG complete ==="
echo "  Path:    $DMG_PATH"
echo "  Size:    $(du -h "$DMG_PATH" | cut -f1)"
echo "  Version: $VERSION"
echo
echo "Upload to GitHub Releases and update the Sparkle appcast."
