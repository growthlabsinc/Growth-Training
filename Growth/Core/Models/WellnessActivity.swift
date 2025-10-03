import Foundation

/// Represents different types of wellness activities that can be logged on rest days
enum WellnessActivityType: String, Codable, CaseIterable {
    case stretching = "stretching"
    case meditation = "meditation"
    case reading = "reading"
    case breathing = "breathing"
    case hydration = "hydration"
    case sleep = "sleep"
    case nutrition = "nutrition"
    case journaling = "journaling"
    case walking = "walking"
    case recovery = "recovery"
    
    var title: String {
        switch self {
        case .stretching: return "Stretching"
        case .meditation: return "Meditation"
        case .reading: return "Reading"
        case .breathing: return "Breathing Exercises"
        case .hydration: return "Hydration"
        case .sleep: return "Quality Sleep"
        case .nutrition: return "Mindful Nutrition"
        case .journaling: return "Journaling"
        case .walking: return "Light Walking"
        case .recovery: return "Recovery Activities"
        }
    }
    
    var emoji: String {
        switch self {
        case .stretching: return "🧘‍♂️"
        case .meditation: return "🧘"
        case .reading: return "📚"
        case .breathing: return "💨"
        case .hydration: return "💧"
        case .sleep: return "😴"
        case .nutrition: return "🥗"
        case .journaling: return "📝"
        case .walking: return "🚶‍♂️"
        case .recovery: return "🌿"
        }
    }
    
    var description: String {
        switch self {
        case .stretching: return "Light stretching or mobility work"
        case .meditation: return "Mindfulness or meditation practice"
        case .reading: return "Reading recovery or wellness articles"
        case .breathing: return "Deep breathing or relaxation exercises"
        case .hydration: return "Tracking water intake and hydration"
        case .sleep: return "Quality rest and sleep tracking"
        case .nutrition: return "Mindful eating and nutrition focus"
        case .journaling: return "Reflection and written meditation"
        case .walking: return "Gentle movement and fresh air"
        case .recovery: return "General recovery and self-care activities"
        }
    }
}

/// Represents a wellness activity that can be logged on rest days
struct WellnessActivity: Identifiable, Codable, Equatable {
    let id: String
    let type: WellnessActivityType
    let duration: Int // in minutes
    let notes: String?
    let loggedAt: Date
    
    init(id: String = UUID().uuidString, 
         type: WellnessActivityType, 
         duration: Int, 
         notes: String? = nil, 
         loggedAt: Date = Date()) {
        self.id = id
        self.type = type
        self.duration = duration
        self.notes = notes
        self.loggedAt = loggedAt
    }
}

/// Suggested wellness activities for rest days
struct WellnessActivitySuggestion {
    let type: WellnessActivityType
    let title: String
    let description: String
    let estimatedDuration: Int // in minutes
    let instructions: String?
    
    static let suggestions: [WellnessActivitySuggestion] = [
        WellnessActivitySuggestion(
            type: .stretching,
            title: "Gentle Stretching",
            description: "Light mobility work to aid recovery",
            estimatedDuration: 10,
            instructions: "Focus on major muscle groups with gentle, sustained stretches. Hold each stretch for 30 seconds."
        ),
        WellnessActivitySuggestion(
            type: .meditation,
            title: "Mindfulness Meditation",
            description: "Calm the mind and reduce stress",
            estimatedDuration: 15,
            instructions: "Find a quiet space, sit comfortably, and focus on your breath. Let thoughts come and go without judgment."
        ),
        WellnessActivitySuggestion(
            type: .breathing,
            title: "Deep Breathing",
            description: "Activate the relaxation response",
            estimatedDuration: 5,
            instructions: "Try 4-7-8 breathing: Inhale for 4, hold for 7, exhale for 8. Repeat 4-6 times."
        ),
        WellnessActivitySuggestion(
            type: .hydration,
            title: "Hydration Check",
            description: "Ensure proper fluid intake",
            estimatedDuration: 2,
            instructions: "Drink a glass of water and track your daily intake. Aim for clear, pale yellow urine."
        ),
        WellnessActivitySuggestion(
            type: .journaling,
            title: "Reflection Writing",
            description: "Process thoughts and emotions",
            estimatedDuration: 10,
            instructions: "Write about your current feelings, progress, or gratitude. No editing needed - just flow."
        ),
        WellnessActivitySuggestion(
            type: .walking,
            title: "Gentle Walk",
            description: "Light movement and fresh air",
            estimatedDuration: 20,
            instructions: "Take a leisurely walk outside or indoors. Focus on your surroundings and breathing."
        )
    ]
}