# FCM Live Activity Implementation Guide

## Overview
Firebase Cloud Messaging now officially supports Live Activities (November 2024). This approach bypasses direct APNs authentication issues by using Firebase's infrastructure.

## Benefits Over Direct APNs
1. No manual JWT token generation
2. Firebase handles APNs authentication
3. Simpler implementation
4. Better error handling and retry logic
5. Unified notification system

## Implementation Steps

### 1. Update Firebase Function for FCM

Create a new function `updateLiveActivityFCM.js`:

```javascript
const { onCall } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

// Initialize admin SDK if not already
if (!admin.apps.length) {
  admin.initializeApp();
}

exports.updateLiveActivityFCM = onCall(
  { 
    region: 'us-central1',
    consumeAppCheckToken: false
  },
  async (request) => {
    const { activityId, contentState, action } = request.data;
    
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Authentication required');
    }
    
    // Get the Live Activity token from Firestore
    const tokenDoc = await admin.firestore()
      .collection('liveActivityTokens')
      .doc(activityId)
      .get();
      
    if (!tokenDoc.exists) {
      throw new HttpsError('not-found', 'Live Activity token not found');
    }
    
    const tokenData = tokenDoc.data();
    
    // Construct FCM message for Live Activity
    const message = {
      token: tokenData.fcmToken, // FCM registration token
      apns: {
        headers: {
          'apns-push-type': 'liveactivity',
          'apns-priority': '10',
          'apns-topic': `${tokenData.bundleId}.push-type.liveactivity`
        },
        payload: {
          aps: {
            timestamp: Math.floor(Date.now() / 1000),
            event: action || 'update',
            'content-state': contentState,
            'live-activity-token': tokenData.pushToken // Apple's Live Activity token
          }
        }
      }
    };
    
    // Add dismissal date for stop action
    if (action === 'end') {
      message.apns.payload.aps['dismissal-date'] = Math.floor(Date.now() / 1000);
    }
    
    try {
      // Send via FCM
      const response = await admin.messaging().send(message);
      console.log('Successfully sent Live Activity update:', response);
      
      return { success: true, messageId: response };
    } catch (error) {
      console.error('Error sending Live Activity update:', error);
      throw new HttpsError('internal', `Failed to send update: ${error.message}`);
    }
  }
);
```

### 2. Update iOS App to Store FCM Token

In `LiveActivityManager.swift`, update the token storage:

```swift
// When starting Live Activity
private func storePushToken(_ token: Data, for activityId: String) {
    let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
    
    // Get FCM token
    Messaging.messaging().token { fcmToken, error in
        guard let fcmToken = fcmToken else {
            print("Error fetching FCM token: \(error?.localizedDescription ?? "Unknown")")
            return
        }
        
        let db = Firestore.firestore()
        let tokenData: [String: Any] = [
            "pushToken": tokenString,        // Apple's Live Activity token
            "fcmToken": fcmToken,           // FCM registration token
            "activityId": activityId,
            "userId": Auth.auth().currentUser?.uid ?? "",
            "bundleId": Bundle.main.bundleIdentifier ?? "",
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        db.collection("liveActivityTokens")
            .document(activityId)
            .setData(tokenData) { error in
                if let error = error {
                    print("Error storing tokens: \(error)")
                } else {
                    print("Tokens stored successfully")
                }
            }
    }
}
```

### 3. Deploy and Test

1. Deploy the new function:
   ```bash
   firebase deploy --only functions:updateLiveActivityFCM
   ```

2. Update your app to call the FCM function:
   ```swift
   functions.httpsCallable("updateLiveActivityFCM").call([
       "activityId": activityId,
       "contentState": contentState,
       "action": "update"
   ])
   ```

### 4. Testing with FCM API Explorer

Use the [FCM API Explorer](https://fcm.googleapis.com/$discovery/rest?version=v1) to test:

1. Get your FCM Server Key from Firebase Console
2. Use the `projects.messages.send` endpoint
3. Construct the message payload as shown above
4. Send test messages to verify functionality

## Key Differences from Direct APNs

1. **Authentication**: FCM uses server keys instead of JWT tokens
2. **Token Management**: Need both FCM token and Live Activity token
3. **Error Handling**: FCM provides better error messages
4. **Retry Logic**: FCM handles retries automatically

## Troubleshooting

### Common Issues:
1. **Missing FCM Token**: Ensure Firebase SDK is properly initialized
2. **Invalid Topic**: Use main app bundle ID, not widget bundle ID
3. **Token Mismatch**: Verify FCM token matches the device

### Debug Steps:
1. Check Firebase Console > Cloud Messaging for delivery status
2. Use FCM diagnostics to verify token validity
3. Monitor function logs for detailed error messages

## Migration Path

1. Keep existing direct APNs implementation
2. Add FCM implementation in parallel
3. Test thoroughly with subset of users
4. Gradually migrate all users to FCM
5. Remove direct APNs code once stable

## Advantages for Your Use Case

- Eliminates InvalidProviderToken errors
- No need to manage APNs keys
- Simpler deployment process
- Better integration with Firebase ecosystem
- Automatic handling of development/production environments

## Next Steps

1. Implement the FCM function
2. Update iOS app to store FCM tokens
3. Test with a single device
4. Monitor error rates
5. Roll out to all users if successful