import Foundation
import ActivityKit

// Simple Live Activity Manager based on expo-live-activity-timer pattern
@available(iOS 16.2, *)
class SimpleLiveActivityManager: ObservableObject {
    static let shared = SimpleLiveActivityManager()
    
    @Published var currentActivity: Activity<TimerActivityAttributes>?
    
    private init() {}
    
    // Start a new Live Activity
    func startActivity(
        methodId: String,
        methodName: String,
        sessionType: String,
        targetDuration: TimeInterval
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities not enabled")
            return
        }
        
        let attributes = TimerActivityAttributes(
            methodId: methodId,
            timerType: "main"
        )
        
        // Convert sessionType string to enum
        let sessionTypeEnum: SessionType
        switch sessionType.lowercased() {
        case "countdown":
            sessionTypeEnum = .countdown
        case "countup":
            sessionTypeEnum = .countup
        case "interval":
            sessionTypeEnum = .interval
        case "completed":
            sessionTypeEnum = .completed
        default:
            sessionTypeEnum = .countup
        }
        
        let initialState = TimerActivityAttributes.ContentState(
            startedAt: Date(),
            pausedAt: nil,
            duration: targetDuration,
            methodName: methodName,
            sessionType: sessionTypeEnum
        )
        
        // Very long stale date (24 hours)
        let staleDate = Date().addingTimeInterval(24 * 60 * 60)
        
        do {
            let activity = try Activity<TimerActivityAttributes>.request(
                attributes: attributes,
                content: ActivityContent(state: initialState, staleDate: staleDate),
                pushType: .token
            )
            
            self.currentActivity = activity
            print("Live Activity started: \(activity.id)")
            
            // Register for push token updates
            Task {
                for await token in activity.pushTokenUpdates {
                    let tokenString = token.map { String(format: "%02x", $0) }.joined()
                    print("Push token: \(tokenString)")
                    // TODO: Send to server
                }
            }
            
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }
    
    // Update activity to paused state
    func pauseActivity() {
        guard let activity = currentActivity else { return }
        
        Task {
            let currentState = activity.content.state
            let updatedState = TimerActivityAttributes.ContentState(
                startedAt: currentState.startedAt,
                pausedAt: Date(),
                duration: currentState.duration,
                methodName: currentState.methodName,
                sessionType: currentState.sessionType
            )
            
            await activity.update(
                ActivityContent(
                    state: updatedState,
                    staleDate: Date().addingTimeInterval(24 * 60 * 60)
                )
            )
        }
    }
    
    // Update activity to resumed state
    func resumeActivity() {
        guard let activity = currentActivity else { return }
        
        Task {
            // Key insight from expo-live-activity-timer: adjust startedAt by pause duration
            let currentState = activity.content.state
            let pausedAt = currentState.pausedAt ?? Date()
            let pauseDuration = Date().timeIntervalSince(pausedAt)
            // Add pause duration to startedAt so timer continues from where it was paused
            let adjustedStartTime = currentState.startedAt.addingTimeInterval(pauseDuration)
            
            print("🟢 SimpleLiveActivityManager: RESUMING")
            print("  - Pause duration: \(pauseDuration)s")
            print("  - Adjusted startedAt: \(adjustedStartTime)")
            
            let updatedState = TimerActivityAttributes.ContentState(
                startedAt: adjustedStartTime,
                pausedAt: nil,
                duration: currentState.duration,
                methodName: currentState.methodName,
                sessionType: currentState.sessionType
            )
            
            await activity.update(
                ActivityContent(
                    state: updatedState,
                    staleDate: Date().addingTimeInterval(24 * 60 * 60)
                )
            )
        }
    }
    
    // End the activity
    func endActivity() {
        guard let activity = currentActivity else { return }
        
        Task {
            await activity.end(
                dismissalPolicy: .immediate
            )
            
            await MainActor.run {
                self.currentActivity = nil
            }
        }
    }
}