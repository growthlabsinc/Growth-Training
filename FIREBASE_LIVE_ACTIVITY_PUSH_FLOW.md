# Firebase Live Activity Push Update Flow

## Overview
This document details how Firebase Cloud Functions send push notifications to update Live Activities, following Apple's official ActivityKit push notification approach.

## Architecture

```
User Action → Timer State Change → LiveActivityManager → Firebase Function → APNs → Live Activity Update
```

## Key Components

### 1. Client Side (iOS App)

#### LiveActivityManager.swift
```swift
// Sends push token to Firebase when Live Activity starts
private func registerPushToken(_ token: Data, for activityId: String) async {
    let tokenString = token.map { String(format: "%02x", $0) }.joined()
    
    // Call Firebase Function to register token
    let functions = Functions.functions()
    let callable = functions.httpsCallable("registerLiveActivityToken")
    
    try await callable.call([
        "activityId": activityId,
        "pushToken": tokenString,
        "userId": Auth.auth().currentUser?.uid ?? ""
    ])
}
```

### 2. Server Side (Firebase Functions)

#### functions/src/liveActivity/updateLiveActivity.ts
```typescript
export const updateLiveActivity = functions.https.onCall(async (data, context) => {
    const { activityId, contentState } = data;
    
    // Get push token from Firestore
    const tokenDoc = await admin.firestore()
        .collection('liveActivityTokens')
        .doc(activityId)
        .get();
    
    if (!tokenDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Push token not found');
    }
    
    const { pushToken } = tokenDoc.data();
    
    // Send push via APNs
    const message = {
        token: pushToken,
        apns: {
            headers: {
                'apns-push-type': 'liveactivity',
                'apns-topic': 'com.growthlabs.growthmethod.push-type.liveactivity',
                'apns-priority': '10',
                'apns-relevance-score': 100
            },
            payload: {
                aps: {
                    'timestamp': Date.now() / 1000,
                    'event': 'update',
                    'content-state': contentState,
                    'alert': {
                        'title': 'Timer Update',
                        'body': 'Your timer has been updated'
                    }
                }
            }
        }
    };
    
    return await admin.messaging().send(message);
});
```

## Push Update Triggers

### 1. Timer Pause
```swift
// LiveActivityManager.swift
@MainActor
func pauseTimer() async {
    guard let activity = currentActivity else { return }
    
    let contentState = TimerActivityAttributes.ContentState(
        startedAt: startTime,
        pausedAt: Date(),  // Mark as paused
        targetDuration: targetDuration,
        methodName: methodName
    )
    
    // Send push update via Firebase
    await sendPushUpdate(activityId: activity.id, contentState: contentState)
}
```

### 2. Timer Resume
```swift
@MainActor
func resumeTimer() async {
    guard let activity = currentActivity else { return }
    
    // Calculate adjusted start time
    let pauseDuration = Date().timeIntervalSince(pausedAt)
    let adjustedStartTime = startTime.addingTimeInterval(pauseDuration)
    
    let contentState = TimerActivityAttributes.ContentState(
        startedAt: adjustedStartTime,
        pausedAt: nil,  // Clear pause state
        targetDuration: targetDuration,
        methodName: methodName
    )
    
    await sendPushUpdate(activityId: activity.id, contentState: contentState)
}
```

### 3. Timer Stop/Complete
```swift
@MainActor
func stopTimer() async {
    guard let activity = currentActivity else { return }
    
    // Send end event
    let message = {
        apns: {
            headers: {
                'apns-push-type': 'liveactivity',
                'apns-topic': 'com.growthlabs.growthmethod.push-type.liveactivity'
            },
            payload: {
                aps: {
                    'event': 'end',
                    'dismissal-date': Date.now() + 2  // Dismiss after 2 seconds
                }
            }
        }
    };
    
    await sendPushEnd(activityId: activity.id)
}
```

## Content State Structure

### TimerActivityAttributes.ContentState
```swift
public struct ContentState: Codable, Hashable {
    public let startedAt: Date      // When timer started (adjusted for pauses)
    public let pausedAt: Date?      // When paused (nil if running)
    public let targetDuration: TimeInterval  // Total duration for countdown
    public let methodName: String   // Display name
    
    // Computed property for current state
    public var isPaused: Bool {
        return pausedAt != nil
    }
    
    // Elapsed time calculation
    public var elapsedTime: TimeInterval {
        let referenceDate = pausedAt ?? Date()
        return referenceDate.timeIntervalSince(startedAt)
    }
}
```

## Firebase Function Endpoints

### 1. registerLiveActivityToken
- **Purpose**: Store APNs push token for Live Activity
- **Called**: When Live Activity starts
- **Parameters**:
  - `activityId`: Unique Live Activity identifier
  - `pushToken`: APNs push token (hex string)
  - `userId`: Firebase Auth user ID

### 2. updateLiveActivity
- **Purpose**: Send content update to Live Activity
- **Called**: On timer state changes (pause/resume)
- **Parameters**:
  - `activityId`: Live Activity to update
  - `contentState`: New state data

