# Live Activity APNS Fix Deployed

## Issue Identified
When running the app from Xcode in debug mode, Live Activity push updates were failing with `INTERNAL` errors in Firebase Functions logs showing:
- **BadDeviceToken** when trying production APNS server
- **BadEnvironmentKeyInToken** when trying development APNS server

## Root Cause
The Firebase function was trying to use different keys for production vs development environments. However, Apple's APNS system requires:
1. Debug/development builds generate **sandbox push tokens**
2. These tokens only work with `api.development.push.apple.com`
3. The **same authentication key** works for both environments
4. The environment is determined by the **server endpoint**, not the key

## Fix Applied
Modified `functions/liveActivityUpdates.js` line 471 to always use the production key (`DQ46FN4PQU`) for both environments:
```javascript
// Always use production key, environment is determined by the server endpoint
token = await generateAPNsToken(true); // Always use production key
```

## Deployment Status
✅ Successfully deployed at 2025-09-10 04:17 UTC
- Function: `updateLiveActivity(us-central1)` 
- Project: `growth-70a85`

## Testing Instructions
1. Run the app from Xcode in debug mode
2. Start a timer to create a Live Activity
3. Use pause/resume buttons in Dynamic Island
4. Verify the Live Activity updates correctly without errors

## Expected Behavior
- Live Activity push updates should work in both:
  - **Debug builds** (Xcode) → Uses sandbox tokens with development APNS server
  - **TestFlight/Production** → Uses production tokens with production APNS server
- Both use the same `DQ46FN4PQU` authentication key

## Monitoring
Check Firebase Functions logs:
```bash
firebase functions:log --only updateLiveActivity --lines 50 --project growth-70a85
```

Look for successful updates without `BadDeviceToken` or `BadEnvironmentKeyInToken` errors.