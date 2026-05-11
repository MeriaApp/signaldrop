#!/bin/bash
# Uninstaller for SignalDrop direct-distribution installs.
# Removes the LaunchAgent (from Scripts/install.sh) AND the /Applications
# bundle if present. Preserves the event database by default — pass --purge
# to wipe it.
set -euo pipefail

BUNDLE_ID="com.meria.signaldrop"
APP_NAME="SignalDrop"
INSTALL_DIR="$HOME/Library/Application Support/$APP_NAME"
LAUNCH_AGENT="$HOME/Library/LaunchAgents/$BUNDLE_ID.plist"
BINARY="$INSTALL_DIR/signaldrop"
LOG_FILE="$INSTALL_DIR/signaldrop.log"
APP_BUNDLE="/Applications/$APP_NAME.app"

echo "Stopping $APP_NAME..."
launchctl bootout "gui/$(id -u)/$BUNDLE_ID" 2>/dev/null || true
pkill -f "$APP_NAME.app/Contents/MacOS/$APP_NAME" 2>/dev/null || true

if [ -f "$LAUNCH_AGENT" ]; then
    echo "Removing LaunchAgent..."
    rm -f "$LAUNCH_AGENT"
fi

if [ -f "$BINARY" ]; then
    echo "Removing direct-install binary..."
    rm -f "$BINARY" "$LOG_FILE"
fi

if [ -d "$APP_BUNDLE" ]; then
    echo "Removing $APP_BUNDLE..."
    rm -rf "$APP_BUNDLE"
fi

if [ "${1:-}" = "--purge" ]; then
    echo "Purging event database and preferences..."
    rm -rf "$INSTALL_DIR"
    defaults delete "$BUNDLE_ID" 2>/dev/null || true
else
    if [ -f "$INSTALL_DIR/events.db" ]; then
        echo "Event database preserved at: $INSTALL_DIR/events.db"
        echo "Run with --purge to remove everything."
    fi
fi

echo ""
echo "$APP_NAME uninstalled."
