# Live Activity Pause/Resume Synchronization Fix

## Issue
The Live Activity pause button wasn't working correctly:
1. First tap didn't react
2. Subsequent taps updated the Live Activity UI to show paused state
3. BUT the countdown timer continued running (timer state not synced)
4. Firebase push updates failed with "INTERNAL" error

## Root Cause
The widget was correctly sending pause/resume notifications via Darwin notifications, and the LiveActivityManager was receiving them, but:
1. **Timer Service wasn't being notified** - LiveActivityManager only updated the Live Activity visual state without actually pausing/resuming the TimerService
2. **Firebase function field name compatibility** - The function expected `startTime`/`endTime` but iOS was correctly using `startedAt`/`pausedAt` pattern (as recommended by expo-live-activity-timer)

## Solution Applied

### 1. Fixed Timer Service Synchronization
Updated `LiveActivityManager.handlePushUpdateRequest()` to:
- First pause/resume/stop the actual TimerService based on the action
- Then update the Live Activity visual state
- This ensures the timer state and Live Activity UI stay in sync

### 2. Fixed Firebase Function Compatibility
Updated both iOS and Firebase sides for better compatibility:
- iOS now sends BOTH field naming conventions (startedAt/pausedAt AND startTime/endTime)
- Firebase function now accepts both naming patterns and converts as needed
- This maintains the correct `startedAt`/`pausedAt` pattern from expo-live-activity-timer while ensuring Firebase compatibility

## Implementation Details

### Flow After Fix:
1. User taps pause button in Dynamic Island/Lock Screen
2. Widget's `TimerControlIntent` updates App Group data and sends Darwin notification
3. `LiveActivityManager.handlePushUpdateRequest()` receives notification
4. **NEW**: Calls `TimerService.shared.pause()` to pause the actual timer
5. Updates Live Activity content state for visual update
6. Attempts Firebase push update (with correct parameters)
7. Falls back to local update if push fails

### Key Code Changes:

```swift
// LiveActivityManager.swift - handlePushUpdateRequest()
// Now updates TimerService BEFORE updating Live Activity
await MainActor.run {
    switch actionRawValue {
    case "pause":
        if timerType == "quick" {
            QuickPracticeTimerService.shared.timerService.pause()
        } else {
            TimerService.shared.pause()
        }
    // ... similar for resume and stop
    }
}
```

```swift
// LiveActivityManager.swift - sendPushUpdate()
// Now sends both naming conventions for compatibility
var contentStateData: [String: Any] = [
    // Primary fields (correct pattern from expo-live-activity-timer)
    "startedAt": ISO8601DateFormatter().string(from: state.startedAt),
    "pausedAt": state.pausedAt != nil ? ISO8601DateFormatter().string(from: state.pausedAt!) : nil,
    
    // Legacy fields for Firebase compatibility
    "startTime": ISO8601DateFormatter().string(from: state.startedAt),
    "endTime": ISO8601DateFormatter().string(from: endTime),
    "pauseTime": state.pausedAt != nil ? ISO8601DateFormatter().string(from: state.pausedAt!) : nil
]
```

```javascript
// liveActivityUpdates.js - sendLiveActivityUpdate()
// Now accepts both naming conventions
if (!contentState.startTime && contentState.startedAt) {
    contentState.startTime = contentState.startedAt;
}
if (!contentState.pauseTime && contentState.pausedAt) {
    contentState.pauseTime = contentState.pausedAt;
}
```

## Testing
After these fixes:
1. Pause button should immediately pause both the visual timer and actual timer
2. Resume button should correctly resume from paused state
3. Timer state should remain synchronized between app and Live Activity
4. Firebase push updates should work (if APNS keys are properly configured)

## Notes
- The fallback to local updates ensures functionality even if Firebase push fails
- Both main timer and quick practice timer are supported
- The iOS implementation correctly uses the `startedAt`/`pausedAt` pattern as recommended by expo-live-activity-timer and Apple's best practices
- The Firebase function now accepts both field naming conventions for backward compatibility
- The key insight from expo-live-activity-timer: using `Text(timerInterval:pauseTime:)` with `startedAt`/`pausedAt` avoids the need for frequent updates