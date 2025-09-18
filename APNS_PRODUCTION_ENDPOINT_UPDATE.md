# APNs Production Endpoint Update

## Summary
Updated all Firebase functions to use the production APNs endpoint (`api.push.apple.com`) instead of the development endpoint (`api.development.push.apple.com`) since the app now uses a production APNs key.

## Changes Made

### 1. `/functions/liveActivityUpdates.js`
- **Line 41**: Changed `config.APNS_HOST_DEV = 'api.development.push.apple.com';` to `config.APNS_HOST_DEV = 'api.push.apple.com';`
- Both production and development configurations now point to the production APNs server

### 2. `/functions/collectAPNsDiagnostics.js`
- **Line 34**: Changed DNS lookup from `api.development.push.apple.com` to `api.push.apple.com`

### 3. Files Already Using Production Endpoint
- `/functions/manageLiveActivityUpdates.js` - Already defaults to `api.push.apple.com`
- `/functions/apnsHelper.js` - Already returns `api.push.apple.com`
- `/functions/test-apns-direct.js` - Already uses `api.push.apple.com`

## Why This Change Was Needed
The app recently migrated from a sandbox/development APNs key to a production APNs key. When using a production key, all push notifications must be sent to the production APNs endpoint (`api.push.apple.com`), even in development environments. Using the development endpoint with a production key results in authentication failures.

## Impact
- Live Activity push notifications will now work correctly with the production APNs key
- No changes needed in the iOS app - it will continue to work as expected
- The functions will automatically use the correct endpoint for push notifications

## Next Steps
Deploy these changes to Firebase Functions:
```bash
firebase deploy --only functions:liveActivityUpdates,functions:manageLiveActivityUpdates
```