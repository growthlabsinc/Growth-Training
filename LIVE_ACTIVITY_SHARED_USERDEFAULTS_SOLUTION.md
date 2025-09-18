# Live Activity Implementation via Shared UserDefaults

## The Problem

When `TimerControlIntent` is included in both the widget extension and main app targets:
- Widget extension can't access main app's dependencies (Firebase, TimerService, etc.)
- Compilation fails with "Cannot find 'TimerService' in scope" errors

## The Solution

Use **App Group UserDefaults** as a communication bridge:

### 1. Widget Extension Side (TimerControlIntent)
- Writes action details to shared UserDefaults
- Doesn't directly call timer services
- No dependency on main app code

### 2. Main App Side (LiveActivityManager)
- Monitors shared UserDefaults for actions
- Processes actions when detected
- Calls timer services directly

## How It Works

### When Button is Pressed:
1. `TimerControlIntent.perform()` runs in app process (via `LiveActivityIntent`)
2. Writes action to shared UserDefaults:
   - `lastTimerAction`: "pause", "resume", or "stop"
   - `lastTimerType`: "main" or "quick"
   - `lastActionTime`: Current timestamp
   - `lastActivityId`: Activity identifier

3. `LiveActivityManager` detects the action (within 0.1 seconds)
4. Processes the action by calling appropriate timer service
5. Sends Firebase push update to Live Activity

## Implementation Details

### TimerControlIntent.swift (Widget Extension)
```swift
private func performTimerAction() async {
    // Write to shared UserDefaults
    sharedDefaults.set(action.rawValue, forKey: "lastTimerAction")
    sharedDefaults.set(timerType, forKey: "lastTimerType")
    sharedDefaults.set(Date(), forKey: "lastActionTime")
    sharedDefaults.set(activityId, forKey: "lastActivityId")
    sharedDefaults.synchronize()
}
```

### LiveActivityManager.swift (Main App)
```swift
private func startMonitoringIntentActions() {
    Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
        // Check for pending actions
        if let actionTime = sharedDefaults.object(forKey: "lastActionTime") as? Date,
           Date().timeIntervalSince(actionTime) < 1.0 {
            // Process the action
        }
    }
}
```

## Benefits

1. **No Compilation Errors**: Widget doesn't reference main app code
2. **LiveActivityIntent Works**: Intent runs in app process as intended
3. **No Darwin Notifications**: Cleaner than cross-process notifications
4. **Fast Response**: 0.1 second polling is imperceptible to users

## Limitations

- Slight delay (up to 100ms) for action processing
- Timer polling overhead (minimal)
- Requires App Group configuration

## Alternative Approaches Considered

1. **Conditional Compilation**: Would require complex `#if` directives
2. **Shared Framework**: Too much refactoring to extract timer logic
3. **Darwin Notifications**: More complex than UserDefaults polling

## Configuration Requirements

1. **App Groups**: Both targets must have same App Group enabled
2. **Target Membership**: `TimerControlIntent.swift` in both targets
3. **LiveActivityIntent**: Intent must adopt this protocol

This approach provides a clean separation between widget and app code while maintaining the benefits of `LiveActivityIntent` running in the app process.