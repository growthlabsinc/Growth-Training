# Live Activity Timer Redesign Plan

## Overview
Complete rebuild of Live Activity timer using Apple's best practices and native timer APIs.

## Architecture Changes

### 1. Timer Display Components

#### Progress Bar
```swift
// MUST use native ProgressView with timerInterval
ProgressView(timerInterval: startDate...endDate, countsDown: false)
    .progressViewStyle(.linear)
    .tint(Color(red: 0.2, green: 0.8, blue: 0.4))
```

#### Timer Text
```swift
// For countdown timers
Text(timerInterval: startDate...endDate, countsDown: true)
    .multilineTextAlignment(.center)
    .monospacedDigit()
    .font(.title2)

// For count-up timers  
Text(startDate, style: .timer)
    .multilineTextAlignment(.center)
    .monospacedDigit()
    .font(.title2)
```

### 2. State Management

#### Simplified TimerActivityAttributes
```swift
struct TimerActivityAttributes: ActivityAttributes {
    let methodId: String
    let methodName: String
    let totalDuration: TimeInterval
    let timerType: String
    
    struct ContentState: Codable, Hashable {
        let startDate: Date
        let endDate: Date
        let isPaused: Bool
        let pausedElapsedTime: TimeInterval? // Store elapsed time when paused
        let sessionType: SessionType
        let isCompleted: Bool
        
        enum SessionType: String, Codable {
            case countdown
            case countup
        }
    }
}
```

### 3. Interactive Buttons with AppIntent

#### LiveActivityIntent Implementation
```swift
// In Widget Target
@available(iOS 17.0, *)
struct PauseTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Pause Timer"
    
    @Parameter(title: "Activity ID")
    var activityId: String
    
    init() {}
    init(activityId: String) {
        self.activityId = activityId
    }
    
    func perform() async throws -> some IntentResult {
        // This will execute in app process
        return .result()
    }
}
```

#### Button Implementation
```swift
Button(intent: PauseTimerIntent(activityId: context.attributes.id)) {
    Image(systemName: "pause.fill")
        .font(.title3)
}
.buttonStyle(.plain)
.foregroundColor(.white)
```

### 4. Push Notification Updates

#### Update Strategy
- Use push notifications ONLY for state changes (pause/resume/stop)
- Native timer APIs handle continuous updates automatically
- Send push with new start/end dates when pausing/resuming

#### Payload Format
```json
{
  "aps": {
    "timestamp": 1234567890,
    "event": "update",
    "content-state": {
      "startDate": "2024-01-01T12:00:00Z",
      "endDate": "2024-01-01T12:30:00Z",
      "isPaused": false,
      "pausedElapsedTime": null,
      "sessionType": "countdown",
      "isCompleted": false
    }
  }
}
```

### 5. Pause/Resume Logic

#### Pausing
1. Store current elapsed time
2. Send push update with `isPaused: true` and `pausedElapsedTime`
3. Progress bar shows static value
4. Timer text shows static elapsed time

#### Resuming
1. Calculate new start/end dates based on remaining time
2. Send push update with new dates and `isPaused: false`
3. Native timer APIs automatically resume from correct position

### 6. View Layouts

#### Lock Screen View
```swift
VStack(spacing: 12) {
    HStack {
        Text(context.attributes.methodName)
            .font(.headline)
        Spacer()
        if context.state.isPaused {
            Text("PAUSED")
                .font(.caption)
                .foregroundColor(.orange)
        }
    }
    
    // Timer display
    if context.state.sessionType == .countdown {
        Text(timerInterval: context.state.startDate...context.state.endDate, 
             countsDown: true)
            .font(.system(size: 36, weight: .bold, design: .monospaced))
    } else {
        Text(context.state.startDate, style: .timer)
            .font(.system(size: 36, weight: .bold, design: .monospaced))
    }
    
    // Progress bar
    ProgressView(timerInterval: context.state.startDate...context.state.endDate, 
                 countsDown: false)
        .progressViewStyle(.linear)
        .tint(Color(red: 0.2, green: 0.8, blue: 0.4))
    
    // Action buttons
    HStack(spacing: 20) {
        Button(intent: context.state.isPaused ? 
               ResumeTimerIntent(activityId: context.attributes.id) :
               PauseTimerIntent(activityId: context.attributes.id)) {
            Image(systemName: context.state.isPaused ? "play.fill" : "pause.fill")
                .font(.title3)
        }
        
        Button(intent: StopTimerIntent(activityId: context.attributes.id)) {
            Image(systemName: "stop.fill")
                .font(.title3)
        }
    }
}
```

### 7. App Group Synchronization

Keep simplified state in App Group:
```swift
struct AppGroupTimerState: Codable {
    let activityId: String
    let startDate: Date
    let endDate: Date
    let isPaused: Bool
    let pausedElapsedTime: TimeInterval?
}
```

## Implementation Steps

1. **Create New Widget Views**
   - Implement lock screen view with native timer APIs
   - Implement Dynamic Island expanded/compact views
   - Remove all custom progress calculations

2. **Implement AppIntents**
   - Create PauseTimerIntent, ResumeTimerIntent, StopTimerIntent
   - Add to both app and widget targets
   - Implement Darwin notifications for IPC

3. **Update LiveActivityManager**
   - Simplify state management
   - Remove periodic local updates
   - Focus on push updates for state changes only

4. **Update Push Service**
   - Modify payload format
   - Send updates only on pause/resume/stop
   - Include proper date calculations

5. **Testing**
   - Test on real device (not simulator)
   - Verify timer continues when app is killed
   - Test pause/resume with correct time preservation
   - Verify Dynamic Island updates

## Migration Notes

- Remove all Timer objects from Live Activity
- Remove manual progress calculations
- Remove frequent push updates (not needed with native APIs)
- Ensure all dates are properly formatted
- Test thoroughly on iOS 16.2+ and iOS 17+ devices