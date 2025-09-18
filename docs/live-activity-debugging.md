# Live Activity Progress Bar Debugging Guide

## Summary of Changes

1. **Replaced manual progress calculations with native `ProgressView(timerInterval:)`**
   - Dynamic Island progress bar (lines 189-193)
   - Lock Screen progress bar (lines 544-549)
   - This follows Apple's documentation: manual progress calculations don't work for Live Activities

2. **Enhanced debugging logs in LiveActivityManager**
   - Added notification permission checks
   - More detailed push token registration logs
   - Timestamp logging for token receipt

3. **Firebase Function already configured**
   - Updates every 0.1 seconds for smooth progress
   - Reads from nested `contentState` structure
   - Uses development APNs endpoint

## Testing Steps

### 1. Check Notification Permissions
```swift
// In AppDelegate or test view
let center = UNUserNotificationCenter.current()
let settings = await center.notificationSettings()
print("Auth status: \(settings.authorizationStatus.rawValue)")
// Should be 2 (authorized)
```

### 2. Verify Live Activity Support
- Go to Settings > Face ID & Passcode
- Scroll down to "Live Activities" 
- Ensure your app is listed and enabled

### 3. Test on Real Device
Live Activities with push updates require:
- Real device (not simulator)
- iOS 16.2 or later
- Proper provisioning profile with push entitlements

### 4. Monitor Console Logs

Look for these key logs when starting a timer:

```
🔵 LiveActivityManager: Requesting Live Activity with push token support
✅ LiveActivityManager: Live Activity created with push token support
🔔 LiveActivityManager: Starting push token registration
✅ Live Activity push token received: [token]
```

### 5. Check Firebase Function Logs
```bash
firebase functions:log --only manageLiveActivityUpdates
```

Look for:
- Push token storage confirmation
- Update frequency (should be every 0.1s)
- Any APNs errors

### 6. Common Issues

**Progress bar not updating:**
- Ensure you're testing on a real device
- Check that push token is received (see logs)
- Verify Firebase function is running (check logs)
- Confirm APNs configuration in Firebase

**Push token not received:**
- Check notification permissions
- Verify entitlements match (aps-environment)
- Ensure iOS 16.2+
- Try deleting and reinstalling app

**Widget not showing timer interval:**
- The `ProgressView(timerInterval:)` requires proper start/end times
- Check that `context.state.startTime` and `context.state.endTime` are valid
- For paused state, we show static progress (expected behavior)

## Architecture Overview

1. **iOS App** starts Live Activity with `pushType: .token`
2. **Push Token** is received via `pushTokenUpdates` 
3. **Token stored** in Firestore `liveActivityTokens` collection
4. **Firebase Function** reads token and timer state
5. **APNs Updates** sent every 0.1 seconds with progress
6. **Widget** uses `ProgressView(timerInterval:)` for smooth updates

## Key Code Locations

- Widget UI: `GrowthTimerWidget/GrowthTimerWidgetLiveActivity.swift`
- Live Activity Manager: `Growth/Features/Timer/Services/LiveActivityManager.swift`
- Firebase Function: `functions/manageLiveActivityUpdates.js`
- Entitlements: Both app and widget have `aps-environment: development`

## Next Steps if Still Not Working

1. **Deploy Latest Firebase Functions**
   ```bash
   firebase deploy --only functions:manageLiveActivityUpdates
   ```

2. **Test Push Token Receipt**
   Add this test code to verify tokens work:
   ```swift
   if #available(iOS 16.2, *) {
       for activity in Activity<TimerActivityAttributes>.activities {
           Task {
               for await token in activity.pushTokenUpdates {
                   print("GOT TOKEN: \(token.map { String(format: "%02x", $0) }.joined())")
               }
           }
       }
   }
   ```

3. **Check APNs Certificate**
   - Verify APNS_AUTH_KEY is set in Firebase environment
   - Ensure APNS_KEY_ID and APNS_TEAM_ID are correct
   - Test with development endpoint: `api.development.push.apple.com`

4. **Monitor Activity State**
   The `debugPrintCurrentState()` method in LiveActivityManager shows all active Live Activities and their states.