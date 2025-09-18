# Complete App Check Setup Guide

## Quick Fix for App Check Warnings

The App Check warnings in Firebase logs are happening because debug tokens aren't registered. Here's how to fix it:

### Step 1: Get Your Debug Token

Add this temporary code to your iOS app (e.g., in `GrowthAppApp.swift` after Firebase initialization):

```swift
// Add this temporarily to get debug token
#if DEBUG
DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
    AppCheckDebugHelper.shared.refreshDebugToken()
}
#endif
```

Or add a debug button in your Settings:

```swift
#if DEBUG
Button("Get App Check Token") {
    AppCheckDebugHelper.shared.refreshDebugToken()
}
.foregroundColor(.orange)
#endif
```

### Step 2: Run the App

1. Run the app in Simulator or on a device in Debug mode
2. Look in Xcode console for output like:

```
✅ App Check debug token refreshed successfully
========================================
🔑 Debug Token:
DCE45C4B-XXXX-XXXX-XXXX-XXXXXXXXXXXX
========================================
```

### Step 3: Add Token to Firebase Console

1. Copy the debug token from the console
2. Go to: https://console.firebase.google.com/project/growth-70a85/appcheck/apps
3. Click on your iOS app (com.growthlabs.growthmethod)
4. Click "Manage debug tokens"
5. Click "Add debug token"
6. Paste your token and give it a name:
   - "iOS Simulator - MacBook Pro"
   - "Developer iPhone"
   - "TestFlight Beta"

### Step 4: Verify It's Working

After adding the token:
1. Restart your app
2. Check Firebase function logs
3. The "Failed to validate AppCheck token" warnings should be gone

## Understanding App Check

### What is App Check?
- Protects your Firebase resources from abuse
- Ensures only your authentic app can call Firebase services
- Uses device attestation (DeviceCheck on iOS)

### Current Configuration
Your app is correctly configured with:
- DebugAppCheckFactory for development (simulator/debug builds)
- DeviceCheckAppCheckFactory for production
- Auto token refresh enabled

### Why the Warnings?
- In development, App Check uses debug tokens
- Each device/simulator generates a unique token
- These tokens must be manually registered in Firebase Console
- Functions with `consumeAppCheckToken: false` still try to validate but don't enforce

## Production Considerations

### For TestFlight/App Store:
1. App Check will use DeviceCheck (automatic, no tokens needed)
2. Consider enabling enforcement in Firebase Console
3. Monitor App Check metrics in Firebase Console

### For Firebase Functions:
Current setting `consumeAppCheckToken: false` means:
- Functions accept requests without valid App Check tokens
- Warnings are logged but requests aren't blocked
- Good for development, consider enforcing for production

## Troubleshooting

### Token Not Appearing?
1. Make sure you're in DEBUG mode
2. Clean build folder (Shift+Cmd+K)
3. Delete app from simulator
4. Check that FirebaseClient shows: "🔐 Firebase App Check configured with DEBUG provider"

### Still Getting Warnings?
1. Token might have expired (add new one)
2. Wrong Firebase project (check GoogleService-Info.plist)
3. Multiple developers (each needs their own token)

### Want to Disable Warnings Completely?
Not recommended, but if needed, you can:
1. Keep `consumeAppCheckToken: false` in functions
2. Ignore the warnings (they don't affect functionality)
3. Or implement custom token validation logic

## Best Practices

1. **Development**: Use debug tokens, add them to Firebase Console
2. **Testing**: Each tester needs their debug token added
3. **Production**: Enable App Check enforcement gradually:
   - Start with monitoring mode
   - Watch metrics for failed attestations
   - Enable enforcement when confident

## Code Reference

The App Check is configured in:
- `Growth/Core/Networking/FirebaseClient.swift` - Main configuration
- `Growth/Core/Networking/AppCheckDebugHelper.swift` - Debug helper utilities

Firebase functions configuration in:
- All functions have `consumeAppCheckToken: false`
- This allows operation without enforcement