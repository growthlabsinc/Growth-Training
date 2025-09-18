# ActivityKit Push Notifications Implementation

## Overview
This implementation enables Live Activity updates via push notifications in both development and production environments, eliminating the need for fallback methods and ensuring consistent behavior across all deployment scenarios.

## Architecture

### Key Components

1. **LiveActivityManager** (`Growth/Features/Timer/Services/LiveActivityManager.swift`)
   - Requests push tokens when starting Live Activities
   - Observes push token updates and syncs with Firebase
   - Handles widget action requests via Darwin notifications
   - Sends push updates through Firebase Functions

2. **TimerControlIntent** (`GrowthTimerWidget/TimerControlIntent.swift`)
   - Simplified to only update shared state and notify main app
   - No longer attempts direct Live Activity updates
   - Works consistently in both development and production

3. **Firebase Functions** (`functions/liveActivityUpdates.js`)
   - Handles APNs authentication with JWT tokens
   - Sends ActivityKit push notifications
   - Supports both development and production environments
   - Implements retry logic and error handling

## Implementation Flow

### Starting a Live Activity with Push Support

1. **Request Push Token**
   ```swift
   // In LiveActivityManager.startActivity()
   activity = try Activity<TimerActivityAttributes>.request(
       attributes: attributes,
       content: .init(state: initialState, staleDate: Date().addingTimeInterval(28800)),
       pushType: .token // Request push token for updates
   )
   ```

2. **Observe Push Token Updates**
   ```swift
   Task {
       await self.observePushTokenUpdates(for: activity)
   }
   ```

3. **Sync Token with Firebase**
   ```swift
   private func syncPushTokenWithFirebase(token: String, activityId: String) async {
       let data: [String: Any] = [
           "token": token,
           "activityId": activityId,
           "platform": "ios",
           "environment": getCurrentAPNSEnvironment()
       ]
       _ = try await functions.httpsCallable("registerLiveActivityPushToken").call(data)
   }
   ```

### Handling Widget Actions

1. **Widget Button Press**
   - User taps pause/resume/stop button in Dynamic Island or Lock Screen
   - TimerControlIntent.perform() is called

2. **Update Shared State**
   ```swift
   func perform() async throws -> some IntentResult {
       updateSharedState() // Store action in UserDefaults
       notifyMainApp()     // Send Darwin notification
       return .result()
   }
   ```

3. **Main App Receives Notification**
   ```swift
   // Darwin notification observer in LiveActivityManager
   if name.rawValue == "com.growthlabs.growthmethod.liveactivity.push.update" {
       Task {
           await LiveActivityManager.shared.handlePushUpdateRequest()
       }
   }
   ```

4. **Send Push Update via Firebase**
   ```swift
   private func sendPushUpdate(for activity: Activity<TimerActivityAttributes>, 
                              with state: TimerActivityAttributes.ContentState, 
                              action: String) async {
       let data: [String: Any] = [
           "activityId": activity.id,
           "contentState": contentStateData,
           "action": action,
           "pushToken": currentPushToken
       ]
       _ = try await functions.httpsCallable("updateLiveActivity").call(data)
   }
   ```

## APNs Configuration

### Required Secrets in Firebase Functions

```bash
# Development/Sandbox
APNS_AUTH_KEY      # P8 private key for APNs
APNS_KEY_ID        # Key ID from Apple Developer
APNS_TEAM_ID       # Team ID from Apple Developer
APNS_TOPIC         # Bundle ID with .push-type.liveactivity suffix

# Production (Optional - for dual-key strategy)
APNS_AUTH_KEY_PROD # Production P8 private key
APNS_KEY_ID_PROD   # Production Key ID
```

### APNs Payload Format

```javascript
{
    "aps": {
        "timestamp": 1234567890,
        "event": "update",
        "content-state": {
            "startedAt": "2024-01-01T12:00:00Z",
            "pausedAt": "2024-01-01T12:05:00Z", // Optional
            "duration": 1800,
            "methodName": "Workout",
            "sessionType": "countup",
            "isPaused": true
        },
        "stale-date": 1234567890,
        "relevance-score": 100
    }
}
```

