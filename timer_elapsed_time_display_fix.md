# Timer Elapsed Time Display Fix for Background Completion

## Issue
When a countdown timer completes in the background and the user returns to the app later, the completion sheet displayed the wrong total time. It showed the time from timer start to when the user returned to the app, rather than the actual timer duration. For example, a 10-minute timer at 5x speed completed in 2 minutes, but if the user returned 3 minutes after completion, it showed 5 minutes total time.

## Root Cause
The `SessionProgress.totalElapsedTime` was calculated using wall clock time (`endTime - startTime`) rather than the timer's actual elapsed time. This caused the displayed duration to include time spent after the timer had already completed.

## Solution
Added support for storing and using the actual timer elapsed time:

### 1. SessionProgress Model
Added `actualElapsedTime` property to store the timer's elapsed time:
```swift
var actualElapsedTime: TimeInterval?  // Store the actual timer elapsed time

var totalElapsedTime: TimeInterval {
    // If we have stored the actual elapsed time (from timer), use that
    if let actualElapsed = actualElapsedTime {
        return actualElapsed
    }
    // Otherwise fall back to wall clock time
    let end = endTime ?? Date()
    return end.timeIntervalSince(startTime)
}
```

### 2. SessionCompletionViewModel
Updated to accept and store timer elapsed time:
- Added `timerElapsedTime` parameter to `completeSession()`
- Added `timerElapsedTime` parameter to `updateMethodProgress()`
- Store the timer's elapsed time in `SessionProgress.actualElapsedTime`

### 3. DailyRoutineView
Updated all places where session completion is handled to pass the timer's elapsed time:
- When stop button is pressed: captures `timerService.elapsedTime` before stopping
- When timer completes naturally: passes elapsed time to `updateMethodProgress`
- When showing completion prompt: stores elapsed time in session progress

## Results
- Completion sheet now shows the correct session duration based on the timer's elapsed time
- Works correctly with the 5x debug speed multiplier
- Background completion scenarios show accurate times
- Users see the expected duration (e.g., 10 minutes for a 10-minute timer) regardless of when they return to the app

## Testing
1. Start a countdown timer (e.g., 10 minutes)
2. Enable 5x speed in development tools
3. Background the app before completion
4. Wait for completion notification (2 minutes at 5x speed)
5. Wait additional time before returning to app
6. Verify completion sheet shows 10 minutes (target duration), not the wall clock time