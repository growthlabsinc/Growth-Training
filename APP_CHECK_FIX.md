# App Check Warning Fix

## Current Issue
Firebase functions are showing App Check token validation warnings:
```
Failed to validate AppCheck token. FirebaseAppCheckError: Decoding App Check token failed.
```

## Root Cause
1. iOS app is configured with App Check using DebugAppCheckFactory for development
2. The debug tokens are not registered in Firebase Console
3. Functions have `consumeAppCheckToken: false` which allows them to run but shows warnings

## Solution Options

### Option 1: Register Debug Tokens (Recommended for Development)
1. Run the app in simulator/debug mode
2. Look for the debug token in Xcode console:
   ```
   🔑 Debug Token: [YOUR-DEBUG-TOKEN-HERE]
   ```
3. Add to Firebase Console:
   - Go to: https://console.firebase.google.com/project/growth-70a85/appcheck/apps
   - Select iOS app
   - Click "Manage debug tokens"
   - Add the token with a descriptive name (e.g., "Developer Simulator")

### Option 2: Disable App Check Warnings in Functions
Since we already have `consumeAppCheckToken: false`, we can suppress the warnings by:

1. Setting enforcement mode to "unenforced" explicitly
2. Catching and ignoring App Check errors

### Option 3: Implement Proper App Check Token Handling
For production, ensure:
1. Device Check provider is used (already configured)
2. App Check is enforced in Firebase Console
3. Functions validate tokens properly

## Immediate Fix

To suppress the warnings while keeping security flexible, update function configurations:

```javascript
// In each onCall function configuration
{
    region: 'us-central1',
    consumeAppCheckToken: false,
    // Add this to suppress warnings
    enforceAppCheck: false
}
```

## Testing App Check

Use the AppCheckDebugHelper in the iOS app:
```swift
// In a debug menu or test button
AppCheckDebugHelper.shared.refreshDebugToken()
```

This will output the debug token to register in Firebase Console.