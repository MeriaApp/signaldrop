#!/bin/bash
# Build, sign, notarize, and staple the SignalDrop Direct-Distribution .app.
#
# Single source of truth for the version is project.yml — this script parses
# MARKETING_VERSION and CURRENT_PROJECT_VERSION from there instead of carrying
# its own copy.
#
# Notarization is HARD-required. If credentials aren't set up the script
# exits non-zero; we never ship an unstapled bundle.
set -euo pipefail

cd "$(cd "$(dirname "$0")/.." && pwd)"

APP_NAME="SignalDrop"
TEAM_ID="36D97ZTP6J"
# Direct-Distribution scheme — separate from the App Store target so the
# DMG binary links Sparkle and the App Store binary doesn't.
SCHEME="SignalDropDirect"
PROJECT="$APP_NAME.xcodeproj"
NOTARIZE_PROFILE="${NOTARIZE_PROFILE:-notarytool}"

# Pull version from project.yml so we can't ship a mismatched DMG.
VERSION=$(awk -F'"' '/^[[:space:]]*MARKETING_VERSION:/{print $2; exit}' project.yml)
BUILD=$(awk -F'"' '/^[[:space:]]*CURRENT_PROJECT_VERSION:/{print $2; exit}' project.yml)
if [ -z "$VERSION" ] || [ -z "$BUILD" ]; then
    echo "ERROR: could not parse MARKETING_VERSION / CURRENT_PROJECT_VERSION from project.yml"
    exit 1
fi

BUILD_DIR=".build/app"
ARCHIVE_PATH="$BUILD_DIR/$APP_NAME.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
APP_BUNDLE="$EXPORT_DIR/$APP_NAME.app"
ZIP_PATH="$BUILD_DIR/$APP_NAME-$VERSION.zip"

echo "=== Building $APP_NAME v$VERSION ($BUILD) ==="
echo

# Step 1: regenerate Xcode project from project.yml (single source of truth)
echo "[1/6] Regenerating Xcode project from project.yml..."
xcodegen generate --quiet
echo "  done"

# Step 2: archive — ReleaseDirect config (no sandbox, no APPSTORE flag,
# Sparkle compiled in, Developer ID signed)
echo "[2/6] Archiving ReleaseDirect (universal arm64 + x86_64)..."
mv "$ARCHIVE_PATH" "$ARCHIVE_PATH.old.$(date +%s)" 2>/dev/null || true
xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration ReleaseDirect \
    -archivePath "$ARCHIVE_PATH" \
    -destination 'generic/platform=macOS' \
    ARCHS="arm64 x86_64" \
    ONLY_ACTIVE_ARCH=NO \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    -quiet
[ -d "$ARCHIVE_PATH" ] || { echo "ERROR: archive failed"; exit 1; }
echo "  Archive: $ARCHIVE_PATH"

# Step 3: export Developer ID-signed .app
echo "[3/6] Exporting Developer ID .app..."
mv "$EXPORT_DIR" "$EXPORT_DIR.old.$(date +%s)" 2>/dev/null || true
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_DIR" \
    -exportOptionsPlist ExportOptions-DirectDistribution.plist \
    -quiet
[ -d "$APP_BUNDLE" ] || { echo "ERROR: export failed"; exit 1; }

ARCHS_OUT=$(lipo -archs "$APP_BUNDLE/Contents/MacOS/$APP_NAME" 2>/dev/null || echo "?")
echo "  App: $APP_BUNDLE"
echo "  Arches: $ARCHS_OUT"
if [[ "$ARCHS_OUT" != *"arm64"* ]] || [[ "$ARCHS_OUT" != *"x86_64"* ]]; then
    echo "ERROR: binary is not universal (got '$ARCHS_OUT')"
    exit 1
fi

# Step 4: notarize (HARD-required — no silent fallback)
echo "[4/6] Notarizing..."
mkdir -p "$BUILD_DIR"
rm -f "$ZIP_PATH"
ditto -c -k --keepParent "$APP_BUNDLE" "$ZIP_PATH"

if ! xcrun notarytool submit "$ZIP_PATH" \
        --keychain-profile "$NOTARIZE_PROFILE" \
        --wait; then
    echo
    echo "ERROR: notarization failed. Apps without notarization tickets will"
    echo "trigger a Gatekeeper warning. Refusing to ship."
    echo
    echo "  First-time setup:"
    echo "    xcrun notarytool store-credentials $NOTARIZE_PROFILE \\"
    echo "      --apple-id YOUR_APPLE_ID \\"
    echo "      --team-id $TEAM_ID \\"
    echo "      --password YOUR_APP_SPECIFIC_PASSWORD"
    rm -f "$ZIP_PATH"
    exit 1
fi
rm -f "$ZIP_PATH"

# Step 5: staple the ticket onto the bundle
echo "[5/6] Stapling notarization ticket..."
xcrun stapler staple "$APP_BUNDLE"
xcrun stapler validate "$APP_BUNDLE"
echo "  Stapled and validated."

# Step 6: Gatekeeper assessment — exactly what a real user's Mac would do
echo "[6/6] Gatekeeper assessment..."
if ! spctl --assess --type execute --verbose=2 "$APP_BUNDLE" 2>&1 | grep -q "accepted"; then
    echo "ERROR: Gatekeeper rejected the bundle"
    exit 1
fi
echo "  accepted"

echo
echo "=== Build complete ==="
echo "  App:     $APP_BUNDLE"
echo "  Version: $VERSION ($BUILD)"
echo "  Arches:  $ARCHS_OUT"
echo "  Size:    $(du -sh "$APP_BUNDLE" | cut -f1)"
echo
echo "Next: ./Scripts/package-dmg.sh"
