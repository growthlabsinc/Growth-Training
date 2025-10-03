import Foundation

/// Model representing a suggested next session for the user.
/// This is not persisted locally; it's created by `NextSessionViewModel` after
/// evaluating the user's focus, readiness, and session history.
struct NextSessionSuggestion: Identifiable, Hashable {
    /// Unique identifier – we use the method ID so it's unique within the user context.
    let id: String

    /// Name / title of the growth method.
    let methodTitle: String

    /// Stage number for the method (e.g. 1 = beginner, 2 = intermediate).
    let stage: Int

    /// Recommended duration in minutes, if available.
    let durationMinutes: Int?
} 