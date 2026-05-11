import Foundation
import UserNotifications

final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    private var authorized = false

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        // Don't request on init — onboarding sequences this with the
        // location prompt so two system dialogs never race at first launch.
        // For returning users we just read whatever was already granted.
        refreshAuthorizationStatus()
    }

    /// Read the current notification authorization without prompting.
    /// Use at app start for returning users so we know whether to skip
    /// notification sends when permission was previously denied.
    func refreshAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            let granted = settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional
            self?.authorized = granted
        }
    }

    func send(title: String, body: String, sound: Bool = true, critical: Bool = false) {
        guard authorized else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        if sound {
            content.sound = critical ? .defaultCritical : .default
        }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    // Show notifications even when app is frontmost
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
