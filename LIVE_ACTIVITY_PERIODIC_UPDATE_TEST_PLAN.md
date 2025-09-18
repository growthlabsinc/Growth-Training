# Live Activity Periodic Update Test Plan

## Test Objective
Verify that the periodic update mechanism prevents the Live Activity from showing "OFFLINE" during normal timer operation.

## Background
- The Live Activity shows "OFFLINE" when `isDataStale` returns true (after 60 seconds without updates)
- We've implemented periodic updates every 30 seconds to refresh `lastKnownGoodUpdate`
- This should prevent the OFFLINE indicator from appearing during normal timer runs

## Test Steps

### 1. Build and Install
```bash
# Clean build
rm -rf ~/Library/Developer/Xcode/DerivedData/Growth-*

# Build and install on device/simulator
xcodebuild -project Growth.xcodeproj \
  -scheme Growth \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  build
```

### 2. Monitor Logs in Real-Time
Open a terminal and run:
```bash
./test_live_activity_updates.sh
```

This monitors for:
- Periodic update messages
- lastKnownGoodUpdate changes
- Any "stale" or "OFFLINE" indicators

### 3. Run the Test

1. **Start a Timer**
   - Launch the app
   - Start a countdown timer for 5 minutes
   - Note: The Live Activity should appear in Dynamic Island/Lock Screen

2. **Monitor for 2+ Minutes**
   - Let the timer run WITHOUT ANY INTERACTION
   - Watch the logs for periodic updates every 30 seconds
   - Look for: `"🔄 LiveActivityManager: Sending periodic update to prevent stale data"`

3. **Expected Log Pattern**
   ```
   [HH:MM:SS] 🔄 LiveActivityManager: Starting periodic updates every 30 seconds
   [HH:MM:SS] 🔄 LiveActivityManager: Sending periodic update to prevent stale data
   [HH:MM:SS] 🔵 LiveActivityManager: updateActivity called
   [HH:MM:SS] ✅ LiveActivityManager: Local update applied
   ... (repeats every 30 seconds)
   ```

4. **Visual Verification**
   - The Live Activity should show the timer counting down smoothly
   - No "OFFLINE" text should appear
   - No frozen/loading state should occur

### 4. Failure Scenarios to Check

1. **Lock Screen Test**
   - Start timer
   - Lock the device
   - Wait 90 seconds
   - Unlock and check if Live Activity is still updating

2. **Background Test**
   - Start timer
   - Switch to another app
   - Wait 2-3 minutes
   - Return to check Live Activity state

### 5. Success Criteria

✅ **PASS** if:
- Periodic update logs appear every 30 seconds
- No "OFFLINE" indicator appears during normal running
- Timer continues counting smoothly
- No frozen states occur

❌ **FAIL** if:
- "OFFLINE" appears on the Live Activity
- Periodic update logs stop appearing
- Live Activity shows frozen/loading state
- Widget logs show crashes or errors

## Debugging Commands

If issues occur, gather more information:

```bash
# Check for widget crashes
./debug_widget_crash.sh

# Monitor Live Activity states
./debug_live_activity.sh

# Check system logs for memory issues
log show --predicate 'processImagePath CONTAINS "GrowthTimerWidget"' --last 5m
```

## What to Report

If the test fails, please provide:
1. Screenshot of the frozen Live Activity
2. Console logs from the monitoring script
3. Time when the freeze occurred
4. What you were doing when it froze
5. Device/simulator details

## Next Steps

If periodic updates are working but freezing still occurs:
1. Check if widget extension is being terminated
2. Investigate push notification delivery
3. Look for memory pressure issues
4. Consider increasing update frequency