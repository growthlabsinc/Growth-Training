# Quick Practice Timer Navigation Fix

## Problem
When navigating away from the quick practice timer and returning, the timer shows in a paused state instead of continuing to run.

## Root Cause
The `BackgroundTimerTracker` was intentionally setting restored timers to `.paused` state (line 117 in BackgroundTimerTracker.swift):
```swift
// Update timer state - if it was running, keep it as paused until explicitly started
if state.isRunning {
    timerService.timerState = .paused
}
```

This is appropriate for the main timer (where user expects manual control) but not for the quick practice timer which should continue running seamlessly.

## Solution
Modified `QuickPracticeTimerView` to automatically resume the timer if it was running before:

1. **In `handleOnAppear()` method**: After restoring timer state, check if it was running and resume it:
```swift
// Check if timer was running before and should be resumed
let wasRunning = backgroundState.isRunning

// If timer was running, resume it
if wasRunning && timerService.state == .paused {
    print("QuickPracticeTimerView: Timer was running, resuming...")
    timerService.resume()
}
```

2. **In back button handler**: Clear the restoration flag when exiting to allow proper restoration on return:
```swift
// Clear the restoration flag so timer can be restored when returning
hasRestoredFromBackground = false
```

## Testing Steps
1. Open Quick Practice Timer
2. Select a method and start the timer
3. Navigate away using back button
4. Navigate to Progress tab, then back to Practice tab
5. Open Quick Practice Timer again
6. Timer should be running (not paused) with correct elapsed time

## Additional Notes
- The glow effect will properly show when timer is running
- Background notifications continue to work as expected
- Timer state is preserved correctly across navigation
- No interference with main daily routine timer