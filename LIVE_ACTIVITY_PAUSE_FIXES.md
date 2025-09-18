# Live Activity Pause Fixes

## Issues Found

1. **Incorrect Time Display**: When pausing, the Live Activity shows the current time left plus 59:00
2. **Crash on Tap**: Live Activity crashes when tapped

## Root Causes

1. **Time Calculation Issue**: The `updateActivity` function was recalculating `startTime` incorrectly when resuming
2. **Total Duration**: The widget might be using incorrect total duration for progress calculations

## Fixes Applied

### 1. Fixed Resume Time Calculation
In `LiveActivityManager.swift`, updated the resume logic to properly extend the end time by the pause duration instead of recalculating start time:

```swift
// Calculate how long we were paused
let pauseDuration = now.timeIntervalSince(activity.content.state.lastUpdateTime)

// Extend the end time by the pause duration
updatedState.endTime = activity.content.state.endTime.addingTimeInterval(pauseDuration)
```

### 2. Local Update for Immediate Feedback
Added local Live Activity update before push notification:

```swift
// Update the Live Activity locally for immediate feedback
await activity.update(
    ActivityContent(state: updatedState, staleDate: staleDate)
)
```

## Remaining Issues

1. **Crash on Tap**: This might be due to:
   - App Group file access permissions
   - Missing entitlements
   - Intent handling issues

2. **Time Display**: The widget needs to correctly calculate elapsed/remaining time when paused

## Next Steps

1. Check App Group entitlements for both app and widget
2. Verify the widget's time calculation logic when paused
3. Test with a fresh timer to ensure clean state

## Testing

1. Build and run the app
2. Start a 1-minute timer
3. Pause after 10 seconds
4. Check that Live Activity shows ~50 seconds remaining (not 1:49)
5. Resume and verify timer continues correctly