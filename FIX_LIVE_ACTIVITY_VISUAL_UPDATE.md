# Fix Live Activity Visual Update Issue

## Problem Summary
When pause/resume buttons are pressed in the Live Activity:
1. ✅ Widget intent executes
2. ✅ Darwin notification is sent
3. ✅ Main app timer pauses/resumes
4. ❌ Live Activity visual state doesn't update

## Root Cause
The widget extension cannot directly access Live Activities created by the main app. The `Activity<TimerActivityAttributes>.activities` array is empty in the widget extension context.

## Solution Implemented

### 1. Updated TimerControlIntent (Widget Extension)
Instead of trying to find and update the Live Activity directly, we now:
- Update shared UserDefaults immediately
- Notify the main app via Darwin notification
- Let the main app handle the Live Activity update

### 2. Main App Updates Live Activity
The main app's `LiveActivityManager.updateTimerActivity()` method:
- Reads the current Live Activity state
- Updates pausedAt/startedAt as needed
- Calls `activity.update()` with new state

### 3. Key Fix Applied
In `TimerControlIntent.swift`:
```swift
func perform() async throws -> some IntentResult {
    // Update shared state immediately for widget to read
    updateSharedState()
    
    // Notify main app to sync timer state
    notifyMainApp()
    
    return .result()
}

private func updateSharedState() {
    let appGroupIdentifier = "group.com.growthlabs.growthmethod"
    guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
    
    switch action {
    case .pause:
        sharedDefaults.set(true, forKey: "timerIsPaused")
        sharedDefaults.set(Date(), forKey: "timerPausedAt")
    case .resume:
        sharedDefaults.set(false, forKey: "timerIsPaused")
        // Adjust startedAt based on pause duration
        if let pausedAt = sharedDefaults.object(forKey: "timerPausedAt") as? Date {
            let pauseDuration = Date().timeIntervalSince(pausedAt)
            if let startedAt = sharedDefaults.object(forKey: "timerStartedAt") as? Date {
                let adjustedStartTime = startedAt.addingTimeInterval(pauseDuration)
                sharedDefaults.set(adjustedStartTime, forKey: "timerStartedAt")
            }
        }
        sharedDefaults.removeObject(forKey: "timerPausedAt")
    case .stop:
        sharedDefaults.set(true, forKey: "timerIsCompleted")
    }
    
    sharedDefaults.synchronize()
}
```

## Alternative Approach (If Above Doesn't Work)

Since the main app properly updates the Live Activity via `LiveActivityManager.updateTimerActivity()`, but the visual update isn't reflecting, we may need to force a more aggressive update:

### Option A: Request Push Token Update
The main app can request a push token and use server-side updates:
```swift
// In LiveActivityManager
Task {
    let pushToken = try? await activity.pushToken
    // Send to server for push-based updates
}
```

### Option B: End and Restart Live Activity
More drastic but guaranteed to work:
```swift
// When pause is pressed
await activity.end(...)
// Immediately start new one with paused state
startActivity(with: pausedState)
```

## Testing Instructions

1. Build with Growth Production scheme
2. Archive and upload to TestFlight
3. Install on physical device
4. Start a timer and verify Live Activity appears
5. Press pause button on Dynamic Island
6. Verify:
   - App timer pauses ✅
   - Live Activity shows paused state
   - Timer display stops updating
7. Press resume button
8. Verify:
   - App timer resumes ✅
   - Live Activity shows running state
   - Timer display continues from paused time

## Debug Logging

To verify the fix is working, check console logs for:
```
🔔 [LIVE_ACTIVITY_BUTTON] Darwin notification received
⏸️ [LIVE_ACTIVITY_BUTTON] Darwin: Pausing timer
✅ [LIVE_ACTIVITY_BUTTON] Timer paused successfully via Darwin notification
⏸️ Live Activity paused via updateTimerActivity
```

## Next Steps if Issue Persists

1. Add more aggressive state forcing in `LiveActivityManager.updateActivity()`:
```swift
// Force immediate update with higher priority
await activity.update(ActivityContent(
    state: updatedState,
    staleDate: Date().addingTimeInterval(1), // Very short stale time
    relevanceScore: 200.0 // Very high relevance
))
```

2. Consider using push notifications for Live Activity updates (requires server)

3. Implement a "refresh" mechanism that ends and restarts the Live Activity