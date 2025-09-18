import Foundation

public enum RoutineDifficulty: String, CaseIterable, Codable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
}

public enum RoutineSchedulingType: String, CaseIterable, Codable {
    case sequential = "sequential" // Day 1, Day 2, Day 3, etc.
    case weekday = "weekday" // Monday, Wednesday, Friday, etc.
    
    var displayName: String {
        switch self {
        case .sequential:
            return "Sequential Days"
        case .weekday:
            return "Weekday-Based"
        }
    }
    
    var description: String {
        switch self {
        case .sequential:
            return "Progress through Day 1, Day 2, Day 3, etc."
        case .weekday:
            return "Schedule specific methods on specific weekdays"
        }
    }
    
    var detailedDescription: String {
        switch self {
        case .sequential:
            return "Perfect for challenges and progressive programs. Each day builds on the previous one."
        case .weekday:
            return "Ideal for weekly patterns like 'Workout Monday, Meditation Wednesday, Rest Sunday'."
        }
    }
    
    var exampleText: String {
        switch self {
        case .sequential:
            return "Example: 21-day meditation challenge"
        case .weekday:
            return "Example: Weekly fitness routine"
        }
    }
    
    var recommendedFor: String {
        switch self {
        case .sequential:
            return "Best for routines longer than 2 weeks"
        case .weekday:
            return "Best for ongoing weekly patterns"
        }
    }
}

public struct Routine: Identifiable, Codable {
    public var id: String
    public var name: String
    public var description: String
    public var difficulty: RoutineDifficulty // Updated to use enum
    public var difficultyLevel: String { // Computed property for backward compatibility
        difficulty.rawValue.capitalized
    }
    public var duration: Int // Number of days
    public var focusAreas: [String] // Categories/tags
    public var stages: [Int] // Method stages included
    public var createdDate: Date
    public var lastUpdated: Date
    public var schedule: [DaySchedule]
    public var isCustom: Bool?
    public var createdBy: String? // User ID who created it
    public var shareWithCommunity: Bool?
    public var schedulingType: RoutineSchedulingType? // nil for legacy routines defaults to sequential
    
    // Community metadata
    public var creatorUsername: String?
    public var creatorDisplayName: String?
    public var sharedDate: Date?
    public var downloadCount: Int = 0
    public var reportCount: Int = 0
    public var moderationStatus: String = "pending" // pending, approved, flagged, removed
    public var rating: Double?
    public var ratingCount: Int = 0
    public var tags: [String] = []
    public var version: Int = 1
    
    // Legacy properties for compatibility
    public var createdAt: Date { createdDate }
    public var updatedAt: Date { lastUpdated }
    public var startDate: Date? // When the user started this routine
    
    // Custom decoder to handle missing fields
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decode(String.self, forKey: .description)
        
        // Handle difficulty with backward compatibility
        if let difficultyEnum = try? container.decode(RoutineDifficulty.self, forKey: .difficulty) {
            self.difficulty = difficultyEnum
        } else if let difficultyString = try? container.decode(String.self, forKey: .difficultyLevel) {
            self.difficulty = RoutineDifficulty(rawValue: difficultyString.lowercased()) ?? .beginner
        } else {
            self.difficulty = .beginner
        }
        
        // Duration can be provided or calculated from schedule
        if let duration = try? container.decode(Int.self, forKey: .duration) {
            self.duration = duration
        } else {
            // Will be calculated after decoding schedule
            self.duration = 0
        }
        self.focusAreas = try container.decodeIfPresent([String].self, forKey: .focusAreas) ?? []
        self.stages = try container.decodeIfPresent([Int].self, forKey: .stages) ?? []
        
        // Handle date fields with backward compatibility
        if let createdDate = try? container.decode(Date.self, forKey: .createdDate) {
            self.createdDate = createdDate
        } else if let createdAt = try? container.decode(Date.self, forKey: .createdAt) {
            self.createdDate = createdAt
        } else {
            self.createdDate = Date()
        }
        
        if let lastUpdated = try? container.decode(Date.self, forKey: .lastUpdated) {
            self.lastUpdated = lastUpdated
        } else if let updatedAt = try? container.decode(Date.self, forKey: .updatedAt) {
            self.lastUpdated = updatedAt
        } else {
            self.lastUpdated = self.createdDate
        }
        
        self.schedule = try container.decode([DaySchedule].self, forKey: .schedule)
        
        // If duration was 0, calculate it from schedule
        if self.duration == 0 {
            self.duration = self.schedule.count
        }
        
