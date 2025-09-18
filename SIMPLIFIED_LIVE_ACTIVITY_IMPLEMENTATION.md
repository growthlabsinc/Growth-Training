# Simplified Live Activity Implementation

## Overview
Based on best practices from the tutorials provided, we've simplified the Live Activity update mechanism to be more reliable and less complex.

## Key Principles Applied

### 1. **startedAt/pausedAt Pattern** (from expo-live-activity-timer)
- Store `startedAt` timestamp when timer begins
- Store `pausedAt` timestamp when paused
- When resuming, adjust `startedAt` by pause duration
- Let iOS handle timer display with `Text(timerInterval:)`

### 2. **Direct State Updates** (from iOS native tutorials)
- Update Live Activity content state immediately
- Use high priority tasks for updates
- Only update when state actually changes
- Avoid unnecessary repeated updates

### 3. **Shared State Management** (from React Native tutorials)
- Store timer state in shared UserDefaults (App Groups)
- Synchronize state between app and widget
- Use Darwin notifications for inter-process communication

## Implementation Changes

### 1. Removed Double Update Pattern
**Before**: Updated Live Activity twice (immediate + 0.2s delay)
```swift
// First update immediately
LiveActivityManager.shared.updateTimerActivity(...)
// Then update again after delay
DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
    LiveActivityManager.shared.updateTimerActivity(...)
}
```

**After**: Single immediate update
```swift
// Update Live Activity immediately
LiveActivityManager.shared.updateTimerActivity(
    elapsedTime: self.elapsedTime,
    isRunning: false,
    isPaused: true
)
```

### 2. Improved LiveActivityManager Updates
- Added high priority task for immediate updates
- Only update when state actually changes
- Better logging for debugging
- Sync detection to avoid unnecessary updates

```swift
Task(priority: .high) {
    var needsUpdate = false
    
    if isPaused && !currentlyPaused {
        updatedState.pausedAt = Date()
        needsUpdate = true
    } else if isRunning && currentlyPaused {
        // Adjust startedAt when resuming
        let pauseDuration = Date().timeIntervalSince(pausedAt)
        updatedState.startedAt = currentState.startedAt.addingTimeInterval(pauseDuration)
        updatedState.pausedAt = nil
        needsUpdate = true
    }
    
    if needsUpdate {
        await activity.update(ActivityContent(...))
    }
}
```

### 3. Enhanced Shared State Storage
- Store initial state when Live Activity starts
- Update shared UserDefaults when buttons pressed
- Include all necessary timer metadata

```swift
sharedDefaults.set(initialState.startedAt, forKey: "timerStartedAt")
sharedDefaults.set(false, forKey: "timerIsPaused")
sharedDefaults.set(duration, forKey: "timerDuration")
sharedDefaults.set(methodName, forKey: "timerMethodName")
sharedDefaults.set(activity.id, forKey: "currentActivityId")
sharedDefaults.synchronize()
```

### 4. Simplified TimerControlIntent
- Updates shared state immediately
- Calculates adjusted start time for resume
- Notifies main app via Darwin notification
- No complex Live Activity lookup needed

## How It Works Now

### When Timer Starts:
1. `LiveActivityManager` creates Live Activity with initial state
2. Stores timer state in shared UserDefaults
3. Live Activity displays using `Text(timerInterval:)` for automatic updates

### When Pause Button Pressed (Live Activity):
1. `TimerControlIntent.perform()` executes
2. Updates shared UserDefaults with pause state
3. Sends Darwin notification to main app
4. Main app receives notification and updates timer
5. `LiveActivityManager.updateTimerActivity()` updates Live Activity

### When Resume Button Pressed (Live Activity):
1. `TimerControlIntent.perform()` executes
2. Calculates pause duration
3. Adjusts `startedAt` in shared UserDefaults
4. Sends Darwin notification to main app
5. Main app resumes timer and updates Live Activity

## Benefits of Simplified Approach

1. **Fewer Moving Parts**: Single update instead of multiple
2. **Better Performance**: High priority tasks, conditional updates
3. **More Reliable**: Direct state updates, proper synchronization
4. **Easier to Debug**: Clear logging, single source of truth
5. **Following Best Practices**: Based on proven patterns from tutorials

## Testing Checklist

- [ ] Build with Growth Production scheme
- [ ] Archive and upload to TestFlight
- [ ] Install on physical device
- [ ] Start timer and verify Live Activity appears
- [ ] Press pause on Dynamic Island - verify:
  - Timer pauses in app
  - Live Activity shows paused state
  - Timer display stops updating
- [ ] Press resume on Dynamic Island - verify:
  - Timer resumes in app
  - Live Activity shows running state
  - Timer continues from paused time
- [ ] Test multiple pause/resume cycles
- [ ] Verify state persists when app is backgrounded

## Debug Tips

Monitor console logs for:
```
⏸️ Setting pausedAt to pause Live Activity
▶️ Adjusting startedAt by Xs to resume Live Activity
✅ Live Activity updated successfully
📝 Stored initial timer state in shared UserDefaults
```

If issues persist:
1. Check shared UserDefaults values are being set
2. Verify Darwin notifications are received
3. Ensure Activity ID matches between widget and app
4. Check iOS version compatibility (16.2+ for best support)