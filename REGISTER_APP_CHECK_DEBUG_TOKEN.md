# Register App Check Debug Token

The app is failing with App Check authentication errors. You need to register the debug token in Firebase Console.

## Debug Token
`FAF05E3D-CBCB-4557-930F-100FF3BAC0E7`

## Steps to Register

1. Go to Firebase Console: https://console.firebase.google.com
2. Select your project: `growth-70a85`
3. Navigate to **App Check** in the left sidebar
4. Click on your iOS app (`com.growthlabs.growthmethod`)
5. Click on the **3 dots menu** (⋮) next to your app
6. Select **Manage debug tokens**
7. Click **Add debug token**
8. Paste: `FAF05E3D-CBCB-4557-930F-100FF3BAC0E7`
9. Give it a name like "Development Device" or your device name
10. Click **Add**

## Alternative: Programmatic Token Generation

If you want to generate a new token programmatically, the app already has debug provider setup:

```swift
// In AppCheckDebugHelper.swift
AppCheckDebugHelper.shared.refreshDebugToken()
```

This will generate a new token and print it to the console. You can then register that token in Firebase Console.

## Verify It's Working

After registering the token, you should see:
- No more 403 PERMISSION_DENIED errors
- Firebase functions working properly
- Live Activity push updates resuming

## Production Note

App Check debug tokens are only for development. In production, the app uses:
- DeviceCheck provider for real devices
- App Attest provider for iOS 14.0+