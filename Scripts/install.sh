#!/bin/bash
# Developer convenience: build a SignalDrop .app and install it the way a
# real user would — drag-to-Applications, then launch. Login-at-startup is
# the app's responsibility via SMAppService (toggle from the menu).
#
# This is NOT the user-facing distribution path — for that, ship the DMG
# produced by Scripts/build-app.sh + Scripts/package-dmg.sh.
set -euo pipefail

cd "$(cd "$(dirname "$0")/.." && pwd)"

APP_NAME="SignalDrop"
BUNDLE_ID="com.meria.signaldrop"
DEST="/Applications/$APP_NAME.app"
LEGACY_LAUNCH_AGENT="$HOME/Library/LaunchAgents/$BUNDLE_ID.plist"
LEGACY_INSTALL_DIR="$HOME/Library/Application Support/$APP_NAME"

echo "Building $APP_NAME (ReleaseDirect via Xcode — full feature set + Sparkle)..."
xcodegen generate --quiet
xcodebuild \
    -project "$APP_NAME.xcodeproj" \
    -scheme "SignalDropDirect" \
    -configuration ReleaseDirect \
    -destination 'platform=macOS' \
    -derivedDataPath ".build/derived" \
    -quiet \
    build

BUILT="$(find .build/derived/Build/Products/ReleaseDirect -maxdepth 1 -name "$APP_NAME.app" -type d | head -1)"
[ -n "$BUILT" ] && [ -d "$BUILT" ] || { echo "ERROR: build failed — $APP_NAME.app not produced"; exit 1; }

echo "Stopping any running instance..."
pkill -f "$APP_NAME.app/Contents/MacOS/$APP_NAME" 2>/dev/null || true
sleep 1

# Clean up legacy LaunchAgent / Application Support binary from older
# install.sh versions so they don't keep relaunching a stale build.
if [ -f "$LEGACY_LAUNCH_AGENT" ]; then
    echo "Removing legacy LaunchAgent..."
    launchctl bootout "gui/$(id -u)/$BUNDLE_ID" 2>/dev/null || true
    rm -f "$LEGACY_LAUNCH_AGENT"
fi
if [ -f "$LEGACY_INSTALL_DIR/signaldrop" ]; then
    echo "Removing legacy binary at $LEGACY_INSTALL_DIR/signaldrop..."
    rm -f "$LEGACY_INSTALL_DIR/signaldrop" "$LEGACY_INSTALL_DIR/signaldrop.log"
fi

echo "Installing to $DEST..."
rm -rf "$DEST"
cp -R "$BUILT" "$DEST"

echo "Launching..."
open "$DEST"

echo
echo "$APP_NAME installed."
echo "  App:  $DEST"
echo "  Data: $LEGACY_INSTALL_DIR/events.db"
echo
echo "Enable 'Launch at Login' from the $APP_NAME menu to start on boot."
