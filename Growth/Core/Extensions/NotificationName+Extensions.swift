import Foundation

extension Notification.Name {
    // MARK: - Authentication
    static let authStateChanged = Notification.Name("authStateChanged")
    
    // MARK: - Progress Updates
    static let methodProgressionCompleted = Notification.Name("methodProgressionCompleted")
    static let routineProgressReset = Notification.Name("routineProgressReset")
    static let methodCompleted = Notification.Name("methodCompleted")
    static let sessionLogged = Notification.Name("sessionLogged")
    static let sessionDismissedWithoutLogging = Notification.Name("sessionDismissedWithoutLogging")
    
    // MARK: - App Tour
    static let triggerAppTour = Notification.Name("triggerAppTour")
    
    // MARK: - Timer Live Activity
    static let timerPauseRequested = Notification.Name("timerPauseRequested")
    static let timerResumeRequested = Notification.Name("timerResumeRequested")
    static let timerStopRequested = Notification.Name("timerStopRequested")
    
    // MARK: - Timer User Info Keys
    struct TimerUserInfoKey {
        static let timerType = "timerType"
    }
    
    // MARK: - Timer Types
    enum TimerType: String {
        case main = "main"
        case quick = "quick"
    }
}

// Note: Navigation-related notifications are defined in SmartNavigationService.swift:
// - switchToPracticeTab
// - switchToHomeTab  
// - switchToProgressTab
// - switchToRoutinesTab
// - navigateToRoutineDetail

// Note: routineProgressUpdated is defined in LogSessionViewModel.swift