# Live Activity Fix Guide

## Issues Found and Fixed

### 1. **Incorrect APNS Topic**
- **Problem**: Using main app bundle ID instead of widget bundle ID
- **Fix**: Changed topic to `com.growth.GrowthTimerWidget.push-type.liveactivity`

### 2. **Missing Stale Date**
- **Problem**: Live Activities require a stale-date to know when updates are no longer relevant
- **Fix**: Added dynamic stale-date calculation based on timer type:
  - Countdown timers: Timer end time + 10 seconds
  - Countup/paused timers: 2 minutes from current time
  - Completed timers: 30 minutes from completion

### 3. **Relevance Score**
- **Problem**: All updates had same priority
- **Fix**: Added relevance score (0-100) based on timer state:
  - Running countdown timers: Higher score as they approach completion
  - Paused timers: 75
  - Running countup timers: 90
  - Completed timers: 50

### 4. **Content State Format**
- **Problem**: Timestamps not properly formatted
- **Fix**: Ensured all timestamps are ISO 8601 strings
- **Fix**: Added totalDuration field for countdown timers

### 5. **Completion Handling**
- **Problem**: Timer completion wasn't properly ending the Live Activity
- **Fix**: Added proper completion detection and sending 'end' event

## iOS App Requirements

Ensure your iOS app has these implementations:

### 1. **Push Token Storage**
```swift
// In TimerService.swift or LiveActivityManager
func startLiveActivity() async {
    let activity = try Activity.request(
        attributes: attributes,
        content: content,
        pushType: .token // This is critical!
    )
    
    // Listen for push token updates
    Task {
        for await pushToken in activity.pushTokenUpdates {
            await storePushToken(pushToken, activityId: activity.id)
        }
    }
}

func storePushToken(_ token: Data, activityId: String) async {
    let tokenString = token.map { String(format: "%02x", $0) }.joined()
    
    try await db.collection("liveActivityTokens")
        .document(activityId)
        .setData([
            "pushToken": tokenString,
            "userId": Auth.auth().currentUser?.uid ?? "",
            "activityId": activityId,
            "createdAt": FieldValue.serverTimestamp()
        ])
}
```

### 2. **Widget Content State Model**
```swift
// In your widget extension
struct TimerActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var startTime: String
        var endTime: String?
        var methodName: String
        var sessionType: String
        var isPaused: Bool
        var lastUpdateTime: String
        var elapsedTimeAtLastUpdate: Int
        var remainingTimeAtLastUpdate: Int
        var totalDuration: Int?
        var isCompleted: Bool?
        var completionMessage: String?
    }
    
    var timerType: String
}
```

### 3. **Starting Push Updates**
```swift
// When starting the timer
func startTimer() async {
    // Start the timer logic...
    
    // Start server-side push updates
    let functions = Functions.functions()
    do {
        let result = try await functions.httpsCallable("manageLiveActivityUpdates").call([
            "activityId": activity.id,
            "userId": userId,
            "action": "startPushUpdates",
            "pushToken": pushTokenString // Optional if already stored
        ])
        print("Push updates started: \(result.data)")
    } catch {
        print("Error starting push updates: \(error)")
    }
}
```

### 4. **Info.plist Configuration**
```xml
<key>NSSupportsLiveActivities</key>
<true/>
<key>NSSupportsLiveActivitiesFrequentUpdates</key>
<true/>
```

## Deployment Instructions

### Option 1: Individual Function Deployment (Recommended)
```bash
cd functions
./deploy-functions-individually.sh
```

### Option 2: Manual Deployment
```bash
# Deploy only the fixed Live Activity functions
firebase deploy --only functions:manageLiveActivityUpdates --force
firebase deploy --only functions:updateLiveActivityTimer --force
firebase deploy --only functions:onTimerStateChange --force
```

### Option 3: If deployment still stalls
1. Use Firebase Console to deploy
2. Or try with a different Firebase CLI version:
```bash
npm install -g firebase-tools@12.9.1
firebase deploy --only functions --force
```

## Testing the Fix

1. **Start a timer in the app**
2. **Check Firebase logs**:
   ```bash
   firebase functions:log --only manageLiveActivityUpdates
   ```
3. **Verify Live Activity updates**:
   - Should update every second
   - Should show correct remaining time
   - Should complete properly

## Troubleshooting

### "Invalid push token" error
- Ensure the iOS app is requesting push tokens with `.token` type
- Check that tokens are being stored in Firestore

### "Topic disallowed" error
- Verify widget bundle ID matches: `com.growth.GrowthTimerWidget`
- Check provisioning profiles include push notifications

### Updates not appearing
- Check device has internet connection
- Verify push notification permissions are granted
- Check Firebase logs for APNS errors

### Timer not completing
- Ensure countdown timers have proper `totalDuration` set
- Check that completion detection logic is working
- Verify `end` event is being sent

## Additional Notes

- Live Activities have a maximum duration of 12 hours
- Updates are rate-limited by iOS (frequent updates allowed with proper entitlement)
- Always test on real devices, not simulators
- Use development APNS for debug builds, production for release builds