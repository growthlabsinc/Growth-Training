# Cloud Functions App Check Setup

## Current Issue
Your Cloud Functions are receiving invalid App Check tokens because:
1. The debug token needs to be registered in Firebase Console
2. Cloud Functions need proper App Check validation

## Step 1: Register Debug Token in Firebase Console

1. Go to [Firebase Console > App Check](https://console.firebase.google.com/project/growth-70a85/appcheck)
2. Click on your **iOS app**
3. Click the **menu (3 dots)** → **Manage debug tokens**
4. Click **Add debug token**
5. Add:
   - Token: `4C4C2F26-8881-4144-9B48-6FD556A0CD3D`
   - Name: `iOS Development`
6. Click **Done**

## Step 2: Enable App Check for Cloud Functions

1. In App Check section, click **APIs** tab
2. Find **Cloud Functions** 
3. Ensure it's **Enabled** (toggle ON)

## Step 3: Update Cloud Functions Code

### Option A: Enforce App Check (Recommended for Production)

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

exports.yourFunction = functions.https.onCall(async (data, context) => {
    // Verify App Check token
    if (context.app == undefined) {
        throw new functions.https.HttpsError(
            'failed-precondition',
            'The function must be called from an App Check verified app.'
        );
    }
    
    // Your function logic here
    return { success: true };
});
```

### Option B: Optional App Check (For Development)

```javascript
exports.yourFunction = functions.https.onCall(async (data, context) => {
    // Log App Check status but don't block
    if (!context.app) {
        console.warn('Unverified request - App Check token missing or invalid');
        // In production, you might want to limit functionality
    } else {
        console.log('Verified request from app:', context.app.appId);
    }
    
    // Your function logic here
    return { success: true };
});
```

### Option C: App Check with Replay Protection

```javascript
exports.yourFunction = functions.https.onCall(async (data, context) => {
    // Verify App Check token is present
    if (!context.app) {
        throw new functions.https.HttpsError(
            'unauthenticated', 
            'Missing App Check token'
        );
    }
    
    // Additional replay protection can be added here
    // For example, checking token freshness
    
    // Your function logic
    return { success: true };
});
```

## Step 4: Update Your iOS App

Your app is already configured correctly with:
- Debug token in environment variable
- App Check provider set before Firebase initialization
- Token auto-refresh enabled

## Step 5: Test

1. **Clean build** in Xcode (⌘⇧K)
2. **Run** the app
3. **Check logs** for: `APP CHECK DEBUG TOKEN (from environment): 4C4C2F26-8881-4144-9B48-6FD556A0CD3D`
4. **Call a Cloud Function** from your app
5. **Check Cloud Function logs** - should no longer show App Check errors

## Production Considerations

1. **App Attest** (iOS 14+) provides strongest security
2. **DeviceCheck** is fallback for older iOS versions
3. **Token refresh** is automatic with `isTokenAutoRefreshEnabled = true`
4. **Monitor** App Check metrics in Firebase Console

## Debugging Tips

- Use `gcloud functions logs read` to see function logs
- Check App Check metrics in Firebase Console
- Ensure bundle ID matches between app and Firebase project
- Debug tokens only work in DEBUG builds