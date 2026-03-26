#!/bin/bash
set -euo pipefail

APP_NAME="SignalDrop"
BUNDLE_ID="com.meria.signaldrop"
INSTALL_DIR="$HOME/Library/Application Support/SignalDrop"
LAUNCH_AGENT="$HOME/Library/LaunchAgents/$BUNDLE_ID.plist"
BINARY="$INSTALL_DIR/signaldrop"

echo "Building SignalDrop..."
cd "$(dirname "$0")/.."
swift build -c release 2>&1

BUILT_BINARY=".build/release/signaldrop"
if [ ! -f "$BUILT_BINARY" ]; then
    echo "Build failed."
    exit 1
fi

echo "Installing to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
cp "$BUILT_BINARY" "$BINARY"
chmod +x "$BINARY"

# Create LaunchAgent for auto-start
echo "Creating LaunchAgent..."
cat > "$LAUNCH_AGENT" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$BUNDLE_ID</string>
    <key>ProgramArguments</key>
    <array>
        <string>$BINARY</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <dict>
        <key>Crashed</key>
        <true/>
    </dict>
    <key>ProcessType</key>
    <string>Interactive</string>
    <key>StandardErrorPath</key>
    <string>$INSTALL_DIR/signaldrop.log</string>
</dict>
</plist>
EOF

# Load the agent
echo "Starting SignalDrop..."
launchctl bootout "gui/$(id -u)/$BUNDLE_ID" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$LAUNCH_AGENT"

echo ""
echo "SignalDrop installed and running."
echo "  Binary: $BINARY"
echo "  Agent:  $LAUNCH_AGENT"
echo "  Log:    $INSTALL_DIR/signaldrop.log"
echo "  Data:   $INSTALL_DIR/events.db"
echo ""
echo "Look for the WiFi icon in your menu bar."
