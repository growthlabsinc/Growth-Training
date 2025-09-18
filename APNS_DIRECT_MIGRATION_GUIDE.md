# Migration Guide: Firebase to Direct APNs for Live Activities

## Overview
This guide explains how to migrate from Firebase Cloud Functions to direct APNs for Live Activity updates. This simplifies the architecture and removes the Firebase dependency for Live Activities.

## Benefits of Direct APNs

1. **Simpler Architecture**: No Firebase intermediary layer
2. **Lower Latency**: Direct connection to Apple's servers
3. **Reduced Dependencies**: No Firebase SDK needed for Live Activities
4. **Better Control**: Direct management of push tokens and payloads
5. **Cost Savings**: No Firebase function invocations

## Architecture Comparison

### Before (Firebase):
```
iOS App → Firebase Functions → APNs → Device
```

### After (Direct APNs):
```
iOS App → Your Server → APNs → Device
```

## Setup Instructions

### 1. Start the APNs Server

```bash
cd apns-server
npm install
cp .env.example .env
# Edit .env with your configuration
npm start
```

### 2. Configure iOS App

The app has been updated with:
- `APNsService.swift` - Direct APNs client service
- Modified `LiveActivityManager.swift` - Uses APNsService instead of Firebase

### 3. Key Files Created

#### Server Side:
- `/apns-server/server.js` - Express server for APNs
- `/apns-server/package.json` - Node.js dependencies
- `/apns-server/.env.example` - Configuration template

#### iOS Side:
- `/Growth/Core/Services/APNsService.swift` - APNs client service

## API Endpoints

### Register Push Token
```
POST /register-token
{
  "token": "abc123...",
  "activityId": "activity-id",
  "userId": "user-id" (optional)
}
```

### Update Activity
```
POST /update-activity
{
  "activityId": "activity-id",
  "action": "pause|resume|stop|update",
  "contentState": {
    "startedAt": "2025-09-11T10:00:00Z",
    "pausedAt": null,
    "duration": 1800,
    "methodName": "Training",
    "sessionType": "countdown"
  }
}
```

### Start Activity (iOS 17.2+)
```
POST /start-activity
{
  "pushToStartToken": "xyz789...",
  "attributes": {...},
  "contentState": {...}
}
```

## Migration Steps

### Step 1: Update LiveActivityManager

Replace Firebase calls with APNsService:

```swift
// Before (Firebase):
_ = try await functions.httpsCallable("registerLiveActivityPushToken").call(data)

// After (Direct APNs):
try await APNsService.shared.registerPushToken(token, activityId: activityId)
```

### Step 2: Update Push Token Registration

```swift
// In observePushTokenUpdates()
do {
    try await APNsService.shared.registerPushToken(
        tokenString,
        activityId: activity.id,
        userId: nil
    )
} catch {
    Logger.error("Failed to register push token: \(error)")
}
```

### Step 3: Update Activity Controls

```swift
// Pause/Resume/Stop actions now use APNsService
try await APNsService.shared.updateActivity(
    activityId: activity.id,
    action: .pause,
    contentState: contentStateDict
)
```

## Testing

### Local Testing
1. Start the APNs server locally:
   ```bash
   cd apns-server
   npm run dev
   ```

2. Update `APNsService.swift` to use localhost:
   ```swift
   private var serverURL: String {
       #if DEBUG
       return "http://localhost:3000"
       #else
       return "https://your-production-server.com"
       #endif
   }
   ```

3. Run the app and test Live Activity updates

### Production Deployment

1. Deploy the Node.js server to your hosting provider (Heroku, AWS, etc.)
2. Update the production URL in `APNsService.swift`
3. Ensure the APNs key file is securely stored on the server
4. Use environment variables for sensitive configuration

## Troubleshooting

### Common Issues

1. **"Invalid token" error from APNs**
   - Ensure you're using the correct environment (development vs production)
   - Verify the token format is correct

2. **Live Activity not updating**
   - Check server logs for APNs responses
   - Verify the content-state payload matches your Swift model
   - Ensure timestamps are current

3. **Authentication failures**
   - Verify the .p8 key file is correctly loaded
   - Check Team ID and Key ID match your Apple Developer account

## Security Considerations

1. **Never commit the .p8 key file to version control**
2. **Use HTTPS in production**
3. **Implement rate limiting on the server**
4. **Validate input on the server side**
5. **Consider adding authentication to the API endpoints**

## Rollback Plan

If you need to rollback to Firebase:
1. Uncomment the Firebase import in `LiveActivityManager.swift`
2. Revert the token registration to use Firebase functions
3. Redeploy Firebase functions

## Next Steps

1. **Add Database**: Store push tokens persistently (PostgreSQL, MongoDB, etc.)
2. **Add Authentication**: Secure the API endpoints
3. **Add Monitoring**: Track APNs success/failure rates
4. **Implement Retry Logic**: Handle temporary APNs failures
5. **Add WebSocket Support**: For real-time updates without polling

## Resources

- [Apple: ActivityKit Push Notifications](https://developer.apple.com/documentation/activitykit/starting-and-updating-live-activities-with-activitykit-push-notifications)
- [Apple: Sending Push Notifications](https://developer.apple.com/documentation/usernotifications/sending-push-notifications-using-command-line-tools)
- [JWT for APNs](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_token-based_connection_to_apns)