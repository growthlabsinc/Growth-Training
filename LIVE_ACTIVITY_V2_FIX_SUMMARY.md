# Live Activity Firebase Functions V2 Fix Summary

## Issues Fixed

### 1. Functions Not Deployed
The Live Activity functions (`updateLiveActivityTimer`, `updateLiveActivity`) were not deployed. They are now successfully deployed as v2 functions.

### 2. Secret Access Issue
The main issue was incorrect secret access in Firebase Functions v2:
- **Before**: `config.apnsKey = apnsAuthKeySecret.value();`
- **After**: `config.apnsKey = process.env.APNS_AUTH_KEY;`

In Firebase Functions v2, secrets defined with `defineSecret()` are automatically injected into `process.env` when the function runs.

### 3. APNs Configuration
- Updated APNs Key ID: `66LQV834DU`
- Team ID: `62T6J77P6R`
- Bundle ID: `com.growthlabs.growthmethod`
- Topic: `com.growthlabs.growthmethod.GrowthTimerWidget.push-type.liveactivity`

## Files Modified
1. `/functions/liveActivityUpdatesSimple.js` - Fixed secret access
2. `/functions/manageLiveActivityUpdates.js` - Fixed secret access

## Deployment Status
✅ All Live Activity functions are now deployed:
- `updateLiveActivityTimer` - v2 callable function
- `updateLiveActivity` - v2 callable function  
- `onTimerStateChange` - v2 Firestore trigger
- `manageLiveActivityUpdates` - v2 callable function

## Remaining Issues
1. **Timer State Not Found**: The iOS app needs to create the `activeTimers` document in Firestore before calling Live Activity functions
2. **APNs Environment**: The app is using production bundle ID but might have development push tokens

## Next Steps for iOS App
1. Ensure `activeTimers` document is created with proper timer state before calling functions
2. Verify push tokens match the APNs environment (production vs development)
3. Test Live Activity updates again with the fixed functions