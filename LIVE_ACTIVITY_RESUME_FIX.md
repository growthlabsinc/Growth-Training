# Live Activity Resume Fix - 1 Hour Duration Issue

## Problem
When resuming a paused Live Activity timer, it was showing "1:00:00 minus time elapsed" instead of the actual remaining time. The logs showed `remainingTimeAtLastUpdate: 3594 seconds` (nearly 1 hour), indicating a default 1-hour duration was being applied.

## Root Cause
1. **Firebase Function Default**: In `liveActivityUpdates.js` line 616, there was a hardcoded default endTime of 1 hour:
   ```javascript
   endTime: endTime || new Date(Date.now() + 3600000).toISOString(), // 3600000ms = 1 hour
   ```

2. **Incorrect Remaining Time Calculation**: When starting the timer sync, the remaining time was set to the total duration instead of accounting for elapsed time.

3. **Duration Not Preserved**: The actual timer duration wasn't being properly preserved through pause/resume cycles.

## Changes Made

### 1. Fixed Default Duration (functions/liveActivityUpdates.js)
Changed the default from 1 hour to 5 minutes:
```javascript
// Before:
endTime: endTime || new Date(Date.now() + 3600000).toISOString(),

// After:
endTime: endTime || new Date(Date.now() + 300000).toISOString(), // 5 minutes instead of 1 hour
```

### 2. Fixed Remaining Time Calculation (Growth/Features/Timer/Services/TimerStateSync.swift)
Updated to properly calculate remaining time when not paused:
```swift
if sessionType == "countdown" {
    let totalDuration = endTime.timeIntervalSince(startTime)
    // When not paused and we have a specific remaining time, use it
    // Otherwise calculate from the total duration minus elapsed time
    if isPaused {
        initialRemainingTime = remainingTime
    } else if remainingTime > 0 {
        // Use provided remaining time if available
        initialRemainingTime = remainingTime
    } else {
        // Calculate remaining time: total duration minus elapsed time
        initialRemainingTime = max(0, totalDuration - elapsedTime)
    }
}
```

### 3. Added Duration Validation (functions/manageLiveActivityUpdates.js)
Added logging to detect when the 1-hour default is being used:
```javascript
// CRITICAL: Log if total duration appears to be 1 hour
if (Math.abs(totalDuration - 3600) < 10) {
    console.error(`⚠️ [Duration Issue] Total duration is suspiciously close to 1 hour: ${totalDuration}s`);
    console.error(`  - This suggests a default duration is being used instead of actual timer duration`);
}
```

### 4. Duration Preservation (functions/liveActivityUpdates.js)
Added code to preserve the total duration through state changes:
```javascript
// CRITICAL: Preserve totalDuration if available to prevent 1-hour default
if (afterData.totalDuration) {
    contentState.totalDuration = afterData.totalDuration;
    console.log(`📊 Preserving total duration: ${contentState.totalDuration}s`);
}
```

## Testing Steps
1. Start a timer with a specific duration (e.g., 10 minutes)
2. Let it run for a minute
3. Pause the timer
4. Resume the timer
5. Verify the remaining time is correct (should be ~9 minutes, not ~59 minutes)

## Deployment
Deploy the updated Firebase functions:
```bash
firebase deploy --only functions:updateLiveActivity,functions:updateLiveActivityTimer,functions:onTimerStateChange,functions:manageLiveActivityUpdates
```

## Additional Notes
- The issue was that when no proper duration was available, the system defaulted to 1 hour
- This fix ensures the actual timer duration is preserved through pause/resume cycles
- The 5-minute default is only used as a last resort when no duration information is available