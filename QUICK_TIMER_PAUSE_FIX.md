# Quick Timer Live Activity Pause Issue Fix

## Problem
When pausing the quick practice timer from the lock screen Live Activity:
1. Timer pauses briefly
2. Then immediately restarts 
3. Subsequent pause attempts don't work

## Root Cause
Race condition in the background restoration logic:

1. **Pause Action**: User taps pause → notification sent → timer pauses
2. **Foreground Event**: App enters foreground → `willEnterForegroundNotification` fires
3. **Restoration**: `handleOnAppear()` → `restoreFromBackground()` → timer resumes
4. **Race Condition**: The Live Activity pause state hasn't propagated when restoration checks occur

## Solution

### Option 1: Add Delay Before Restoration (Quick Fix)
Increase the delay in `QuickPracticeTimerView` line 178:
```swift
// Change from 0.1 to 0.5 seconds
DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
```

### Option 2: Check Recent Pause State (Better Fix)
Add a timestamp check to prevent restoration if timer was recently paused:

```swift
// In TimerService
private var lastPauseTime: Date?

func pause() {
    lastPauseTime = Date()
    // ... existing pause logic
}

func restoreFromBackground() {
    // Don't restore if paused within last 2 seconds
    if let pauseTime = lastPauseTime, 
       Date().timeIntervalSince(pauseTime) < 2.0 {
        print("Recently paused, skipping restoration")
        return
    }
    // ... existing restoration logic
}
```

### Option 3: Improve Live Activity State Check (Best Fix)
Store pause state in App Group immediately when pause is triggered:

```swift
// In LiveActivityManagerSimplified
func pauseTimer() async {
    // Store pause state in App Group FIRST
    if let defaults = UserDefaults(suiteName: AppGroupConstants.identifier) {
        defaults.set(true, forKey: "timerPausedViaLiveActivity")
        defaults.set(Date(), forKey: "timerPauseTime")
    }
    
    // Then update Live Activity
    // ... existing pause logic
}

// In TimerService.restoreFromBackground()
// Check App Group for recent pause
if let defaults = UserDefaults(suiteName: AppGroupConstants.identifier),
   defaults.bool(forKey: "timerPausedViaLiveActivity"),
   let pauseTime = defaults.object(forKey: "timerPauseTime") as? Date,
   Date().timeIntervalSince(pauseTime) < 3.0 {
    print("Timer was paused via Live Activity, not restoring")
    return
}
```

## Recommended Implementation
Implement Option 3 as it's the most robust solution that properly handles the asynchronous nature of Live Activity updates.