        // Optional fields
        self.isCustom = try container.decodeIfPresent(Bool.self, forKey: .isCustom)
        self.createdBy = try container.decodeIfPresent(String.self, forKey: .createdBy)
        self.shareWithCommunity = try container.decodeIfPresent(Bool.self, forKey: .shareWithCommunity)
        self.startDate = try container.decodeIfPresent(Date.self, forKey: .startDate)
        self.schedulingType = try container.decodeIfPresent(RoutineSchedulingType.self, forKey: .schedulingType)
        
        // Community metadata with defaults
        self.creatorUsername = try container.decodeIfPresent(String.self, forKey: .creatorUsername)
        self.creatorDisplayName = try container.decodeIfPresent(String.self, forKey: .creatorDisplayName)
        self.sharedDate = try container.decodeIfPresent(Date.self, forKey: .sharedDate)
        self.downloadCount = try container.decodeIfPresent(Int.self, forKey: .downloadCount) ?? 0
        self.reportCount = try container.decodeIfPresent(Int.self, forKey: .reportCount) ?? 0
        self.moderationStatus = try container.decodeIfPresent(String.self, forKey: .moderationStatus) ?? "pending"
        self.rating = try container.decodeIfPresent(Double.self, forKey: .rating)
        self.ratingCount = try container.decodeIfPresent(Int.self, forKey: .ratingCount) ?? 0
        self.tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        self.version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
    }
    
    // Custom encoder
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(difficulty, forKey: .difficulty)
        try container.encode(duration, forKey: .duration)
        try container.encode(focusAreas, forKey: .focusAreas)
        try container.encode(stages, forKey: .stages)
        try container.encode(createdDate, forKey: .createdDate)
        try container.encode(lastUpdated, forKey: .lastUpdated)
        try container.encode(schedule, forKey: .schedule)
        try container.encodeIfPresent(isCustom, forKey: .isCustom)
        try container.encodeIfPresent(createdBy, forKey: .createdBy)
        try container.encodeIfPresent(shareWithCommunity, forKey: .shareWithCommunity)
        try container.encodeIfPresent(startDate, forKey: .startDate)
        try container.encodeIfPresent(creatorUsername, forKey: .creatorUsername)
        try container.encodeIfPresent(creatorDisplayName, forKey: .creatorDisplayName)
        try container.encodeIfPresent(sharedDate, forKey: .sharedDate)
        try container.encode(downloadCount, forKey: .downloadCount)
        try container.encode(reportCount, forKey: .reportCount)
        try container.encode(moderationStatus, forKey: .moderationStatus)
        try container.encodeIfPresent(rating, forKey: .rating)
        try container.encode(ratingCount, forKey: .ratingCount)
        try container.encode(tags, forKey: .tags)
        try container.encode(version, forKey: .version)
        try container.encodeIfPresent(schedulingType, forKey: .schedulingType)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case difficulty
        case difficultyLevel // For backward compatibility
        case duration
        case focusAreas
        case stages
        case createdDate
        case createdAt // For backward compatibility
        case lastUpdated
        case updatedAt // For backward compatibility
        case schedule
        case isCustom
        case createdBy
        case shareWithCommunity
        case startDate
        case creatorUsername
        case creatorDisplayName
        case sharedDate
        case downloadCount
        case reportCount
        case moderationStatus
        case rating
        case ratingCount
        case tags
        case version
        case schedulingType
    }
    
    // Backward compatible initializer
    public init(id: String, name: String, description: String, difficultyLevel: String, schedule: [DaySchedule], createdAt: Date, updatedAt: Date, startDate: Date? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.difficulty = RoutineDifficulty(rawValue: difficultyLevel.lowercased()) ?? .beginner
        self.duration = schedule.count
        self.focusAreas = []
        self.stages = []
        self.createdDate = createdAt
        self.lastUpdated = updatedAt
        self.schedule = schedule
        self.isCustom = false
        self.createdBy = nil
        self.shareWithCommunity = false
        self.startDate = startDate
        // Initialize community metadata with defaults
        self.creatorUsername = nil
        self.creatorDisplayName = nil
        self.sharedDate = nil
        self.downloadCount = 0
        self.reportCount = 0
        self.moderationStatus = "pending"
        self.rating = nil
        self.ratingCount = 0
        self.tags = []
        self.version = 1
    }
    
    // New initializer for premium creation
    public init(id: String, name: String, description: String, difficulty: RoutineDifficulty, duration: Int, focusAreas: [String], stages: [Int], createdDate: Date, lastUpdated: Date, schedule: [DaySchedule], isCustom: Bool? = nil, createdBy: String? = nil, shareWithCommunity: Bool? = nil, creatorUsername: String? = nil, creatorDisplayName: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.difficulty = difficulty
        self.duration = duration
        self.focusAreas = focusAreas
        self.stages = stages
        self.createdDate = createdDate
        self.lastUpdated = lastUpdated
        self.schedule = schedule
        self.isCustom = isCustom
        self.createdBy = createdBy
        self.shareWithCommunity = shareWithCommunity
        self.startDate = nil
        // Initialize community metadata
        self.creatorUsername = creatorUsername
        self.creatorDisplayName = creatorDisplayName
        self.sharedDate = shareWithCommunity == true ? Date() : nil
        self.downloadCount = 0
        self.reportCount = 0
        self.moderationStatus = "pending"
        self.rating = nil
        self.ratingCount = 0
        self.tags = []
        self.version = 1
    }
}

