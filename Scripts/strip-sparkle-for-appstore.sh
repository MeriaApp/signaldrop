#!/bin/bash
# Run as an xcodegen postCompileScript. Removes Sparkle.framework and SU*
# Info.plist keys from the bundle when building the App Store target
# (Release configuration). Sparkle is only valid for Direct Distribution
# (ReleaseDirect) — the framework's mere presence in an App Store bundle
# is bundle bloat and could draw Apple review attention.
#
# This script runs AFTER framework embedding but BEFORE the implicit
# code-sign step, so the bundle gets signed without Sparkle inside.
set -euo pipefail

if [ "${CONFIGURATION:-}" != "Release" ]; then
    echo "strip-sparkle: skipping (CONFIGURATION=$CONFIGURATION, only acts on Release)"
    exit 0
fi

APP="${BUILT_PRODUCTS_DIR}/${TARGET_NAME}.app"
[ -d "$APP" ] || { echo "strip-sparkle: $APP not found"; exit 0; }

SPARKLE="$APP/Contents/Frameworks/Sparkle.framework"
INFO_PLIST="$APP/Contents/Info.plist"

if [ -d "$SPARKLE" ]; then
    echo "strip-sparkle: removing Sparkle.framework from Release bundle"
    rm -rf "$SPARKLE"
fi

FRAMEWORKS_DIR="$APP/Contents/Frameworks"
if [ -d "$FRAMEWORKS_DIR" ] && [ -z "$(ls -A "$FRAMEWORKS_DIR")" ]; then
    rmdir "$FRAMEWORKS_DIR"
fi

if [ -f "$INFO_PLIST" ]; then
    echo "strip-sparkle: removing SU* keys from Info.plist"
    for k in SUFeedURL SUPublicEDKey SUEnableAutomaticChecks SUEnableInstallerLauncherService; do
        /usr/libexec/PlistBuddy -c "Delete :$k" "$INFO_PLIST" 2>/dev/null || true
    done
fi
