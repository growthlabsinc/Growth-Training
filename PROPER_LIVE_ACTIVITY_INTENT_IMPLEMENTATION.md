# Proper LiveActivityIntent Implementation

## Current Issue
We're using `LiveActivityIntent` but not following Apple's recommended pattern. The `perform()` method should directly update the Live Activity, not just send notifications to the main app.

## Apple's Recommended Approach

From Apple's documentation:
> "Create and start a Live Activity manually in your perform() method."

For modifying existing Live Activities, the widget extension should:
1. Find the relevant Live Activity using the activity ID
2. Update its content state directly
3. Let ActivityKit handle the visual updates

## Proper Implementation

```swift
import AppIntents
import ActivityKit
import Foundation

@available(iOS 17.0, *)
struct TimerControlIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Control Timer"
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "Action")
    var action: TimerAction
    
    @Parameter(title: "Activity ID")
    var activityId: String
    
    @Parameter(title: "Timer Type")
    var timerType: String
    
    func perform() async throws -> some IntentResult {
        // Find the Live Activity
        guard let activity = Activity<TimerActivityAttributes>.activities
            .first(where: { $0.id == activityId }) else {
            // If no activity found, fall back to notifying main app
            notifyMainApp()
            return .result()
        }
        
        // Update the Live Activity directly based on action
        let currentState = activity.content.state
        var updatedState = currentState
        
        switch action {
        case .pause:
            // Set pausedAt timestamp
            updatedState.pausedAt = Date()
            
        case .resume:
            // Adjust startedAt and clear pausedAt
            if let pausedAt = currentState.pausedAt {
                let pauseDuration = Date().timeIntervalSince(pausedAt)
                updatedState.startedAt = currentState.startedAt.addingTimeInterval(pauseDuration)
                updatedState.pausedAt = nil
            }
            
        case .stop:
            // End the activity
            await activity.end(
                ActivityContent(
                    state: TimerActivityAttributes.ContentState(
                        startedAt: currentState.startedAt,
                        pausedAt: Date(),
                        duration: currentState.duration,
                        methodName: currentState.methodName,
                        sessionType: .completed
                    ),
                    staleDate: nil
                ),
                dismissalPolicy: .immediate
            )
            
            // Also notify main app for cleanup
            notifyMainApp()
            return .result()
        }
        
        // Update the Live Activity
        await activity.update(ActivityContent(
            state: updatedState,
            staleDate: Date().addingTimeInterval(28800),
            relevanceScore: updatedState.isRunning ? 100.0 : 50.0
        ))
        
        // Also notify main app to sync timer state
        notifyMainApp()
        
        return .result()
    }
    
    private func notifyMainApp() {
        // Write to UserDefaults for main app to read
        let appGroupIdentifier = "group.com.growthlabs.growthmethod"
        if let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) {
            sharedDefaults.set(action.rawValue, forKey: "lastTimerAction")
            sharedDefaults.set(timerType, forKey: "lastTimerType")
            sharedDefaults.set(Date(), forKey: "lastActionTime")
            sharedDefaults.set(activityId, forKey: "lastActivityId")
            sharedDefaults.synchronize()
        }
        
        // Post Darwin notification
        let notificationName = "com.growthlabs.growthmethod.liveactivity.action"
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(notificationName as CFString),
            nil,
            nil,
            true
        )
    }
}
```

## Key Benefits

1. **Instant Visual Updates**: Live Activity updates immediately without waiting for main app
2. **Follows Apple's Guidelines**: Proper use of `LiveActivityIntent`
3. **More Reliable**: Direct updates don't depend on Darwin notifications
4. **Maintains Sync**: Still notifies main app to keep timer state in sync

## Implementation Steps

1. Import `ActivityKit` in the widget extension
2. Update `perform()` to directly modify the Live Activity
3. Keep Darwin notification as backup for main app sync
4. Test on physical device with iOS 17+

## Important Notes

- The widget extension needs access to `TimerActivityAttributes`
- Both widget and main app must share the same Activity type
- The activity ID must match between widget buttons and Live Activity
- iOS 17.0+ required for `LiveActivityIntent`

## Testing

After implementation:
1. Start a timer with Live Activity
2. Press pause button - should update instantly
3. Press resume button - should update instantly
4. Check main app timer is also synced