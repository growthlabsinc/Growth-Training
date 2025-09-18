# Timer Cross-Interference Fix

## Problem
When stopping the main timer, it was also stopping the quick timer. This was happening because:
1. TimerCoordinator calls `QuickPracticeTimerService.shared.stop()` when main timer starts
2. Both timers share the same `LiveActivityManagerSimplified` singleton
3. When quick timer stops, it calls `LiveActivityManagerSimplified.shared.stopTimer()` which could affect the main timer's Live Activity

## Solution
Added logic to ensure each timer only stops its own Live Activity:

### 1. Enhanced stop() method in TimerService
- Added `fromCoordinator` parameter to track when stop is called by coordinator
- Added check to verify timer owns the current Live Activity before stopping it
- Only stops Live Activity if `activity.attributes.timerType` matches the timer type

### 2. Updated QuickPracticeTimerService
- Modified `stop()` to accept and pass through `fromCoordinator` flag

### 3. Updated TimerCoordinator
- Now calls `stop(fromCoordinator: true)` when stopping quick timer

### 4. Added Debug Logging
- Enhanced logging in Darwin notification handler to track which timer receives notifications
- Added logging to track Live Activity ownership checks

## Key Code Changes

```swift
// TimerService.swift
public func stop(fromCoordinator: Bool = false) {
    // ... existing code ...
    
    if #available(iOS 16.1, *) {
        Task {
            // Only stop if this timer owns the current activity
            if let activity = LiveActivityManagerSimplified.shared.currentActivity,
               activity.attributes.timerType == (isQuickPracticeTimer ? "quick" : "main") {
                await LiveActivityManagerSimplified.shared.stopTimer()
            }
        }
    }
}
```

## Testing
1. Start quick timer - verify it runs properly
2. Start main timer - verify quick timer stops but main timer continues
3. Stop main timer - verify only main timer stops, quick timer unaffected
4. Check console logs for proper timer type filtering