### 3. endLiveActivity
- **Purpose**: End and dismiss Live Activity
- **Called**: When timer stops or completes
- **Parameters**:
  - `activityId`: Live Activity to end
  - `dismissalDate`: When to remove from screen

## APNs Configuration

### Required Headers
```javascript
{
    'apns-push-type': 'liveactivity',  // Required for Live Activities
    'apns-topic': 'com.growthlabs.growthmethod.push-type.liveactivity',  // Bundle ID + .push-type.liveactivity
    'apns-priority': '10',  // High priority for immediate delivery
    'apns-relevance-score': 100  // Importance for Smart Stack
}
```

### Payload Structure
```javascript
{
    aps: {
        'timestamp': Date.now() / 1000,  // Unix timestamp
        'event': 'update',  // or 'end'
        'content-state': {
            // Matches ContentState structure
            startedAt: '2024-01-15T10:30:00Z',
            pausedAt: null,
            targetDuration: 300,
            methodName: 'Training Session'
        },
        'stale-date': staleDate,  // Optional: When content becomes stale
        'dismissal-date': dismissalDate  // For 'end' event
    }
}
```

## Error Handling

### Common Errors

#### 1. Invalid Push Token
```typescript
if (!isValidAPNsToken(pushToken)) {
    throw new functions.https.HttpsError(
        'invalid-argument',
        'Invalid APNs push token format'
    );
}
```

#### 2. Token Not Found
```typescript
const tokenDoc = await getTokenDocument(activityId);
if (!tokenDoc.exists) {
    // Activity may have ended, log and return
    console.log(`No token found for activity ${activityId}`);
    return { success: false, reason: 'token_not_found' };
}
```

#### 3. APNs Errors
```typescript
try {
    await admin.messaging().send(message);
} catch (error) {
    if (error.code === 'messaging/invalid-registration-token') {
        // Token expired or invalid, clean up
        await deleteTokenDocument(activityId);
    }
    throw error;
}
```

## Security Considerations

### 1. Authentication
```typescript
// Verify user owns the Live Activity
const activityDoc = await admin.firestore()
    .collection('liveActivities')
    .doc(activityId)
    .get();

if (activityDoc.data()?.userId !== context.auth?.uid) {
    throw new functions.https.HttpsError(
        'permission-denied',
        'User does not own this Live Activity'
    );
}
```

### 2. Rate Limiting
```typescript
// Prevent spam updates
const lastUpdate = await getLastUpdateTime(activityId);
if (Date.now() - lastUpdate < 1000) {  // 1 second minimum
    throw new functions.https.HttpsError(
        'resource-exhausted',
        'Too many updates, please wait'
    );
}
```

### 3. Token Encryption
- Store tokens encrypted in Firestore
- Use Firebase Security Rules to restrict access
- Rotate encryption keys periodically

## Testing Push Updates

### Manual Test Script
```javascript
// functions/test-push-update.js
const admin = require('firebase-admin');
admin.initializeApp();

async function testPushUpdate() {
    const activityId = 'test-activity-123';
    const pushToken = 'YOUR_APNS_TOKEN';
    
    // Simulate pause
    await sendUpdate(activityId, pushToken, {
        startedAt: new Date().toISOString(),
        pausedAt: new Date().toISOString(),
        targetDuration: 300,
        methodName: 'Test Timer'
    });
    
    // Wait 3 seconds
    await new Promise(resolve => setTimeout(resolve, 3000));
    
    // Simulate resume
    const pauseDuration = 3;
    const adjustedStart = new Date(Date.now() - pauseDuration * 1000);
    await sendUpdate(activityId, pushToken, {
        startedAt: adjustedStart.toISOString(),
        pausedAt: null,
        targetDuration: 300,
        methodName: 'Test Timer'
    });
}
```

## Monitoring

### Firebase Console
- Monitor function execution logs
- Track push notification delivery rates
- View error rates and latency

### Client-Side Logging
```swift
// Log push token registration
Logger.liveActivity.info("📤 Registered push token: \(tokenString.prefix(10))...")

// Log content updates
Logger.liveActivity.info("📥 Received push update for activity: \(activityId)")
```

## Best Practices

1. **Minimize Payload Size**: Keep content-state under 4KB
2. **Batch Updates**: Avoid sending multiple updates within 1 second
3. **Handle Failures Gracefully**: Fall back to local updates if push fails
4. **Clean Up Tokens**: Remove tokens when Live Activity ends
5. **Use Relevance Scores**: Set appropriate scores for Smart Stack ranking
6. **Test on Real Devices**: Live Activities don't work fully in simulator

## Deployment Checklist

- [ ] APNs authentication key uploaded to Firebase Console
- [ ] Firebase Functions deployed with correct environment variables
- [ ] Firestore security rules configured for token storage
- [ ] Error handling and logging in place
- [ ] Rate limiting configured
- [ ] Push token cleanup job scheduled
- [ ] Monitoring dashboards set up
- [ ] Testing completed on physical devices

This implementation provides reliable, server-authoritative updates to Live Activities while following Apple's recommended patterns and best practices.