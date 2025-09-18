# Live Activity Pause/Resume Time Fix

## Date: 2025-09-11

## Issue Description
When pausing and resuming a Live Activity countdown timer, the displayed time was incorrect after resume. The timer would show the time as if it had been running during the pause period.

## Root Cause
The Live Activity widget calculates remaining time using:
- `endTime = startedAt + duration`
- When paused: Shows static `getFormattedRemainingTime()` based on `pausedAt - startedAt`
- When resumed: Shows countdown from `startedAt...endTime`

The problem was that when resuming, we weren't adjusting `startedAt` to account for the pause duration, so the countdown would jump back to an earlier time.

## Solution
Adjust `startedAt` forward by the pause duration when resuming. This shifts the entire timer window forward, maintaining the correct remaining time.

## Code Changes

### LiveActivityManager.swift - updateTimerActivity()

```swift
// When resuming from pause
if let pausedAt = currentState.pausedAt {
    let pauseDuration = Date().timeIntervalSince(pausedAt)
    
    // Adjust startedAt to account for the pause duration
    let adjustedStartTime = currentState.startedAt.addingTimeInterval(pauseDuration)
    
    updatedState = TimerActivityAttributes.ContentState(
        startedAt: adjustedStartTime,
        pausedAt: nil,
        duration: currentState.duration,
        methodName: currentState.methodName,
        sessionType: currentState.sessionType
    )
}
```

### LiveActivityManager.swift - handlePushUpdateRequest()

```swift
case "resume":
    // When resuming, adjust startedAt to account for pause duration
    if let pausedAt = currentState.pausedAt {
        let pauseDuration = Date().timeIntervalSince(pausedAt)
        let adjustedStartTime = currentState.startedAt.addingTimeInterval(pauseDuration)
        
        updatedState = TimerActivityAttributes.ContentState(
            startedAt: adjustedStartTime,
            pausedAt: nil,
            duration: currentState.duration,
            methodName: currentState.methodName,
            sessionType: currentState.sessionType
        )
    }
```

## Comprehensive Logging Added

### Pause Event Logging
```swift
print("🔍 [PAUSE] Live Activity pause details:")
print("  - Pause time: \(pauseTime)")
print("  - Elapsed since start: \(elapsedSinceStart)s")
print("  - Remaining time: \(remainingTime)s")
print("  - Will show in widget: \(Int(remainingTime/60)):\(String(format: "%02d", Int(remainingTime) % 60))")
```

### Resume Event Logging
```swift
print("🔍 [RESUME] Live Activity resume details:")
print("  - Resume time: \(Date())")
print("  - Pause duration: \(pauseDuration)s")
print("  - Original startedAt: \(currentState.startedAt)")
print("  - Adjusted startedAt: \(adjustedStartTime)")
print("  - Actual elapsed (from timer): \(actualElapsed)s")
print("  - Remaining time: \(currentState.duration - actualElapsed)s")
```

### Update State Logging
```swift
print("🔍 [LIVE_ACTIVITY_UPDATE] Called with:")
print("  - elapsedTime: \(elapsedTime)s")
print("  - isRunning: \(isRunning)")
print("  - isPaused: \(isPaused)")
print("  - Current startedAt: \(activity.content.state.startedAt)")
print("  - Current pausedAt: \(String(describing: activity.content.state.pausedAt))")
print("  - Current duration: \(activity.content.state.duration)s")
```

## Timeline Example

### 20-minute timer (1200s duration):
1. **Start**: `startedAt = 10:00:00`, `endTime = 10:20:00`
2. **After 5 minutes** (10:05:00): Timer shows 15:00 remaining
3. **Pause**: `pausedAt = 10:05:00`, widget shows static "15:00"
4. **Wait 2 minutes** (pause duration)
5. **Resume at 10:07:00**:
   - Pause duration = 2 minutes (120s)
   - Adjusted `startedAt = 10:00:00 + 120s = 10:02:00`
   - New `endTime = 10:02:00 + 1200s = 10:22:00`
   - Timer correctly shows 15:00 remaining (counting down to 10:22:00)

## Testing
1. Start a countdown timer
2. Let it run for a few minutes
3. Pause the timer - note the remaining time
4. Wait any amount of time
5. Resume the timer
6. **Expected**: Timer continues from where it was paused
7. **Fixed**: Timer no longer jumps to incorrect time

## Note on Push Update Errors
The "INTERNAL" errors from Firebase are due to App Check token validation issues in development. These don't affect the local Live Activity updates which work correctly. The push updates are a backup mechanism for remote updates.