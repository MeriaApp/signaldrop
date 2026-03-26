#!/bin/bash
set -euo pipefail

APP_NAME="Dropout"
VERSION="1.0.0"

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/.build/app"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
DMG_DIR="$BUILD_DIR/dmg"
DMG_PATH="$BUILD_DIR/$APP_NAME-$VERSION.dmg"

cd "$PROJECT_ROOT"

if [ ! -d "$APP_BUNDLE" ]; then
    echo "ERROR: App bundle not found at $APP_BUNDLE"
    echo "Run ./Scripts/build-app.sh first."
    exit 1
fi

echo "=== Packaging $APP_NAME v$VERSION DMG ==="

# Check for create-dmg (brew install create-dmg)
if command -v create-dmg &>/dev/null; then
    echo "Using create-dmg for professional DMG..."
    rm -f "$DMG_PATH"

    create-dmg \
        --volname "$APP_NAME $VERSION" \
        --volicon "$APP_BUNDLE/Contents/Resources/AppIcon.icns" \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 100 \
        --icon "$APP_NAME.app" 150 185 \
        --hide-extension "$APP_NAME.app" \
        --app-drop-link 450 185 \
        --no-internet-enable \
        "$DMG_PATH" \
        "$APP_BUNDLE" 2>&1 || true  # create-dmg exits 2 on success sometimes

    if [ -f "$DMG_PATH" ]; then
        echo ""
        echo "=== DMG created ==="
        echo "  Path: $DMG_PATH"
        echo "  Size: $(du -h "$DMG_PATH" | cut -f1)"
        exit 0
    fi

    echo "create-dmg failed, falling back to hdiutil..."
fi

# Fallback: basic DMG with hdiutil
echo "Creating DMG with hdiutil..."
rm -rf "$DMG_DIR"
mkdir -p "$DMG_DIR"

# Copy app
cp -R "$APP_BUNDLE" "$DMG_DIR/"

# Create Applications symlink
ln -s /Applications "$DMG_DIR/Applications"

# Create DMG
rm -f "$DMG_PATH"
hdiutil create -volname "$APP_NAME $VERSION" \
    -srcfolder "$DMG_DIR" \
    -ov -format UDZO \
    "$DMG_PATH" 2>&1

# Sign the DMG
DEVELOPER_ID="Developer ID Application: JESSE ROBERT MERIA (36D97ZTP6J)"
codesign --force --sign "$DEVELOPER_ID" "$DMG_PATH" 2>&1 || true

# Notarize the DMG
NOTARIZE_PROFILE="${NOTARIZE_PROFILE:-notarytool}"
if xcrun notarytool submit "$DMG_PATH" \
    --keychain-profile "$NOTARIZE_PROFILE" \
    --wait 2>&1; then
    xcrun stapler staple "$DMG_PATH" 2>&1
    echo "  DMG notarized and stapled."
else
    echo "  DMG not notarized (credentials not configured)."
fi

# Cleanup
rm -rf "$DMG_DIR"

echo ""
echo "=== DMG created ==="
echo "  Path: $DMG_PATH"
echo "  Size: $(du -h "$DMG_PATH" | cut -f1)"
echo ""
echo "Ready to distribute."