## Environment Detection

The implementation automatically detects the current environment:

```swift
private func getCurrentAPNSEnvironment() -> String {
    #if DEBUG
    return "development"
    #else
    if Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt" {
        return "sandbox"  // TestFlight
    } else {
        return "production"  // App Store
    }
    #endif
}
```

## Push-to-Start Support (iOS 17.2+)

For future implementation of push-to-start functionality:

```swift
@available(iOS 17.2, *)
private func observePushToStartTokenUpdates() {
    Task {
        for await pushToken in Activity<TimerActivityAttributes>.pushToStartTokenUpdates {
            let tokenString = pushToken.reduce("") { $0 + String(format: "%02x", $1) }
            await self.syncPushToStartTokenWithFirebase(token: tokenString)
        }
    }
}
```

## Key Differences from Fallback Approach

### Old Approach (Fallback Method)
- Widget attempted direct Live Activity updates
- Failed in production due to sandboxing
- Required complex fallback logic
- Inconsistent behavior between environments

### New Approach (Push Notifications)
- Widget only updates shared state and notifies main app
- Main app always uses push notifications for updates
- Consistent behavior in all environments
- No fallback logic needed

## Testing

### Development Testing
1. Build with development scheme
2. Run on physical device (Live Activities don't work in simulator)
3. Start timer and test pause/resume/stop from Dynamic Island
4. Check console logs for push token registration and update flow

### TestFlight Testing
1. Archive with production scheme
2. Upload to TestFlight
3. Ensure APNs production credentials are configured
4. Test Live Activity updates work without fallback

### Verification Points
- Push token is received and logged: `"📱 New Live Activity push token received"`
- Token syncs with Firebase: `"✅ Push token synced with Firebase"`
- Darwin notifications are received: `"🔔 LiveActivityManager: Received Darwin notification"`
- Push updates are sent: `"✅ Push update sent successfully"`

## Troubleshooting

### Common Issues

1. **Push token not received**
   - Ensure `pushType: .token` is set when requesting Live Activity
   - Check Live Activities are enabled in Settings
   - Verify push notification entitlements

2. **Updates not working in TestFlight**
   - Verify production APNs credentials are configured
   - Check Firebase Functions have production secrets
   - Ensure correct environment detection

3. **Darwin notifications not received**
   - Check app group configuration
   - Verify notification names match between sender and receiver
   - Ensure main app is running (at least in background)

### Debug Logging

Enable verbose logging to troubleshoot issues:

```swift
Logger.verbose("Push token: \(tokenString)", logger: AppLoggers.liveActivity)
Logger.debug("Environment: \(getCurrentAPNSEnvironment())", logger: AppLoggers.liveActivity)
Logger.info("Sending push update for action: \(action)", logger: AppLoggers.liveActivity)
```

## Security Considerations

1. **Token Management**
   - Push tokens are activity-specific
   - Tokens are invalidated when Live Activity ends
   - Tokens may change during activity lifetime

2. **Authentication**
   - Firebase Functions require authenticated users
   - APNs uses JWT authentication with P8 keys
   - Separate keys for development and production

3. **Data Validation**
   - Content state size limited to 4KB
   - Validate all data before sending push notifications
   - Handle errors gracefully with local fallback

## Future Enhancements

1. **Push-to-Start** (iOS 17.2+)
   - Start Live Activities remotely
   - Schedule Live Activities for future events
   - Requires additional token management

2. **Batch Updates**
   - Update multiple Live Activities simultaneously
   - Optimize for frequent updates (e.g., sports scores)

3. **Analytics**
   - Track push notification delivery rates
   - Monitor Live Activity engagement
   - Measure update latency

## Conclusion

This implementation provides a robust, production-ready solution for Live Activity updates using ActivityKit push notifications. By leveraging Firebase Functions and APNs, the system works consistently across all deployment environments without requiring fallback methods or workarounds.