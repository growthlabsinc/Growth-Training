# Fix App Check Token Validation Error

## Error
```
Failed to validate AppCheck token. FirebaseAppCheckError: Decoding App Check token failed
```

## Root Cause
The debug token `4C4C2F26-8881-4144-9B48-6FD556A0CD3D` needs to be properly registered in Firebase Console.

## Solution Steps

### 1. Add Debug Token to Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/project/growth-70a85/appcheck/apps)
2. Select your iOS app
3. Click the **3 dots menu** → **Manage debug tokens**
4. Click **Add debug token**
5. Enter:
   - Token: `4C4C2F26-8881-4144-9B48-6FD556A0CD3D`
   - Name: `Development Device` (or any descriptive name)
6. Click **Save**

### 2. Verify App Check is Enabled for Cloud Functions

1. In Firebase Console, go to **App Check**
2. Click on **APIs** tab
3. Find **Cloud Functions** in the list
4. Ensure it's **Enabled** (toggle should be ON)
5. If not enabled, click the toggle to enable it

### 3. Update Your Cloud Functions (if needed)

Check if your functions are properly validating App Check tokens:

```javascript
// In your Cloud Functions
const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.yourFunction = functions.https.onCall(async (data, context) => {
    // App Check verification (optional - can be enforced or just logged)
    if (context.app == undefined) {
        // The request is missing an App Check token
        functions.logger.warn('Missing App Check token');
        // Decide whether to proceed or throw error
    }
    
    // Your function logic here
});
```

### 4. Test the Fix

1. **In Xcode:**
   - Clean Build Folder (⌘⇧K)
   - Ensure environment variable is set:
     - `FIRAppCheckDebugToken` = `4C4C2F26-8881-4144-9B48-6FD556A0CD3D`
   - Build and Run

2. **Check Console Logs:**
   - Look for: `APP CHECK DEBUG TOKEN (from environment): 4C4C2F26-8881-4144-9B48-6FD556A0CD3D`
   - This confirms the token is being used

3. **Test a Function Call:**
   - Try calling a Cloud Function from your app
   - Check Cloud Functions logs - the error should be gone

## Alternative: Disable App Check for Development

If you need to temporarily bypass App Check during development:

1. In your Cloud Functions, make App Check optional:
```javascript
exports.yourFunction = functions.https.onCall(async (data, context) => {
    // Only warn about missing App Check, don't block
    if (!context.app) {
        functions.logger.warn('App Check token missing - allowing in dev');
    }
    
    // Continue with function logic
    return { success: true };
});
```

## Important Notes

- Each developer needs their own debug token
- Debug tokens only work in DEBUG builds
- Production builds use Device Check (real device attestation)
- The token in environment variable must match the one in Firebase Console exactly