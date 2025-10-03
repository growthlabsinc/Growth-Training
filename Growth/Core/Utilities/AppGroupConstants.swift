import Foundation

/// Constants for App Group functionality
struct AppGroupConstants {
    /// The app group identifier used for data sharing between app and widgets
    static let identifier = "group.com.growthlabs.growthmethod"
    
    /// UserDefaults instance for the app group
    static var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: identifier)
    }
    
    /// Keys for storing data in shared UserDefaults
    struct Keys {
        static let timerState = "com.growthlabs.growthmethod.timerState"
        static let timerStartTime = "com.growthlabs.growthmethod.timerStartTime"
        static let timerEndTime = "com.growthlabs.growthmethod.timerEndTime"
        static let timerElapsedTime = "com.growthlabs.growthmethod.timerElapsedTime"
        static let timerIsPaused = "com.growthlabs.growthmethod.timerIsPaused"
        static let timerMethodName = "com.growthlabs.growthmethod.timerMethodName"
        static let timerSessionType = "com.growthlabs.growthmethod.timerSessionType"
        static let liveActivityId = "com.growthlabs.growthmethod.liveActivityId"
        static let timerIsCompleted = "com.growthlabs.growthmethod.timerIsCompleted"
        static let timerCompletionMessage = "com.growthlabs.growthmethod.timerCompletionMessage"
        
        // Additional keys for Live Activity integration
        static let currentTimerActivityId = "currentTimerActivityId"
        static let timerActivityStatePrefix = "timerActivityState_"
        static let timerPausedViaLiveActivity = "timerPausedViaLiveActivity"
        static let timerPauseTime = "timerPauseTime"
        static let lastTimerAction = "lastTimerAction"
        static let lastTimerType = "lastTimerType"
        static let lastTimerActionTime = "lastTimerActionTime"
    }
    
    /// Store timer state in app group
    static func storeTimerState(
        startTime: Date,
        endTime: Date,
        elapsedTime: TimeInterval,
        isPaused: Bool,
        methodName: String,
        sessionType: String,
        activityId: String?,
        isCompleted: Bool = false,
        completionMessage: String? = nil
    ) {
        guard let defaults = sharedDefaults else { return }
        
        defaults.set(startTime, forKey: Keys.timerStartTime)
        defaults.set(endTime, forKey: Keys.timerEndTime)
        defaults.set(elapsedTime, forKey: Keys.timerElapsedTime)
        defaults.set(isPaused, forKey: Keys.timerIsPaused)
        defaults.set(methodName, forKey: Keys.timerMethodName)
        defaults.set(sessionType, forKey: Keys.timerSessionType)
        defaults.set(isCompleted, forKey: Keys.timerIsCompleted)
        
        if let activityId = activityId {
            defaults.set(activityId, forKey: Keys.liveActivityId)
        }
        
        if let completionMessage = completionMessage {
            defaults.set(completionMessage, forKey: Keys.timerCompletionMessage)
        }
        
        defaults.synchronize()
    }
    
    /// Clear timer state from app group
    static func clearTimerState() {
        guard let defaults = sharedDefaults else { return }
        
        defaults.removeObject(forKey: Keys.timerStartTime)
        defaults.removeObject(forKey: Keys.timerEndTime)
        defaults.removeObject(forKey: Keys.timerElapsedTime)
        defaults.removeObject(forKey: Keys.timerIsPaused)
        defaults.removeObject(forKey: Keys.timerMethodName)
        defaults.removeObject(forKey: Keys.timerSessionType)
        defaults.removeObject(forKey: Keys.liveActivityId)
        defaults.removeObject(forKey: Keys.timerIsCompleted)
        defaults.removeObject(forKey: Keys.timerCompletionMessage)
        
        defaults.synchronize()
    }
    
    /// Get current timer state from app group
    static func getTimerState() -> (
        startTime: Date?,
        endTime: Date?,
        elapsedTime: TimeInterval,
        isPaused: Bool,
        methodName: String?,
        sessionType: String?,
        activityId: String?,
        isCompleted: Bool,
        completionMessage: String?
    ) {
        guard let defaults = sharedDefaults else {
            return (nil, nil, 0, false, nil, nil, nil, false, nil)
        }
        
        return (
            defaults.object(forKey: Keys.timerStartTime) as? Date,
            defaults.object(forKey: Keys.timerEndTime) as? Date,
            defaults.double(forKey: Keys.timerElapsedTime),
            defaults.bool(forKey: Keys.timerIsPaused),
            defaults.string(forKey: Keys.timerMethodName),
            defaults.string(forKey: Keys.timerSessionType),
            defaults.string(forKey: Keys.liveActivityId),
            defaults.bool(forKey: Keys.timerIsCompleted),
            defaults.string(forKey: Keys.timerCompletionMessage)
        )
    }
}