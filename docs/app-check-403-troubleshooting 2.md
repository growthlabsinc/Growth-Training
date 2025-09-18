# App Check 403 Error Troubleshooting Guide

## Overview
This guide helps troubleshoot Firebase App Check 403 errors in the Growth app.

## Error Description
```
Firebase App Check: Token verification error: 403
<FIRAppCheckErrorInfo: 0x103917f00>
```

## Root Causes and Solutions

### 1. App Not Registered in Firebase Console
**Issue**: The app with bundle ID `com.growthlabs.growthmethod` is not registered for App Check.

**Solution**:
1. Go to [Firebase Console App Check](https://console.firebase.google.com/project/growth-70a85/appcheck/apps)
2. Click on your iOS app
3. Enable App Check if not already enabled
4. Choose "App Attest" as the provider for production

### 2. Debug Token Not Registered (Development)
**Issue**: Debug token for simulator/development builds not registered.

**Solution**:
1. Run the app in simulator with `-FIRDebugEnabled` flag:
   - In Xcode: Product → Scheme → Edit Scheme
   - Select Run → Arguments
   - Add `-FIRDebugEnabled` to Arguments Passed On Launch
2. Copy the debug token from console output
3. Register it in Firebase Console:
   - Go to App Check section
   - Click "Manage debug tokens"
   - Add the token with a descriptive name

### 3. App Attest Not Properly Configured
**Issue**: App Attest capability missing or misconfigured.

**Solution Implemented**:
- Added `com.apple.developer.devicecheck.appattest-environment` to entitlements
- Set environment to `production` (required for App Attest)
- Updated `AppCheckProviderFactory` to support App Attest for iOS 14+

### 4. Provider Factory Implementation
**Updated Implementation**:
```swift
class AppAttestAppCheckFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        if #available(iOS 14.0, *) {
            return AppAttestProvider(app: app)
        } else {
            return DeviceCheckProvider(app: app)
        }
    }
}
```

## Configuration Changes Made

### 1. Entitlements File (`Growth.entitlements`)
Added App Attest capability:
```xml
<key>com.apple.developer.devicecheck.appattest-environment</key>
<string>production</string>
```

### 2. App Check Provider Factory
- Created `AppAttestAppCheckFactory` for production builds
- Falls back to Device Check for iOS < 14.0
- Debug provider remains for development/simulator

### 3. Firebase Client Configuration
- App Check is configured BEFORE `FirebaseApp.configure()`
- Auto-refresh enabled for production tokens
- Debug token retrieval for development builds

## Testing Steps

### For Development (Simulator)
1. Ensure `-FIRDebugEnabled` flag is set
2. Run the app and copy debug token from console
3. Register token in Firebase Console
4. Test Firebase operations

### For Production (Real Device)
1. Ensure App Attest capability is in entitlements
2. Build with production configuration
3. App Check will use App Attest automatically
4. Monitor Firebase Console for successful attestations

## Additional Considerations

### Token TTL (Time To Live)
- Default is 1 hour
- Shorter TTLs improve security but increase overhead
- Can be configured in Firebase Console

### Gradual Rollout
Apple recommends gradual onboarding to avoid quota limits:
- Start with enforcement disabled
- Monitor metrics in Firebase Console
- Enable enforcement after validating everything works

### Monitoring
Check these metrics in Firebase Console:
- Verified request rate
- Unverified request rate
- Token refresh failures
- Provider-specific errors

## Common Issues

### 1. "App not registered" Error
- Verify bundle ID matches Firebase project
- Ensure app is registered in App Check section

### 2. Token Refresh Failures
- Check network connectivity
- Verify App Attest is properly configured
- Check device compatibility (iOS 14.0+)

### 3. Quota Exceeded
- App Attest has daily quotas
- Monitor usage in Firebase Console
- Consider gradual rollout strategy

## Next Steps

1. Deploy Firestore rules: `firebase deploy --only firestore:rules`
2. Test on real device with production build
3. Monitor App Check metrics in Firebase Console
4. Enable enforcement after successful testing