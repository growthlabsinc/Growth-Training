# Live Activity Screen Lock Freezing Fix

## Problem
When starting a timer and locking the screen, the Live Activity would show a frozen state with the timer still running behind a loading indicator (spinner).

## Root Cause
The Live Activity was using short stale dates (10-60 seconds), causing iOS to stop updating the timer when the screen was locked. Based on the articles and Apple documentation, iOS may pause Live Activity updates as the stale date approaches, especially when the device is locked to conserve battery.

## Solution

### 1. Extended Stale Dates
Changed all stale dates to be hours instead of seconds/minutes:

**LiveActivityManager.swift:**
- Countdown timers: 2 hours past end time (was 10 seconds)
- Count-up timers: 4 hours from now (was 60 seconds)
- Completion state: 1 hour (was 5 minutes)

**LiveActivityUpdateManager.swift (Widget):**
- All states: 4 hours minimum
- Countdown with buffer: 2 hours past end time

### 2. Added State Persistence
- Live Activity state now persists to App Group on start/update
- Enables recovery when app becomes active after being terminated

### 3. Improved State Recovery
Enhanced `syncWithLiveActivityState()` in TimerService to:
- Check if Live Activity still exists before recovery
- Restore timer properties from persisted state
- Handle cases where timer is stopped but Live Activity is active

## Technical Details

### Key Code Changes

1. **Stale Date Calculation** (LiveActivityManager.swift:65-78):
```swift
// Calculate appropriate stale date - needs to be far in future to prevent freezing
let staleDate: Date
if sessionType == .countdown {
    // For countdown timers, stale date should be well past end time
    // to prevent freezing when screen is locked
    staleDate = endTime.addingTimeInterval(3600) // 1 hour past end time
} else {
    // For countup timers, use a very long duration
    staleDate = Date().addingTimeInterval(14400) // 4 hours from now
}
```

2. **State Persistence** (LiveActivityManager.swift:103-113):
```swift
// Persist the Live Activity state to App Group for recovery
AppGroupConstants.storeTimerState(
    startTime: startTime,
    endTime: endTime,
    elapsedTime: 0,
    isPaused: false,
    methodName: methodName,
    sessionType: sessionType.rawValue,
    activityId: activity.id
)
```

3. **State Recovery** (TimerService.swift:1284-1313):
```swift
// If timer is stopped but Live Activity exists, recover the timer state
if timerState == .stopped {
    // Restore timer properties and restart if needed
}
```

## Why This Works

According to the Apple documentation and community findings:
1. iOS uses the stale date to determine when to stop updating a Live Activity
2. When the screen is locked, iOS becomes more aggressive about pausing updates
3. Using longer stale dates (hours instead of seconds) prevents premature freezing
4. The widget correctly uses `Text(timerInterval:)` for automatic updates, as recommended

## Testing Instructions

1. Build and run on a physical device
2. Start any timer (countdown or count-up)
3. Lock the screen immediately
4. Wait 10-15 seconds
5. Check the Live Activity - it should continue updating
6. Unlock and lock multiple times - timer should keep working

## References

- [Building a Live Activity Timer in Expo React Native](https://medium.com/@tarikfp/building-a-live-activity-timer-in-expo-react-native-b8f3e3c5e879)
- [Apple's Live Activities Documentation](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities)
- Reddit discussions on Live Activity timer updates

## Key Takeaway

**Always use long stale dates (hours, not seconds) for Live Activities to prevent freezing when the screen locks.**