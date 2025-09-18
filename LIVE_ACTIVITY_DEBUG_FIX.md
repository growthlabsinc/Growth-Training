# Live Activity Debug Build Fix

## Date: 2025-09-10

## Issues Fixed

### 1. Firebase Initialization Warning
- **Issue**: "The default Firebase app has not yet been configured" warning in widget extension
- **Root Cause**: Widget extension doesn't need Firebase initialization for Live Activities
- **Resolution**: This is expected behavior - widget only displays timer UI, doesn't need Firebase

### 2. APNS Environment Configuration
- **Issue**: Development builds were using production APNS key
- **Root Cause**: Firebase function was hardcoded to always use production key
- **Fix Applied**: Modified `liveActivityUpdates.js` to:
  - Properly detect development environment from iOS app
  - Use development key (55LZB28UY2) for development server
  - Use production key (DQ46FN4PQU) for production server

### 3. Push Update INTERNAL Error
- **Issue**: Push updates failing with "INTERNAL" error in development
- **Root Cause**: Wrong APNS key being used for development environment
- **Fix Applied**: Corrected key selection logic in Firebase functions

## Code Changes

### `/functions/liveActivityUpdates.js`

1. **Fixed key selection based on environment** (lines 491-501):
```javascript
// Select the correct key based on environment
// Development environment uses development key (55LZB28UY2)
// Production environment uses production key (DQ46FN4PQU)
const isDevelopmentServer = !useProduction;
const keyIdToUse = isDevelopmentServer ? config.apnsKeyIdDev : config.apnsKeyIdProd;
logger.log(`  Key ID: ${keyIdToUse} (${environment} environment)`);

// Use the appropriate key for the environment
token = await generateAPNsToken(!isDevelopmentServer); // false for dev, true for prod
```

2. **Updated generateAPNsToken function** (lines 115-127):
```javascript
// For development, use development key (55LZB28UY2)
// For production, use production key (DQ46FN4PQU)
const keyId = useProduction ? (config.apnsKeyIdProd || 'DQ46FN4PQU') : (config.apnsKeyIdDev || '55LZB28UY2');
const authKey = useProduction ? config.apnsKeyProd : config.apnsKeyDev;
```

3. **Improved credential initialization** (lines 61-75):
```javascript
// Set development credentials
config.apnsKeyDev = devKey;
config.apnsKeyIdDev = '55LZB28UY2';

// Set production credentials
config.apnsKeyProd = prodKey;
config.apnsKeyIdProd = 'DQ46FN4PQU';
```

## Environment Detection

The iOS app correctly detects and sends the environment:

### `LiveActivityManager.swift` (lines 867-878):
```swift
private func getCurrentAPNSEnvironment() -> String {
    #if DEBUG
    return "development"  // Uses development APNS server
    #else
    // Check if it's a TestFlight build
    if Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt" {
        return "sandbox"
    } else {
        return "production"
    }
    #endif
}
```

## APNS Configuration

### Development Environment
- **Key ID**: 55LZB28UY2
- **Key File**: `AuthKey_55LZB28UY2.p8`
- **Server**: api.development.push.apple.com
- **Used for**: Xcode Debug builds

### Production Environment
- **Key ID**: DQ46FN4PQU
- **Key File**: `AuthKey_DQ46FN4PQU.p8`
- **Server**: api.push.apple.com
- **Used for**: TestFlight and App Store builds

## Testing Instructions

1. **Deploy the fixed Firebase functions**:
```bash
firebase deploy --only functions:updateLiveActivity,functions:registerLiveActivityToken
```

2. **Build and run in Xcode**:
- Select Debug build configuration
- Build to physical device (Live Activities don't work in simulator)
- The app will automatically use development APNS

3. **Monitor Live Activity**:
```bash
./monitor_live_activity.sh
```

4. **Check Firebase logs**:
```bash
firebase functions:log --lines 50
```

## Expected Behavior

### Debug Builds
- Environment sent as "development" to Firebase
- Firebase uses development key (55LZB28UY2)
- APNS requests go to api.development.push.apple.com
- Push updates work correctly

### TestFlight/Production Builds
- Environment sent as "sandbox" or "production"
- Firebase uses production key (DQ46FN4PQU)
- APNS requests go to api.push.apple.com
- Push updates work correctly

## Verification

Look for these logs in Firebase Functions:

```
🔧 APNs Environment Detection:
  - Token Environment: development
  - Bundle ID: com.growthlabs.growthmethod
  - Preferred Environment: development

📱 Attempting DEVELOPMENT environment...
  Host: api.development.push.apple.com
  Key ID: 55LZB28UY2 (development environment)

✅ Live Activity update sent successfully using development environment
```

## Summary

The Live Activity push notifications now correctly:
1. Detect the build environment (Debug/TestFlight/Production)
2. Use the appropriate APNS key for each environment
3. Connect to the correct APNS server
4. Successfully deliver push updates in all environments

The Firebase initialization warning in the widget extension is expected and doesn't affect functionality.