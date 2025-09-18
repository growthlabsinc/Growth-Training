# Live Activity Debugging Guide

## Issue: Live Activity Freezes When Paused

### Debugging Steps Added

1. **LiveActivityManager.swift** - Added comprehensive logging:
   - 🟢 DEBUG: General activity lifecycle events
   - 🟡 Pause/Resume state transitions with timestamp tracking
   - 🔵 Activity state monitoring (active, stale, ended)
   - ⚠️ Warnings when activity becomes stale

2. **LiveActivityUpdateManager.swift** (Widget Extension) - Added widget-side logging:
   - 🟣 WIDGET DEBUG: Widget-initiated pause/resume actions
   - Timestamp validation before/after updates
   - Stale state detection

3. **TimerControlIntent.swift** - Added intent action logging:
   - Button press events from Live Activity
   - Action routing to update managers

### Key Things to Monitor

1. **Activity State Transitions**
   ```
   Look for: "Activity state changed to: stale"
   This indicates the Live Activity has become stale and will freeze
   ```

2. **Timestamp Modifications**
   ```
   Look for: "timestamps should be UNCHANGED"
   Verify startTime and endTime remain constant during pause/resume
   ```

3. **Stale Date Configuration**
   ```
   Look for: "Stale date set to: ... (X hours from now)"
   Should be 8 hours in the future to prevent freezing
   ```

4. **Data Staleness Check**
   ```
   The widget considers data stale if lastKnownGoodUpdate > 60 seconds ago
   This triggers the "OFFLINE" indicator
   ```

### How to Run Debug Session

1. **Start the debug monitor**:
   ```bash
   ./debug_live_activity.sh
   ```

2. **Build and run on physical device** (Live Activities require real device):
   ```bash
   xcodebuild -project Growth.xcodeproj \
     -scheme Growth \
     -sdk iphoneos \
     -destination 'id=YOUR_DEVICE_ID' \
     run
   ```

3. **Test sequence**:
   - Start a timer
   - Wait for Live Activity to appear
   - Press pause button in Live Activity
   - Watch debug logs for state changes
   - Wait 10-30 seconds
   - Press resume button
   - Check if timer continues or freezes

### What to Look For in Logs

#### ✅ Good (Expected) Behavior:
```
🟡 DEBUG: PAUSING Activity
  - Before pause:
    - startTime: 2025-01-20 10:00:00
    - endTime: 2025-01-20 10:30:00
  - After pause (timestamps should be UNCHANGED):
    - startTime: 2025-01-20 10:00:00  ← Same
    - endTime: 2025-01-20 10:30:00    ← Same
```

#### ❌ Bad (Problematic) Behavior:
```
⚠️ WARNING: Activity became STALE!
🔵 DEBUG: Activity state changed to: stale
```

### Potential Causes of Freezing

1. **Stale Date Too Close**: If stale date is < 30 seconds from current time
2. **Activity State = Stale**: iOS stops updating stale activities
3. **Timestamp Adjustments**: Any modification to startTime/endTime confuses SwiftUI
4. **Push Token Issues**: Failed push updates after 30 seconds
5. **Memory Pressure**: Widget extension terminated by iOS

### Additional Debug Commands

**Check all Live Activities**:
```swift
// Add to TimerService
LiveActivityManager.shared.debugPrintCurrentState()
```

**Force refresh Live Activity**:
```swift
// In LiveActivityManager
await recoverFromStaleActivity(activity: currentActivity, updatedState: newState)
```

**Monitor widget extension lifecycle**:
```bash
log stream --predicate 'processImagePath CONTAINS "GrowthTimerWidget"' --style json
```

### Firebase Push Notification Debug

The logs show successful push notifications (HTTP 200), so the infrastructure is working.
Key fields in push payload:
- `event: "update"`
- `stale-date`: Must be far future
- `content-state`: Must match TimerActivityAttributes.ContentState exactly

### Next Steps if Issue Persists

1. Check if `isDataStale` computed property is triggering too early
2. Verify Darwin notifications are being received by the app
3. Test with different timer durations (short vs long)
4. Monitor memory usage in widget extension
5. Check if issue is specific to certain iOS versions