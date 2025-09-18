# Live Activity Timer - New Implementation Summary

## Architecture Overview

### Core Principles
1. **Use Native Timer APIs**: Let iOS handle timer updates automatically
2. **Minimal State**: Only track what changes (start time, pause state)
3. **Push for State Changes Only**: No periodic updates needed
4. **AppIntent for Buttons**: Reliable cross-process communication

## Key Components

### 1. Widget Views (`GrowthTimerWidgetLiveActivityNew.swift`)

#### Timer Display
```swift
// Running countdown timer
Text(timerInterval: startDate...endDate, countsDown: true)

// Running count-up timer  
Text(startDate, style: .timer)

// Paused timer (show static time)
Text(formatTime(remainingTime))
```

#### Progress Bar
```swift
// Running timer (auto-updates)
ProgressView(timerInterval: startDate...endDate, countsDown: false)
    .progressViewStyle(.linear)
    .tint(Color(red: 0.2, green: 0.8, blue: 0.4))

// Paused timer (static)
ProgressView(value: progress)
    .progressViewStyle(.linear)
    .tint(Color(red: 0.2, green: 0.8, blue: 0.4))
```

#### Interactive Buttons
```swift
// iOS 17+ with LiveActivityIntent
Button(intent: TimerControlIntent(
    action: .pause,
    activityId: context.activityID,
    timerType: context.attributes.timerType
)) {
    Image(systemName: "pause.fill")
}
.buttonStyle(.plain)
```

### 2. State Structure (`TimerActivityAttributes.swift`)

```swift
struct ContentState: Codable, Hashable {
    // Core state
    var startedAt: Date      // Adjusted when resuming
    var pausedAt: Date?      // Non-nil when paused
    var duration: TimeInterval
    var methodName: String
    var sessionType: SessionType
    
    // Computed properties
    var isPaused: Bool { pausedAt != nil }
    var endTime: Date { startedAt.addingTimeInterval(duration) }
}
```

### 3. AppIntent (`TimerControlIntent.swift`)

```swift
@available(iOS 17.0, *)
struct TimerControlIntent: LiveActivityIntent {
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "Action")
    var action: TimerAction
    
    func perform() async throws -> some IntentResult {
        // Write action to App Group
        AppGroupFileManager.shared.writeTimerAction(action.rawValue)
        
        // Send Darwin notification
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName("com.growthlabs.growthmethod.liveactivity.\(action)"),
            nil, nil, true
        )
        
        return .result(dialog: IntentDialog(""))
    }
}
```

### 4. Live Activity Manager (`LiveActivityManagerSimplified.swift`)

#### Start Timer
```swift
func startTimerActivity(methodId: String, methodName: String, 
                       duration: TimeInterval, sessionType: SessionType) {
    let now = Date()
    let contentState = ContentState(
        startedAt: now,
        pausedAt: nil,
        duration: duration,
        methodName: methodName,
        sessionType: sessionType
    )
    
    let activity = try Activity.request(
        attributes: attributes,
        content: ActivityContent(state: contentState, staleDate: staleDate),
        pushType: .token
    )
}
```

#### Pause/Resume
```swift
// Pause - just set pausedAt
let pausedState = ContentState(
    startedAt: currentState.startedAt,
    pausedAt: Date(),
    duration: currentState.duration,
    // ... other fields unchanged
)

// Resume - adjust startedAt
let pauseDuration = Date().timeIntervalSince(pausedAt)
let resumedState = ContentState(
    startedAt: currentState.startedAt.addingTimeInterval(pauseDuration),
    pausedAt: nil,  // Clear pause
    duration: currentState.duration,
    // ... other fields unchanged
)
```

### 5. Push Updates (`updateLiveActivitySimplified.js`)

```javascript
// Only called for state changes
const payload = {
    aps: {
        timestamp: Math.floor(Date.now() / 1000),
        event: 'update',
        'content-state': {
            startedAt: "2025-01-17T12:00:00Z",
            pausedAt: null,  // or ISO date if paused
            duration: 1800,  // seconds
            methodName: "Deep Breathing",
            sessionType: "countdown",
            isCompleted: false
        },
        'stale-date': staleTimestamp
    }
};
```

## Data Flow

### Starting Timer
1. App calls `startTimerActivity()`
2. Live Activity created with current time as `startedAt`
3. Native timer APIs begin updating automatically
4. Push token registered in Firestore
5. No periodic updates needed

### Pausing Timer
1. User taps pause button in Live Activity
2. AppIntent writes action to App Group
3. Darwin notification wakes app
4. App sets `pausedAt` to current time
5. Single push update sent with paused state
6. Widget shows static time/progress

### Resuming Timer
1. User taps resume button
2. App calculates pause duration
3. Adjusts `startedAt` by pause duration
4. Clears `pausedAt`
5. Single push update sent
6. Native timer APIs resume from correct position

### Timer Completion
1. For countdown: Native APIs stop at 00:00
2. App can detect completion and update state
3. Show completion message
4. Dismiss after delay

## Benefits

1. **Accuracy**: System-level 60fps updates
2. **Battery**: No wake-ups for updates
3. **Reliability**: Works when app is killed
4. **Simplicity**: ~70% less code
5. **Native**: Matches iOS timer behavior

## Testing Requirements

- **Must use real device** (not simulator)
- **iOS 16.2+** for push tokens
- **iOS 17+** for LiveActivityIntent
- **Notification permissions** enabled
- **Live Activities** enabled in Settings

## Limitations

1. Cannot customize timer format (always HH:MM:SS or MM:SS)
2. Cannot update progress bar styling dynamically
3. End state shows "00:00" (cannot change to custom text)
4. Must handle pause/resume through date math

These limitations are by design - Apple wants consistent timer behavior across all apps.