public struct DaySchedule: Identifiable, Codable, Hashable {
    public var id: String
    public var day: Int // Day number in the routine
    public var dayNumber: Int { day } // Alias for compatibility
    public var dayName: String { "Day \(day)" } // Computed property
    public var description: String
    public var isRestDay: Bool
    public var methods: [MethodSchedule]
    public var methodIds: [String]? { // For backward compatibility
        methods.map { $0.methodId }
    }
    public var notes: String
    public var additionalNotes: String? { notes.isEmpty ? nil : notes }
    
    // Legacy initializer for backward compatibility
    public init(id: String, dayNumber: Int, dayName: String, description: String, methodIds: [String]?, isRestDay: Bool, additionalNotes: String?) {
        self.id = id
        self.day = dayNumber
        self.description = description
        self.isRestDay = isRestDay
        self.methods = methodIds?.enumerated().map { index, methodId in
            MethodSchedule(methodId: methodId, duration: 20, order: index)
        } ?? []
        self.notes = additionalNotes ?? ""
    }
    
    // New initializer for premium creation
    public init(day: Int, isRestDay: Bool, methods: [MethodSchedule], notes: String = "") {
        self.id = UUID().uuidString
        self.day = day
        self.description = ""
        self.isRestDay = isRestDay
        self.methods = methods
        self.notes = notes
    }
    
    // Custom decoder to handle missing fields and backward compatibility
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        
        // Handle both 'day' and 'dayNumber' for backward compatibility
        if let day = try? container.decode(Int.self, forKey: .day) {
            self.day = day
        } else if let dayNumber = try? container.decode(Int.self, forKey: .dayNumber) {
            self.day = dayNumber
        } else {
            throw DecodingError.keyNotFound(CodingKeys.day, DecodingError.Context(codingPath: container.codingPath, debugDescription: "Neither 'day' nor 'dayNumber' found"))
        }
        
        self.description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        self.isRestDay = try container.decodeIfPresent(Bool.self, forKey: .isRestDay) ?? false
        
        // Handle both 'methods' array and legacy 'methodIds' array
        if let methods = try? container.decode([MethodSchedule].self, forKey: .methods) {
            self.methods = methods
        } else if let methodIds = try? container.decode([String].self, forKey: .methodIds) {
            // Convert legacy methodIds to MethodSchedule objects
            self.methods = methodIds.enumerated().map { index, methodId in
                MethodSchedule(methodId: methodId, duration: 20, order: index)
            }
        } else {
            self.methods = []
        }
        
        // Handle both 'notes' and 'additionalNotes' for backward compatibility
        if let notes = try? container.decode(String.self, forKey: .notes) {
            self.notes = notes
        } else if let additionalNotes = try? container.decode(String.self, forKey: .additionalNotes) {
            self.notes = additionalNotes
        } else {
            self.notes = ""
        }
    }
    
    // Custom encoder to handle backward compatibility
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(day, forKey: .day)
        try container.encode(description, forKey: .description)
        try container.encode(isRestDay, forKey: .isRestDay)
        try container.encode(methods, forKey: .methods)
        try container.encode(notes, forKey: .notes)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case day
        case dayNumber // For backward compatibility
        case description
        case isRestDay
        case methods
        case methodIds // For backward compatibility
        case notes
        case additionalNotes // For backward compatibility
    }
}

public struct MethodSchedule: Codable, Hashable, Identifiable {
    public var id: String
    public var methodId: String
    public var duration: Int // Minutes
    public var order: Int // Order in the day
    
    public init(methodId: String, duration: Int, order: Int) {
        self.id = UUID().uuidString
        self.methodId = methodId
        self.duration = duration
        self.order = order
    }
    
    // Custom decoder to handle missing fields
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.methodId = try container.decode(String.self, forKey: .methodId)
        self.duration = try container.decodeIfPresent(Int.self, forKey: .duration) ?? 20
        self.order = try container.decodeIfPresent(Int.self, forKey: .order) ?? 0
    }
    
    // Custom encoder
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(methodId, forKey: .methodId)
        try container.encode(duration, forKey: .duration)
        try container.encode(order, forKey: .order)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case methodId
        case duration
        case order
    }
} 