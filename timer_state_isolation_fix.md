# Timer State Isolation Fix

## Issue
The quick practice timer was triggering state changes in the main timer. When returning from background, the main timer (DailyRoutineView) was picking up the paused state from the quick practice timer, showing incorrect elapsed time and remaining time.

## Root Cause
Both the main timer (TimerService.shared) and quick practice timer (QuickPracticeTimerTracker.shared.timerService) were using the same UserDefaults keys to save their state:
- `timerService.savedElapsedTime`
- `timerService.savedTimerState`
- `timerService.savedTimerMode`
- etc.

This caused state conflicts when both timers were used in the same session.

## Solution
Modified the TimerService to use different UserDefaults keys based on whether it's a quick practice timer:

1. Changed DefaultsKeys from static enum to dynamic struct that uses a key prefix
2. Quick practice timer uses prefix: `quickPracticeTimer`
3. Main timer uses prefix: `timerService`

### Code Changes

```swift
// Before (static keys for all instances)
private enum DefaultsKeys {
    static let savedElapsedTime = "timerService.savedElapsedTime"
    // ... etc
}

// After (dynamic keys based on timer type)
private struct DefaultsKeys {
    let keyPrefix: String
    
    init(isQuickPractice: Bool) {
        self.keyPrefix = isQuickPractice ? "quickPracticeTimer" : "timerService"
    }
    
    var savedElapsedTime: String { "\(keyPrefix).savedElapsedTime" }
    // ... etc
}

private var defaultsKeys: DefaultsKeys {
    return DefaultsKeys(isQuickPractice: isQuickPracticeTimer)
}
```

### Updated Methods
- `saveStateOnPauseOrBackground()`: Uses `defaultsKeys` instance
- `restoreState()`: Uses `defaultsKeys` instance  
- `clearSavedState()`: Uses `defaultsKeys` instance

## Result
- Quick practice timer saves to: `quickPracticeTimer.savedElapsedTime`, etc.
- Main timer saves to: `timerService.savedElapsedTime`, etc.
- No more state conflicts between the two timers
- Each timer maintains its own independent state in UserDefaults