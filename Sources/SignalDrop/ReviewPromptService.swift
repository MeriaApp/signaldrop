import Foundation
import StoreKit

/// Requests an App Store rating at the single highest-satisfaction moment in
/// SignalDrop's lifecycle: right after the app has caught a *real* WiFi drop
/// and shown the user the recovery (with downtime). That's the instant the
/// product has just proven its entire value proposition — the moment a happy
/// user is most likely to leave a 5-star review.
///
/// Apple already throttles the system prompt (max 3 displays per user per 365
/// days) and renders it ONLY in Mac App Store builds — outside the store, and
/// once the cap is hit, `requestReview()` silently no-ops. This service layers
/// product-side discipline on top so we never ask too early, twice on the same
/// version, or more than once per long cool-down window. We never ask on a
/// button tap and never incentivize a rating (App Store Review Guideline 1.1.4
/// / 5.6.1).
///
/// All time/version/storage dependencies are injected so the gating logic is
/// deterministically unit-testable (see `-reviewSelfTest`).
final class ReviewPromptService {

    private let defaults: UserDefaults
    private let now: () -> Date
    private let appVersion: () -> String?
    private let requestReviewImpl: () -> Void

    private enum Key {
        static let firstLaunch = "review.firstLaunchDate"
        static let dropsCaught = "review.realDropsCaught"
        static let lastPromptDate = "review.lastPromptDate"
        static let lastPromptVersion = "review.lastPromptVersion"
    }

    /// Only ask an engaged returning user who has already watched SignalDrop
    /// earn its keep more than once.
    private let minDropsBeforeAsking = 3
    private let minTimeSinceFirstLaunch: TimeInterval = 2 * 24 * 60 * 60     // 2 days
    private let minTimeBetweenPrompts: TimeInterval = 120 * 24 * 60 * 60     // 120 days

    init(
        defaults: UserDefaults = .standard,
        now: @escaping () -> Date = { Date() },
        appVersion: @escaping () -> String? = {
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        },
        requestReviewImpl: @escaping () -> Void = {
            // macOS uses the parameterless API (the scene-based variant is
            // iOS/SwiftUI-only). The system decides whether to actually render.
            SKStoreReviewController.requestReview()
        }
    ) {
        self.defaults = defaults
        self.now = now
        self.appVersion = appVersion
        self.requestReviewImpl = requestReviewImpl

        if defaults.object(forKey: Key.firstLaunch) == nil {
            defaults.set(now(), forKey: Key.firstLaunch)
        }
    }

    /// Call when SignalDrop has caught a real (non-phantom) drop and shown the
    /// user the recovery. Increments the value counter and — if the user is an
    /// engaged returning user who hasn't been asked recently — requests a review.
    func recordCaughtDropAndMaybeAsk() {
        let drops = defaults.integer(forKey: Key.dropsCaught) + 1
        defaults.set(drops, forKey: Key.dropsCaught)

        guard isEligible(dropsCaught: drops) else { return }

        defaults.set(now(), forKey: Key.lastPromptDate)
        defaults.set(appVersion(), forKey: Key.lastPromptVersion)
        requestReviewImpl()
        #if DEBUG
        print("signaldrop: requested App Store review (system may suppress in non-MAS builds)")
        #endif
    }

    /// Pure, side-effect-free eligibility decision — the unit of behavior the
    /// self-test exercises.
    func isEligible(dropsCaught: Int) -> Bool {
        guard dropsCaught >= minDropsBeforeAsking else { return false }

        if let first = defaults.object(forKey: Key.firstLaunch) as? Date,
           now().timeIntervalSince(first) < minTimeSinceFirstLaunch {
            return false
        }
        if let lastVersion = defaults.string(forKey: Key.lastPromptVersion),
           lastVersion == appVersion() {
            return false   // already asked on this version
        }
        if let last = defaults.object(forKey: Key.lastPromptDate) as? Date,
           now().timeIntervalSince(last) < minTimeBetweenPrompts {
            return false   // still inside the cool-down window
        }
        return true
    }
}
