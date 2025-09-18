# Firebase App Check Complete Fix Guide

## Current Issue
The app is receiving App Check errors because the new bundle ID `com.growthlabs.growthmethod` hasn't been registered in Firebase Console:
```
"App not registered: 1:645068839446:ios:c49ec579111e8a65fc3337."
```

## Step-by-Step Fix

### 1. Firebase Console Configuration

1. **Go to Firebase Console**
   - Navigate to https://console.firebase.google.com/project/growth-70a85
   - Go to Project Settings → General tab

2. **Add the iOS App**
   - Click "Add app" and select iOS
   - Enter bundle ID: `com.growthlabs.growthmethod`
   - App nickname: "Growth Method"
   - App Store ID: (leave empty for now)
   - Click "Register app"

3. **Download GoogleService-Info.plist**
   - After registering, download the new `GoogleService-Info.plist`
   - This file will have the correct app ID for the new bundle ID

4. **Configure App Check**
   - Go to App Check section in Firebase Console
   - Find the newly registered app
   - Click on it and configure providers:
     - **DeviceCheck**: Enable for production
     - **Debug**: Enable for development
   - Save the configuration

### 2. Update Project Configuration

Replace the GoogleService-Info.plist files:

```bash
# Backup current files
cp Growth/Resources/Plist/GoogleService-Info.plist Growth/Resources/Plist/GoogleService-Info.plist.backup
cp Growth/Resources/Plist/dev.GoogleService-Info.plist Growth/Resources/Plist/dev.GoogleService-Info.plist.backup

# Place the new downloaded file
# Copy the downloaded GoogleService-Info.plist to:
# Growth/Resources/Plist/GoogleService-Info.plist
```

### 3. Configure Debug Token (Development Only)

When running in debug mode, the app logs a debug token. This token needs to be added to Firebase Console:

1. Run the app in Xcode
2. Look for this log message:
   ```
   App Check debug token retrieved (add this to Firebase Console if needed): [TOKEN]
   ```
3. Copy the token
4. In Firebase Console:
   - Go to App Check → Apps → Your app → Manage debug tokens
   - Add the debug token
   - Give it a name like "Development Device"

### 4. Update Firebase Functions (if needed)

The Firebase Functions should already be configured correctly, but verify:

```javascript
// In functions/index.js or liveActivityUpdates.js
// Ensure App Check is properly validated:
const appCheckToken = request.headers['x-firebase-appcheck'];
if (!appCheckToken) {
  console.error('App Check token missing');
  response.status(401).send('Unauthorized');
  return;
}
```

### 5. Test the Fix

1. Clean and rebuild the app
2. Start a timer and check Xcode console for errors
3. Verify no App Check errors appear
4. Check that Live Activity push updates work

## Alternative: Temporary Workaround

If you need to test immediately without fixing App Check:

1. **Disable App Check enforcement temporarily** (NOT for production):
   - In Firebase Console → App Check
   - Click on "APIs" tab
   - Find your Cloud Functions API
   - Set enforcement to "Unenforced"
   - Remember to re-enable after testing!

## Verification Checklist

- [ ] New app registered in Firebase Console with bundle ID `com.growthlabs.growthmethod`
- [ ] App Check providers configured (DeviceCheck + Debug)
- [ ] New GoogleService-Info.plist downloaded and placed in project
- [ ] Debug token added to Firebase Console (for development)
- [ ] No more "App not registered" errors in console
- [ ] Live Activity push updates working
- [ ] Firebase Functions receiving valid App Check tokens

## Common Issues

1. **"Invalid app ID" error**
   - Ensure the GoogleService-Info.plist matches your bundle ID
   - Check that you're using the correct environment file

2. **"Missing App Check token" in Functions**
   - Ensure App Check is initialized in the app
   - Check that Functions are validating tokens properly

3. **Debug token not working**
   - Token changes between app installs
   - Add new token to Firebase Console when it changes