# App Check Debug Token Setup

## Current Issue
App Check is now configured with DeviceCheck but failing with "App attestation failed" because you're running from Xcode.

## Solution: Add Debug Token

### 1. Get the Debug Token from Xcode Console

Look for a log message in your Xcode console that looks like:
```
Firebase App Check debug token: YOUR-DEBUG-TOKEN-HERE
```

If you don't see it:

1. In Xcode, edit your scheme:
   - Product → Scheme → Edit Scheme
   - Select "Run" on the left
   - Go to "Arguments" tab
   - Add `-FIRDebugEnabled` to "Arguments Passed On Launch"
   - Click "Close"

2. Clean and rebuild:
   - Product → Clean Build Folder (⇧⌘K)
   - Product → Run (⌘R)

3. Look in the console for:
   ```
   Firebase App Check debug token: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
   ```

### 2. Add Token to Firebase Console

1. Go to: https://console.firebase.google.com/project/growth-70a85/appcheck/apps
2. Click on your iOS app
3. Click the three dots menu (⋮) → "Manage debug tokens"
4. Click "Add debug token"
5. Enter:
   - Name: "Xcode Development" (or any descriptive name)
   - Value: The debug token from the console
6. Click "Done"

### 3. Restart the App

After adding the debug token, restart your app from Xcode. App Check should now work properly.

## Alternative: Use Debug Provider in Code

If you want to use the debug provider programmatically (for development only), you can modify your App Check setup:

```swift
#if DEBUG
let providerFactory = AppCheckDebugProviderFactory()
#else
let providerFactory = DeviceCheckProviderFactory()
#endif

AppCheck.setAppCheckProviderFactory(providerFactory)
```

## Important Notes

- Debug tokens are only for development
- Each device/simulator needs its own debug token
- Production apps will use DeviceCheck automatically
- TestFlight builds use the production DeviceCheck provider