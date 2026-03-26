#!/bin/bash
set -euo pipefail

BUNDLE_ID="com.meria.signaldrop"
INSTALL_DIR="$HOME/Library/Application Support/SignalDrop"
LAUNCH_AGENT="$HOME/Library/LaunchAgents/$BUNDLE_ID.plist"

echo "Stopping SignalDrop..."
launchctl bootout "gui/$(id -u)/$BUNDLE_ID" 2>/dev/null || true

echo "Removing LaunchAgent..."
rm -f "$LAUNCH_AGENT"

echo "Removing binary..."
rm -f "$INSTALL_DIR/dropout"
rm -f "$INSTALL_DIR/dropout.log"

# Keep the database unless --purge is passed
if [ "${1:-}" = "--purge" ]; then
    echo "Purging event database..."
    rm -rf "$INSTALL_DIR"
else
    echo "Event database preserved at: $INSTALL_DIR/events.db"
    echo "Run with --purge to remove everything."
fi

echo ""
echo "SignalDrop uninstalled."
