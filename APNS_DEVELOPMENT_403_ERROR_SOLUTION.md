# APNs 403 Forbidden Error in Development Environment

## Issue
Getting `403 Forbidden` error when sending push notifications in development/debug builds:
```
ERROR 2025-09-11T22:38:54.572227Z Error: ❌ 403 Forbidden in development - Invalid authentication
```

## Root Cause
The 403 error occurs when there's a mismatch between:
1. The APNs environment (development vs production)
2. The APNs authentication key being used
3. The device token's environment

## Current Configuration

### APNs Keys in Use:
- **Development Key**: `55LZB28UY2` 
- **Production Key**: `DQ46FN4PQU`
- **Server**: `api.development.push.apple.com` (for dev)

## Common Causes of 403 Errors

### 1. **Invalid Authentication Key**
- The APNs key might be revoked or invalid
- Wrong key ID or team ID

### 2. **Environment Mismatch**
- Development token sent to production server
- Production token sent to development server

### 3. **Bundle ID Mismatch**
- Topic doesn't match the app's bundle ID
- Currently using: `com.growthlabs.growthmethod.push-type.liveactivity`

### 4. **Key Permissions**
- APNs key doesn't have Live Activity permissions
- Key not configured for the right app

## Solutions

### Option 1: Use Production Key for All Environments (Recommended)
APNs authentication keys (p8 files) work for BOTH development and production. You don't need separate keys.

```javascript
// In liveActivityUpdates.js, always use production key
const keyId = process.env.APNS_KEY_ID || 'DQ46FN4PQU'; // Use production key
const useProduction = true; // Always use production key
```

### Option 2: Fix Token Environment Detection
The issue might be that the function is incorrectly detecting the token environment. Add better logging:

```javascript
function detectEnvironmentFromToken(token) {
    // Development tokens are shorter (typically 64 chars hex)
    // Production tokens are longer (typically 160+ chars)
    if (token.length < 100) {
        logger.log('📱 Detected DEVELOPMENT token (length: ' + token.length + ')');
        return 'development';
    } else {
        logger.log('📱 Detected PRODUCTION token (length: ' + token.length + ')');
        return 'production';
    }
}
```

### Option 3: Check Key Configuration in Firebase Console
1. Go to Firebase Console → Project Settings → Cloud Messaging
2. Verify APNs authentication key is uploaded
3. Ensure key has proper permissions

### Option 4: Force Production Environment Temporarily
For testing, force production environment in the Firebase function:

```javascript
// In updateLiveActivity function
const forceProduction = true; // Temporary override
const environment = forceProduction ? 'production' : detectEnvironmentFromToken(pushToken);
```

## Quick Fix to Apply Now

In `/functions/liveActivityUpdates.js`, update the sendPushNotification function:

```javascript
async function sendPushNotification(pushToken, payload, eventType = 'update', topicOverride = null, frequentPushesEnabled = true) {
    // TEMPORARY FIX: Always use production key and server
    // APNs auth keys work for both environments
    const useProduction = true; // Force production
    const keyId = 'DQ46FN4PQU'; // Production key works for all environments
    const host = useProduction ? config.APNS_HOST_PROD : config.APNS_HOST_DEV;
    
    logger.log(`📱 Using ${useProduction ? 'PRODUCTION' : 'DEVELOPMENT'} environment`);
    logger.log(`  Host: ${host}`);
    logger.log(`  Key ID: ${keyId}`);
    
    // Continue with existing code...
}
```

## Why This Works

1. **APNs Authentication Keys (p8)** are universal - they work for both development and production
2. **Device tokens** determine the environment, not the key
3. **Production server** (`api.push.apple.com`) can handle both token types

## Testing After Fix

1. Deploy the updated Firebase function
2. Test with a development build
3. Check Firebase logs for successful delivery
4. Verify Live Activity updates work

## Long-term Solution

Consider implementing automatic environment detection based on the token format:
- Development tokens: Shorter, from Xcode builds
- Production tokens: Longer, from TestFlight/App Store

But for immediate resolution, using the production key for all environments is the simplest and most reliable approach.