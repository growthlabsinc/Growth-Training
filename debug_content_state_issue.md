# Live Activity ContentState Decoding Issue Debug Guide

## Issue Summary
The Live Activity shows "Unable to decode content state: The data couldn't be read because it isn't in the correct format" error approximately 2 seconds after starting a timer, which coincides with when the device screen is locked.

## Root Cause Analysis

### 1. Timing of the Error
- Error occurs at ~1.9 seconds after timer start
- This is exactly when the screen lock typically happens during testing
- The widget extension may be attempting to decode ContentState during a state transition

### 2. Potential Causes

#### A. Race Condition During Screen Lock
When the screen locks, iOS may:
- Suspend the widget extension briefly
- Interrupt the ActivityKit data transfer
- Cause partial data corruption during encoding/decoding

#### B. Widget Extension Memory Pressure
- Widget extensions have strict memory limits
- Screen lock may trigger memory cleanup
- Partial state may be lost during this process

### 3. Solutions to Try

#### Solution 1: Add Retry Logic in Widget
Add error handling in the widget's update method to retry decoding:

```swift
// In GrowthTimerWidgetLiveActivity.swift
struct TimerLockScreenView: View {
    let context: ActivityViewContext<TimerActivityAttributes>
    
    private var safeContentState: TimerActivityAttributes.ContentState {
        // Add defensive coding to handle decoding errors
        return context.state
    }
    
    var body: some View {
        // Use safeContentState instead of context.state
    }
}
```

#### Solution 2: Simplify Initial State
Reduce the initial ContentState complexity by deferring some calculations:

```swift
// In LiveActivityManager.swift startTimerActivity()
let contentState = TimerActivityAttributes.ContentState(
    startTime: startTime,
    endTime: endTime,
    methodName: methodName,
    sessionType: sessionType,
    isPaused: false,
    lastUpdateTime: now,
    elapsedTimeAtLastUpdate: 0,
    remainingTimeAtLastUpdate: duration, // Use duration directly
    lastKnownGoodUpdate: now,
    expectedEndTime: endTime, // Use endTime directly, not conditional
    isCompleted: false,
    completionMessage: nil
)
```

#### Solution 3: Delay Live Activity Start
Add a small delay before starting the Live Activity to ensure the app is fully in foreground:

```swift
Task {
    // Add a small delay to ensure app is stable
    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    
    await endCurrentActivity()
    
    // Continue with Live Activity creation...
}
```

#### Solution 4: Force Synchronous Update
Ensure the initial Live Activity creation is fully synchronous:

```swift
// Use MainActor.run to ensure UI thread
await MainActor.run {
    let activity = try Activity<TimerActivityAttributes>.request(
        attributes: attributes,
        content: ActivityContent(state: contentState, staleDate: staleDate),
        pushType: .token
    )
    self.currentActivity = activity
}
```

## Testing Steps

1. **Clean Build**
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/Growth-*
   xcodebuild clean -project Growth.xcodeproj -scheme Growth
   ```

2. **Test with Logging**
   ```bash
   # Monitor for the specific error
   log stream --predicate 'eventMessage CONTAINS "Unable to decode" OR eventMessage CONTAINS "content state"' --style compact
   ```

3. **Test Scenarios**
   - Start timer and immediately lock screen
   - Start timer and wait 5 seconds before locking
   - Start timer with screen already dimmed
   - Start timer in landscape mode then lock

## Next Steps

1. **Add defensive coding** in the widget to handle potential nil or corrupted states
2. **Add logging** around ContentState creation and updates
3. **Test with different iOS versions** to see if it's OS-specific
4. **Consider using UserDefaults** as a backup for state persistence

## Related Files
- `GrowthTimerWidget/TimerActivityAttributes.swift` - ContentState definition
- `Growth/Features/Timer/Services/LiveActivityManager.swift` - Live Activity creation
- `GrowthTimerWidget/GrowthTimerWidgetLiveActivity.swift` - Widget UI