# Live Activity Timer Migration Guide

## Overview
This guide shows how to migrate from the current Live Activity implementation to the new simplified version that uses Apple's native timer APIs.

## Key Changes

### 1. Timer Display
**OLD**: Manual calculations and periodic updates
```swift
// Manual progress calculation
let progress = elapsedTime / totalDuration
ProgressView(value: progress)

// Manual time formatting
Text(formatTime(remainingTime))
```

**NEW**: Native timer APIs
```swift
// Automatic progress updates
ProgressView(timerInterval: startDate...endDate, countsDown: false)

// Automatic timer display
Text(timerInterval: startDate...endDate, countsDown: true)
Text(startDate, style: .timer) // For count-up
```

### 2. State Management
**OLD**: Complex state with multiple timestamps
```swift
struct ContentState {
    var startTime: Date
    var endTime: Date
    var isPaused: Bool
    var lastUpdateTime: Date
    var elapsedTimeAtLastUpdate: TimeInterval
    var remainingTimeAtLastUpdate: TimeInterval
    // ... many more fields
}
```

**NEW**: Simplified state
```swift
struct ContentState {
    var startedAt: Date           // Adjusted for pauses
    var pausedAt: Date?          // Non-nil when paused
    var duration: TimeInterval   // Total duration
    var methodName: String
    var sessionType: SessionType
    var isCompleted: Bool
}
```

### 3. Push Updates
**OLD**: Frequent updates (every 0.1s - 1s)
**NEW**: Only on state changes (pause/resume/stop)

### 4. Pause/Resume Logic
**OLD**: Complex elapsed time tracking
**NEW**: Simple date adjustment
```swift
// Pausing: Store pausedAt
pausedAt = Date()

// Resuming: Adjust startedAt
let pauseDuration = Date().timeIntervalSince(pausedAt)
startedAt = startedAt.addingTimeInterval(pauseDuration)
pausedAt = nil
```

## Migration Steps

### Step 1: Update Widget Extension

1. Replace `GrowthTimerWidgetLiveActivity.swift` with new implementation:
```bash
cp GrowthTimerWidgetLiveActivityNew.swift GrowthTimerWidgetLiveActivity.swift
```

2. Ensure AppIntent files are added to both app and widget targets

### Step 2: Update TimerService

Replace timer Live Activity calls with simplified manager:

```swift
// OLD
LiveActivityManager.shared.startTimerActivity(
    methodId: methodId,
    methodName: methodName,
    startTime: startTime,
    endTime: endTime,
    duration: duration,
    sessionType: sessionType
)

// NEW
LiveActivityManagerSimplified.shared.startTimerActivity(
    methodId: methodId,
    methodName: methodName,
    duration: duration,
    sessionType: sessionType
)
```

### Step 3: Handle AppIntent Actions

Update `TimerService` to handle Darwin notifications:

```swift
// In init() or viewDidLoad
setupDarwinNotifications()

private func setupDarwinNotifications() {
    // Pause notification
    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        nil,
        { _, _, name, _, _ in
            Task { @MainActor in
                await TimerService.shared.pauseTimer()
            }
        },
        "com.growthlabs.growthmethod.liveactivity.pause" as CFString,
        nil,
        .deliverImmediately
    )
    
    // Similar for resume and stop...
}
```

### Step 4: Update Firebase Functions

Deploy the new simplified function:
```bash
firebase deploy --only functions:updateLiveActivitySimplified
```

Update function calls in app:
```swift
// Change function name
functions.httpsCallable("updateLiveActivitySimplified")
```

### Step 5: Testing Checklist

#### On Real Device (Required)
- [ ] Start timer - verify Live Activity appears
- [ ] Let timer run - verify it updates without app running
- [ ] Pause from Live Activity - verify pause state
- [ ] Resume from Live Activity - verify correct time
- [ ] Stop from Live Activity - verify dismissal
- [ ] Kill app - verify timer continues
- [ ] Test countdown completion
- [ ] Test Dynamic Island all states

#### State Verification
- [ ] App Group state syncs correctly
- [ ] Firebase state updates on changes only
- [ ] Push tokens are registered
- [ ] Darwin notifications are received

## Rollback Plan

If issues arise, restore from backup:
```bash
# Restore widget
cp backup-live-activity-*/GrowthTimerWidget/* GrowthTimerWidget/

# Restore timer services
cp backup-live-activity-*/Timer/* Growth/Features/Timer/

# Restore Firebase functions
cp backup-live-activity-*/manageLiveActivityUpdates.js functions/
cp backup-live-activity-*/liveActivityUpdates.js functions/

# Deploy original functions
firebase deploy --only functions
```

## Common Issues

### 1. Timer Not Updating
- Ensure using `timerInterval` not `value` in ProgressView
- Check date ranges are valid
- Verify not using manual calculations

### 2. Pause/Resume Time Wrong
- Check startedAt adjustment calculation
- Verify pausedAt is cleared on resume
- Test with different pause durations

### 3. Push Updates Not Working
- Must test on real device
- Check notification permissions
- Verify Firebase function deployed
- Check APNs configuration

### 4. Darwin Notifications Not Received
- Ensure observers are set up
- Check notification names match
- Verify running in app process

## Performance Benefits

1. **Battery Life**: No periodic updates = less battery drain
2. **Accuracy**: System handles timer at 60fps
3. **Reliability**: Works even when app is killed
4. **Simplicity**: Less code to maintain
5. **Native Feel**: Matches Apple's timer behavior

## Next Steps

1. Run full test suite on real device
2. Monitor Firebase function logs
3. Check crash reports for widget
4. Gather user feedback
5. Consider A/B testing rollout