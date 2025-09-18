# Timer Background Completion Fix

## Issue
When a countdown timer completes in the background and the user returns to the app after the completion time, the completion sheet showed the total elapsed time from timer start to when the user returned (e.g., showing 5 minutes for a 10-minute timer at 5x speed that completed in 2 minutes but user returned 3 minutes later).

## Root Cause
The elapsed time calculation continued accumulating even after the timer had completed in the background, resulting in inflated duration values.

## Solution
Implemented elapsed time capping for countdown timers at multiple points:

### 1. BackgroundTimerTracker.swift
In `restoreTimerState` method:
```swift
// Calculate compensated elapsed time
var totalElapsed = state.totalElapsedTime()

// For countdown timers, cap elapsed time at the target duration
if state.timerMode == "countdown", let totalDuration = state.totalDuration {
    totalElapsed = min(totalElapsed, totalDuration)
}
```

### 2. TimerService.swift
In `restoreState` method when handling background time:
```swift
// For countdown timers, cap elapsed time at target duration
if sMode == .countdown {
    self.elapsedTime = min(self.elapsedTime, self.targetDuration)
    #if DEBUG
    self.actualElapsedTime = min(self.actualElapsedTime, self.targetDuration / TimerService.debugSpeedMultiplier)
    #endif
    self.remainingTime = max(0, self.targetDuration - self.elapsedTime)
}
```

In `handleTimerCompletion` method:
```swift
if currentTimerMode == .countdown {
    elapsedTime = targetDuration // Ensure elapsedTime reflects full duration
    #if DEBUG
    actualElapsedTime = targetDuration / TimerService.debugSpeedMultiplier
    #endif
    remainingTime = 0
}
```

## Results
- Countdown timers now correctly show the target duration as the elapsed time when completed
- The completion sheet displays the accurate session duration (e.g., 10 minutes for a 10-minute timer)
- Works correctly with the 5x debug speed multiplier
- Background completion scenarios handled properly

## Testing
1. Start a countdown timer
2. Background the app before completion
3. Wait for completion notification
4. Wait additional time before returning to app
5. Verify completion sheet shows correct duration (target duration, not elapsed time since start)