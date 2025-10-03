import Foundation

/// Category of affirmation used to contextualize when it should be shown.
public enum AffirmationCategory: String, Codable, CaseIterable {
    /// Generic message that can be shown at any time (e.g. Dashboard)
    case general
    /// Message shown right after the user logs a practice session.
    case sessionCompletion
    /// Message shown when the user maintained or extended a streak.
    case streakMaintenance
    /// Message shown when a badge/achievement is earned.
    case badgeEarned
}

/// Represents a short encouraging message shown to the user.
public struct Affirmation: Identifiable, Codable, Equatable, Hashable {
    public let id: String
    public let text: String
    public let category: AffirmationCategory

    public init(id: String = UUID().uuidString,
                text: String,
                category: AffirmationCategory = .general) {
        self.id = id
        self.text = text
        self.category = category
    }
} 