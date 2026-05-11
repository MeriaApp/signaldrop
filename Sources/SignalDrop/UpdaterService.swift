#if !APPSTORE
import Foundation
import Sparkle

/// Wraps Sparkle's standard updater controller. Used only in Direct
/// Distribution builds — Mac App Store builds compile this file out
/// (Apple's App Store handles its own update mechanism, and sandboxed
/// App Store apps can't self-modify).
///
/// SUFeedURL and SUPublicEDKey are configured in Info.plist via
/// project.yml. The private signing key lives in the developer's
/// Keychain — Scripts/release-direct.sh shells out to `sign_update`
/// when publishing a new appcast entry.
final class UpdaterService: NSObject {
    private let controller: SPUStandardUpdaterController

    override init() {
        // startingUpdater: true → Sparkle kicks off its automatic-check
        // schedule immediately (every 24 h by default, configurable in
        // Info.plist via SUScheduledCheckInterval).
        self.controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        super.init()
    }

    /// User-initiated "Check for Updates..." menu action. Sparkle shows
    /// its own UI (no available updates, update found with release
    /// notes, etc.) — we just trigger it.
    @objc func checkForUpdates(_ sender: Any?) {
        controller.checkForUpdates(sender)
    }
}
#endif
