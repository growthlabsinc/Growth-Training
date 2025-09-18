# Live Activity Permission Dialog Fix

## Date: 2025-09-10

### Problem
When users tap pause/resume buttons in Live Activity on Lock Screen, iOS shows a permission dialog:
- "Always Allow" or "Never Allow"
- Choosing "Always Allow" causes the Live Activity to freeze in a paused state
- The pause/resume buttons stop working after granting permission

### Root Cause
iOS 17+ requires user permission for LiveActivityIntent actions. The permission dialog interrupts the intent execution, causing:
1. The Live Activity update to get stuck mid-execution
2. Race condition between permission grant and activity update
3. The widget extension loses context after permission is granted

### Solution Implemented

#### 1. TimerControlIntent.swift Updates
- Added `isDiscoverable: Bool = false` to prevent Siri/Shortcuts discovery
- Added `description` for better permission dialog context
- Made local update asynchronous with Task wrapper
- Added small delay to handle permission dialog timing
- Improved logging for debugging

#### 2. Key Changes Made
```swift
// Added to prevent unnecessary discovery
static var isDiscoverable: Bool = false

// Wrapped local update in Task to avoid blocking
Task {
    await updateLiveActivityLocally()
}

// Added delay to handle permission dialog
try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
```

### Testing Instructions

#### First-Time Permission Test
1. **Reset permissions** (if previously granted):
   - Settings → Growth → Reset Location & Privacy
   - Or delete and reinstall the app

2. **Start a timer** in the app

3. **Lock the device** and view Live Activity on Lock Screen

4. **Tap pause button** - Permission dialog should appear

5. **Choose "Always Allow"**

6. **Verify**:
   - Live Activity should pause without freezing
   - Pause button should change to Resume
   - No loading spinner should appear

#### Subsequent Use Test
1. After granting permission, tap pause/resume multiple times
2. Verify immediate response without permission dialogs
3. Check timer syncs correctly with main app

### Alternative Approach (If Issues Persist)

If the permission dialog continues to cause issues, consider using a different interaction model:

#### Option 1: URL-Based Actions (No Permission Required)
Instead of App Intents, use deep links that open the app:

```swift
// In Live Activity View
Link(destination: URL(string: "growth://timer/pause")!) {
    // Pause button UI
}

// Handle in main app
.onOpenURL { url in
    if url.path == "/timer/pause" {
        timerService.pause()
        // Update Live Activity via push
    }
}
```

#### Option 2: Notification Actions
Use UNNotificationAction for Live Activity controls:

```swift
// Register notification actions
let pauseAction = UNNotificationAction(
    identifier: "PAUSE_TIMER",
    title: "Pause",
    options: []
)
```

### Known iOS Behaviors

1. **iOS 17.0-17.1**: Permission dialog appears every time
2. **iOS 17.2+**: Permission is remembered after first grant
3. **iOS 18+**: Improved permission handling with less intrusive UI

### Monitoring

Check for these indicators of permission issues:
1. Live Activity freezes after tapping button
2. Loading spinner appears and doesn't disappear
3. Buttons become unresponsive
4. Console shows "Failed to perform intent" errors

### Debug Commands

```bash
# View widget extension logs
log stream --predicate 'subsystem == "com.growthlabs.growthmethod.widget"' --level debug

# Check for permission-related errors
log stream --predicate 'eventMessage CONTAINS "authorization"' --level debug

# Monitor Darwin notifications
log stream --predicate 'eventMessage CONTAINS "darwin"' --level debug
```

### Rollback Plan

If the permission dialog continues to cause issues:

1. **Disable App Intents temporarily**:
   - Comment out Button(intent:) in GrowthTimerWidgetLiveActivity.swift
   - Replace with static UI showing current state only

2. **Use push-only updates**:
   - Remove interactive buttons from Live Activity
   - Control timer only from main app
   - Live Activity becomes display-only

3. **Implement URL scheme approach**:
   - Buttons open app to perform actions
   - Less seamless but more reliable

### Related Apple Documentation
- [App Intents with Live Activities](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities#Add-Buttons-or-Toggles)
- [LiveActivityIntent Protocol](https://developer.apple.com/documentation/appintents/liveactivityintent)
- [Handling Permissions in App Intents](https://developer.apple.com/documentation/appintents/app-intents-authorization)

### Support Notes
- This is a known iOS limitation, not a bug in our implementation
- Apple may improve this behavior in future iOS versions
- Consider filing feedback with Apple if the UX is problematic