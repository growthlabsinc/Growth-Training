import Foundation
import Combine

/// Service responsible for providing journaling prompts used in LogSessionView.
final class JournalingPromptService: ObservableObject {
    // MARK: - Singleton
    static let shared = JournalingPromptService()
    private init() {
        loadDefaultPrompts()
    }

    // MARK: - Published
    @Published private(set) var latestPrompt: JournalingPrompt?

    // MARK: - Storage
    private var promptsByCategory: [PromptCategory: [JournalingPrompt]] = [:]

    // MARK: - Public API
    /// Returns a random prompt for a given category. Falls back to `.general` if none are available.
    @discardableResult
    func randomPrompt(for category: PromptCategory = .general) -> JournalingPrompt? {
        let pool = promptsByCategory[category] ?? promptsByCategory[.general] ?? []
        guard !pool.isEmpty else { return nil }
        let prompt = pool.randomElement()!
        latestPrompt = prompt
        return prompt
    }

    /// Adds a custom prompt to the in-memory pool (could be used for personalization in future).
    func addCustomPrompt(_ prompt: JournalingPrompt) {
        promptsByCategory[prompt.category, default: []].append(prompt)
    }

    // MARK: - Seed Data
    private func loadDefaultPrompts() {
        let defaults: [JournalingPrompt] = [
            // General
            JournalingPrompt(text: "What was the most rewarding part of today's session?", category: .general),
            JournalingPrompt(text: "What would you like to remember about this practice?", category: .general),
            JournalingPrompt(text: "How might you apply what you practiced today in other areas of your life?", category: .general),
            // Reflection
            JournalingPrompt(text: "What did you notice about your thoughts or emotions during this session?", category: .reflection),
            JournalingPrompt(text: "How did this session compare to your previous ones?", category: .reflection),
            JournalingPrompt(text: "What insights or realizations did you have during this practice?", category: .reflection),
            // Progress
            JournalingPrompt(text: "What improvements have you noticed since you started this practice?", category: .progress),
            JournalingPrompt(text: "Which part of your practice feels easier now than before?", category: .progress),
            JournalingPrompt(text: "How has your understanding of this method deepened over time?", category: .progress),
            // Goals
            JournalingPrompt(text: "What would you like to focus on in your next session?", category: .goals),
            JournalingPrompt(text: "What small goal could you set for tomorrow's practice?", category: .goals),
            JournalingPrompt(text: "How does today's session bring you closer to your overall goals?", category: .goals),
            // Challenges
            JournalingPrompt(text: "What was challenging about today's session, and how did you work through it?", category: .challenges),
            JournalingPrompt(text: "What might help you overcome any obstacles you encountered today?", category: .challenges),
            JournalingPrompt(text: "If you faced resistance during this session, what helped you continue?", category: .challenges),
            // Wellness
            JournalingPrompt(text: "How are you feeling physically and emotionally today?", category: .wellness),
            JournalingPrompt(text: "What wellness activity brought you the most peace today?", category: .wellness),
            JournalingPrompt(text: "How did this wellness practice contribute to your overall well-being?", category: .wellness),
            JournalingPrompt(text: "What aspects of self-care feel most important to you right now?", category: .wellness),
            JournalingPrompt(text: "How does taking time for wellness activities affect your mood?", category: .wellness),
            // Recovery
            JournalingPrompt(text: "How does your body feel after taking this rest day?", category: .recovery),
            JournalingPrompt(text: "What did you learn about yourself during this recovery time?", category: .recovery),
            JournalingPrompt(text: "How might you incorporate more mindful rest into your routine?", category: .recovery),
            JournalingPrompt(text: "What are you most grateful for in your recovery journey today?", category: .recovery),
            JournalingPrompt(text: "How does rest contribute to your overall progress and goals?", category: .recovery),
            JournalingPrompt(text: "What recovery activities felt most restorative to you?", category: .recovery)
        ]

        for prompt in defaults {
            promptsByCategory[prompt.category, default: []].append(prompt)
        }
    }
} 