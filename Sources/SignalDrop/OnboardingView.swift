import SwiftUI

struct OnboardingView: View {
    enum Step: Hashable {
        case welcome
        case location
        case notifications
        case done
    }

    @State private var step: Step = .welcome
    @State private var locationResult: PermissionResult?
    @State private var notificationsResult: PermissionResult?
    @State private var isAwaitingPermission = false

    let requestLocation: (@escaping (PermissionResult) -> Void) -> Void
    let requestNotifications: (@escaping (PermissionResult) -> Void) -> Void
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            content
                .padding(.horizontal, 40)
                .padding(.top, 36)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            footer
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
        }
        .frame(width: 520, height: 420)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Step content

    @ViewBuilder
    private var content: some View {
        switch step {
        case .welcome:   welcomeStep
        case .location:  locationStep
        case .notifications: notificationsStep
        case .done:      doneStep
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: 18) {
            appIcon
            VStack(spacing: 8) {
                Text("Welcome to SignalDrop")
                    .font(.system(size: 22, weight: .semibold))
                Text("macOS silently drops your WiFi and hopes you notice.\nSignalDrop tells you the moment it happens.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            VStack(alignment: .leading, spacing: 10) {
                bullet("Instant disconnect notifications with downtime duration")
                bullet("Signal-weakness warnings before drops happen")
                bullet("Daily reliability stats and CSV export for ISP support")
            }
            .padding(.top, 4)
        }
    }

    private var locationStep: some View {
        permissionStep(
            symbol: "location.circle.fill",
            tint: .blue,
            title: "Location access",
            body: "Apple requires location permission for any app that reads WiFi network names — even though SignalDrop never uses your location for anything else.\n\nYour location is never stored, sent anywhere, or shared."
        )
    }

    private var notificationsStep: some View {
        permissionStep(
            symbol: "bell.badge.circle.fill",
            tint: .orange,
            title: "Notifications",
            body: "SignalDrop alerts you the moment your connection changes — disconnects, weak signal, internet outages. Without this, the app still works but can only show events in the menu."
        )
    }

    private var doneStep: some View {
        // Detect a "crippled" state: user reached Done without granting
        // anything. Surface that honestly instead of a green checkmark
        // that contradicts reality.
        let locationOK = locationResult == .granted
        let notificationsOK = notificationsResult == .granted
        let bothMissing = !locationOK && !notificationsOK
        let someMissing = !locationOK || !notificationsOK
        let tint: Color = bothMissing ? .orange : (someMissing ? .yellow : .green)
        let symbol = bothMissing ? "exclamationmark.triangle.fill"
            : (someMissing ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
        let title = bothMissing ? "Permissions skipped"
            : (someMissing ? "Almost there" : "You\u{2019}re set")
        let subtitle: String = {
            if bothMissing {
                return "SignalDrop will still launch, but without Location it can\u{2019}t read network names, and without Notifications you won\u{2019}t see alerts. Grant either later from System Settings."
            } else if !locationOK {
                return "Notifications are on, but without Location, SignalDrop can\u{2019}t read network names. Grant Location later from System Settings."
            } else if !notificationsOK {
                return "Network names will show, but you won\u{2019}t get alerts. Grant Notifications later from System Settings."
            } else {
                return "SignalDrop is now monitoring your WiFi from the menu bar."
            }
        }()

        return VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.15))
                    .frame(width: 72, height: 72)
                Image(systemName: symbol)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                    .foregroundColor(tint)
            }
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 22, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 440)
            }
            if !someMissing {
                VStack(alignment: .leading, spacing: 8) {
                    tip("Look for the Wi-Fi glyph in your menu bar — its shape changes with signal, internet status, and Wi-Fi power.")
                    tip("Open Network Insights (⌘N) for the live scanner, signal graph, and connection history.")
                    tip("Toggle Launch at Login from the menu so SignalDrop starts on boot.")
                    tip("From the Connection History tab, export a PDF receipt to send to your ISP.")
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Reusable bits

    private func permissionStep(
        symbol: String,
        tint: Color,
        title: String,
        body: String
    ) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().fill(tint.opacity(0.12)).frame(width: 72, height: 72)
                Image(systemName: symbol)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .foregroundColor(tint)
            }
            Text(title)
                .font(.system(size: 20, weight: .semibold))
            Text(body)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 420)
        }
    }

    private var appIcon: some View {
        Group {
            if let img = NSImage(named: "AppIcon") {
                Image(nsImage: img).resizable().scaledToFit()
            } else {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .resizable().scaledToFit()
                    .foregroundColor(.accentColor)
            }
        }
        .frame(width: 84, height: 84)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func tip(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "circle.fill")
                .resizable()
                .frame(width: 4, height: 4)
                .padding(.top, 6)
                .foregroundColor(.secondary)
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Footer / nav

    private var footer: some View {
        HStack {
            stepIndicator
            Spacer()
            primaryButton
        }
    }

    private var stepIndicator: some View {
        HStack(spacing: 6) {
            ForEach([Step.welcome, .location, .notifications, .done], id: \.self) { s in
                Circle()
                    .fill(s == step ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
    }

    private var primaryButton: some View {
        Button(action: advance) {
            Text(primaryLabel).frame(minWidth: 90)
        }
        .controlSize(.large)
        .keyboardShortcut(.return)
        .disabled(isPrimaryDisabled)
    }

    private var primaryLabel: String {
        switch step {
        case .welcome:        return "Continue"
        case .location:       return "Continue"
        case .notifications:  return "Continue"
        case .done:           return "Get Started"
        }
    }

    private var isPrimaryDisabled: Bool {
        isAwaitingPermission
    }

    private func advance() {
        switch step {
        case .welcome:
            step = .location
        case .location:
            if locationResult != nil {
                step = .notifications
            } else {
                isAwaitingPermission = true
                requestLocation { result in
                    locationResult = result
                    isAwaitingPermission = false
                    step = .notifications
                }
            }
        case .notifications:
            if notificationsResult != nil {
                step = .done
            } else {
                isAwaitingPermission = true
                requestNotifications { result in
                    notificationsResult = result
                    isAwaitingPermission = false
                    step = .done
                }
            }
        case .done:
            onFinish()
        }
    }
}
