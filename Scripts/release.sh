#!/bin/bash
# End-to-end release for SignalDrop Direct Distribution:
#   1. Build a notarized, stapled, Developer-ID-signed .app bundle
#   2. Package it into a notarized, stapled DMG
#   3. Stage the DMG into the release-archive folder
#   4. Regenerate the Sparkle appcast from the archive (using
#      Sparkle's generate_appcast tool, which signs with the EdDSA
#      private key from the macOS Keychain)
#   5. Copy the appcast into the jessemeria.com signaldrop folder
#
# After this script finishes, commit + deploy jessemeria.com to publish
# the new appcast, and upload the DMG to GitHub Releases for the public
# download link in jessemeria.com/signaldrop/.
set -euo pipefail

cd "$(cd "$(dirname "$0")/.." && pwd)"

APP_NAME="SignalDrop"
ARCHIVE_DIR=".release-archive"
WEBSITE_DIR="$HOME/Developer/jessemeria.com/signaldrop"

VERSION=$(awk -F'"' '/^[[:space:]]*MARKETING_VERSION:/{print $2; exit}' project.yml)
BUILD=$(awk -F'"' '/^[[:space:]]*CURRENT_PROJECT_VERSION:/{print $2; exit}' project.yml)

echo "=== Releasing $APP_NAME v$VERSION ($BUILD) ==="
echo

./Scripts/build-app.sh
./Scripts/package-dmg.sh

DMG=".build/app/$APP_NAME-$VERSION.dmg"
[ -f "$DMG" ] || { echo "ERROR: $DMG not found"; exit 1; }

# Stage the DMG into the release archive. Sparkle's generate_appcast
# scans every DMG in here so the appcast accumulates a history.
mkdir -p "$ARCHIVE_DIR"
cp "$DMG" "$ARCHIVE_DIR/"
echo "Staged DMG in $ARCHIVE_DIR/"

# Locate Sparkle's generate_appcast tool — comes from the SPM dependency
# after a build has resolved the package.
SPARKLE_BIN=$(find ~/Library/Developer/Xcode/DerivedData/SignalDrop-* \
    -path "*/sparkle/Sparkle/bin" -type d 2>/dev/null | head -1)
[ -d "$SPARKLE_BIN" ] || {
    echo "ERROR: Sparkle bin folder not found. Run an Xcode build first to resolve the SPM dependency."
    exit 1
}

echo "Regenerating appcast (signed with EdDSA key from Keychain)..."
"$SPARKLE_BIN/generate_appcast" \
    --link "https://jessemeria.com/signaldrop/" \
    --download-url-prefix "https://github.com/MeriaApp/signaldrop/releases/download/v$VERSION/" \
    "$ARCHIVE_DIR"

[ -f "$ARCHIVE_DIR/appcast.xml" ] || {
    echo "ERROR: generate_appcast didn't produce appcast.xml"
    exit 1
}

echo "Copying appcast to $WEBSITE_DIR/..."
mkdir -p "$WEBSITE_DIR"
cp "$ARCHIVE_DIR/appcast.xml" "$WEBSITE_DIR/appcast.xml"

echo
echo "=== Release artifacts ready ==="
echo "  DMG:     $DMG"
echo "  Archive: $ARCHIVE_DIR/$APP_NAME-$VERSION.dmg"
echo "  Appcast: $WEBSITE_DIR/appcast.xml"
echo
echo "Next steps:"
echo "  1. Upload $DMG to GitHub Releases as v$VERSION (tag v$VERSION)"
echo "     gh release create v$VERSION \"$DMG\" --notes-file CHANGELOG.md"
echo "  2. Commit + deploy jessemeria.com to publish the appcast:"
echo "     cd ~/Developer/jessemeria.com"
echo "     git add signaldrop/appcast.xml"
echo "     git commit -m \"SignalDrop $VERSION appcast\""
echo "     git push  # or vercel --prod if not auto-deploy"
