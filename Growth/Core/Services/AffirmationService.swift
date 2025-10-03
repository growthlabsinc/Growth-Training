import Foundation
import Combine

/// Service responsible for loading, storing, and retrieving affirmations.
final class AffirmationService: ObservableObject {
    // MARK: - Singleton
    static let shared = AffirmationService()
    private init() {
        loadDefaultAffirmations()
    }

    // MARK: - Published
    /// Stream of the last fetched affirmation so interested views can reactively update.
    @Published private(set) var latestAffirmation: Affirmation?

    // MARK: - Storage
    private var affirmationsByCategory: [AffirmationCategory: [Affirmation]] = [:]
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Public API
    /// Returns a random affirmation for the requested category. Falls back to `general` if none are found.
    func randomAffirmation(for category: AffirmationCategory) -> Affirmation? {
        let pool = affirmationsByCategory[category] ?? affirmationsByCategory[.general] ?? []
        guard !pool.isEmpty else { return nil }
        let affirmation = pool.randomElement()!
        
        // Ensure published property is updated on main thread
        DispatchQueue.main.async { [weak self] in
            self?.latestAffirmation = affirmation
        }
        
        return affirmation
    }

    /// Adds a custom affirmation to the in-memory pool.
    func addCustomAffirmation(_ affirmation: Affirmation) {
        // While this doesn't directly update published properties,
        // it's good practice to ensure thread safety
        DispatchQueue.main.async { [weak self] in
            self?.affirmationsByCategory[affirmation.category, default: []].append(affirmation)
        }
    }

    // MARK: - Default seed
    /// Loads a static seed of affirmations into memory. For MVP these are hard-coded; in the future they could live in Firestore or remote config.
    private func loadDefaultAffirmations() {
        let defaults: [Affirmation] = [
            // General
            Affirmation(text: "Great job staying consistent!", category: .general),
            Affirmation(text: "Every session counts towards your goal.", category: .general),
            Affirmation(text: "Small steps lead to big changes.", category: .general),
            Affirmation(text: "Your dedication is paying off.", category: .general),
            Affirmation(text: "Keep up the great effort!", category: .general),
            Affirmation(text: "Your commitment to growth is inspiring.", category: .general),
            Affirmation(text: "Progress, not perfection.", category: .general),
            Affirmation(text: "Consistency is your superpower.", category: .general),
            Affirmation(text: "Believe in your journey.", category: .general),
            Affirmation(text: "Celebrate every win, no matter how small.", category: .general),
            // Session Completion
            Affirmation(text: "Great job completing your session today!", category: .sessionCompletion),
            Affirmation(text: "You showed up for yourself today – that's what counts.", category: .sessionCompletion),
            Affirmation(text: "Your effort today builds tomorrow's success.", category: .sessionCompletion),
            // Streak Maintenance
            Affirmation(text: "Another day of dedication – your streak continues!", category: .streakMaintenance),
            Affirmation(text: "Your daily practice is creating lasting change.", category: .streakMaintenance),
            Affirmation(text: "Your consistency is impressive! Keep the momentum going.", category: .streakMaintenance),
            // Badge Earned
            Affirmation(text: "Congratulations on your achievement! You earned it through consistent effort.", category: .badgeEarned),
            Affirmation(text: "This badge represents your dedication to growth.", category: .badgeEarned),
            Affirmation(text: "Your hard work has been recognized!", category: .badgeEarned)
        ]

        for affirmation in defaults {
            affirmationsByCategory[affirmation.category, default: []].append(affirmation)
        }
    }
} 