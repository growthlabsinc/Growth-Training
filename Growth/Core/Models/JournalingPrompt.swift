import Foundation

/// Category of journaling prompt to provide contextually relevant questions.
public enum PromptCategory: String, Codable, CaseIterable {
    /// Generic reflection prompt that can apply to any session.
    case general
    /// Prompts focused on self-reflection and feelings.
    case reflection
    /// Prompts about measuring or noticing progress.
    case progress
    /// Prompts that encourage goal setting.
    case goals
    /// Prompts that address obstacles or challenges.
    case challenges
    /// Prompts focused on wellness activities and recovery.
    case wellness
    /// Prompts for rest day activities and mindfulness.
    case recovery
}

/// Represents a short journaling prompt presented to the user while writing session notes.
public struct JournalingPrompt: Identifiable, Codable, Equatable, Hashable {
    public let id: String
    public let text: String
    public let category: PromptCategory

    public init(id: String = UUID().uuidString,
                text: String,
                category: PromptCategory = .general) {
        self.id = id
        self.text = text
        self.category = category
    }
} 