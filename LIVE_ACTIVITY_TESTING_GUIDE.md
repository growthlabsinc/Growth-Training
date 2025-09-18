# Live Activity Testing Guide - UserDefaults Implementation

## Overview
This guide covers testing the Live Activity implementation that uses UserDefaults for communication between the widget extension and main app, following Apple's LiveActivityIntent pattern.

## Architecture Summary

### How It Works
1. **TimerControlIntent** (Widget Extension) - Handles button presses in Live Activity
2. **UserDefaults** (App Group) - Bridge for communication
3. **LiveActivityManager** (Main App) - Monitors UserDefaults and processes actions
4. **Firebase Push** - Updates Live Activity content

### Key Components
- `TimerControlIntent.swift` - LiveActivityIntent that runs in app process
- `LiveActivityManager.swift` - Monitors UserDefaults every 0.1 seconds
- App Group: `group.com.growthlabs.growthmethod`

## Testing Steps

### 1. Prerequisites
- Physical iOS device (iOS 17.0+ for full functionality)
- Xcode 15.0+
- TestFlight or Development build
- Firebase project access

### 2. Verify Target Membership
In Xcode:
1. Select `TimerControlIntent.swift`
2. Open File Inspector (⌥⌘1)
3. Verify Target Membership includes:
   - ✅ GrowthTimerWidgetExtension
   - ✅ Growth (main app)

### 3. Test Live Activity Start
```swift
// In the app, start a timer
1. Navigate to any timer screen
2. Start a timer
3. Verify Live Activity appears on Lock Screen
4. Check Dynamic Island shows timer
```

### 4. Test Pause/Resume via Live Activity
```swift
// Test pause button
1. With timer running, press pause button in Live Activity
2. Expected behavior (within 0.1 seconds):
   - Timer pauses in app
   - Live Activity shows paused state
   - Firebase push updates content

// Verify UserDefaults update
3. Check shared UserDefaults:
   - lastTimerAction: "pause"
   - lastActionTime: <recent timestamp>
   - timerIsPaused: true
```

### 5. Test Resume from Paused State
```swift
// Test resume button
1. With timer paused, press resume button in Live Activity
2. Expected behavior:
   - Timer resumes in app
   - Live Activity shows running state
   - Timer continues from paused duration
```

### 6. Test Stop Action
```swift
// Test stop button
1. With timer running/paused, press stop button
2. Expected behavior:
   - Timer stops in app
   - Live Activity ends
   - Completion animation shows
```

## Debugging

### Console Logs to Monitor
```bash
# Widget extension logs
log stream --predicate 'subsystem == "com.growthlabs.growthmethod.widget"'

# Main app Live Activity logs
log stream --predicate 'subsystem == "com.growthlabs.growthmethod" AND category == "LiveActivity"'

# Firebase push logs
log stream --predicate 'processImagePath CONTAINS "Growth" AND eventMessage CONTAINS "push"'
```

### UserDefaults Debugging
```swift
// Add this to LiveActivityManager for debugging
private func debugUserDefaults() {
    let keys = [
        "lastTimerAction",
        "lastActionTime", 
        "lastActivityId",
        "lastTimerType",
        "timerIsPaused",
        "timerStartedAt"
    ]
    
    for key in keys {
        if let value = sharedDefaults.object(forKey: key) {
            print("🔍 \(key): \(value)")
        }
    }
}
```

### Common Issues and Solutions

#### Issue: Button press doesn't update timer
**Check:**
- TimerControlIntent is in both targets
- App Group is configured correctly
- LiveActivityManager monitoring is running
- UserDefaults synchronization

**Solution:**
```swift
// Verify App Group access
if let sharedDefaults = UserDefaults(suiteName: "group.com.growthlabs.growthmethod") {
    print("✅ App Group accessible")
} else {
    print("❌ App Group not accessible")
}
```

#### Issue: 100ms delay feels noticeable
**Solution:**
The 0.1 second polling interval is typically imperceptible. If needed, can reduce to 0.05 seconds:
```swift
Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true)
```

#### Issue: Multiple actions queued
**Solution:**
Clear action after processing:
```swift
// In LiveActivityManager after processing
sharedDefaults.removeObject(forKey: "lastTimerAction")
sharedDefaults.removeObject(forKey: "lastActionTime")
```

## Firebase Push Testing

### Manual Push Test
```javascript
// functions/test-live-activity-update.js
const admin = require('firebase-admin');
admin.initializeApp();

async function testPush() {
    const activityId = "YOUR_ACTIVITY_ID";
    const pushToken = "YOUR_PUSH_TOKEN";
    
    const message = {
        token: pushToken,
        apns: {
            headers: {
                'apns-push-type': 'liveactivity',
                'apns-topic': 'com.growthlabs.growthmethod.push-type.liveactivity',
                'apns-priority': '10'
            },
            payload: {
                aps: {
                    'timestamp': Date.now() / 1000,
                    'event': 'update',
                    'content-state': {
                        startedAt: new Date().toISOString(),
                        pausedAt: null,
                        targetDuration: 300,
                        methodName: "Test Timer"
                    }
                }
            }
        }
    };
    
    const response = await admin.messaging().send(message);
    console.log('Push sent:', response);
}
```

## Performance Monitoring

### Memory Usage
```swift
// Monitor memory in LiveActivityManager
private func checkMemoryUsage() {
    let info = ProcessInfo.processInfo
    let memory = info.physicalMemory
    print("📊 Memory usage: \(memory / 1024 / 1024) MB")
}
```

### Battery Impact
- UserDefaults polling (0.1s) has minimal battery impact
- Consider reducing frequency during background if needed

## TestFlight Testing Checklist

- [ ] Live Activity appears when timer starts
- [ ] Pause button pauses timer within 0.1 seconds
- [ ] Resume button resumes from correct time
- [ ] Stop button ends Live Activity
- [ ] Dynamic Island shows correct state
- [ ] Lock Screen shows correct UI
- [ ] Firebase push updates work
- [ ] No memory leaks after extended use
- [ ] App Group data syncs correctly
- [ ] Works on iOS 16.1+ devices

## Production Readiness

### Before Release
1. Remove debug logging
2. Verify Firebase Functions are deployed
3. Test on multiple iOS versions (16.1, 17.0, 18.0)
4. Confirm APNS certificates are valid
5. Test with production Firebase environment

### Monitoring
- Track button interaction success rate
- Monitor UserDefaults sync delays
- Log Firebase push delivery rates
- Watch for crash reports in widget extension

## Alternative Approaches (Not Implemented)

### Darwin Notifications (Previous Approach)
- Used CFNotificationCenter for cross-process communication
- Issues: Unreliable delivery, complex setup
- Replaced with UserDefaults polling

### Direct Service Calls (Not Possible)
- Widget can't access main app's TimerService
- Would cause "Missing required module" errors
- LiveActivityIntent helps but still needs bridge

### Shared Framework (Too Complex)
- Would require extracting timer logic to framework
- Major refactoring effort
- UserDefaults approach simpler

## Conclusion

The UserDefaults-based approach with LiveActivityIntent provides:
- ✅ Reliable button interactions
- ✅ No compilation errors
- ✅ Fast response time (≤100ms)
- ✅ Clean separation of concerns
- ✅ Works with Firebase push updates

This implementation follows Apple's recommended patterns while working around the widget extension limitations.