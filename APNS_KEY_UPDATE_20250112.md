# APNs Authentication Key Update - January 12, 2025

## Update Summary
Updated the Apple Push Notification service (APNs) authentication key for Live Activity push updates.

## Key Details
- **Previous Key ID**: TIFLJYQ0RT0J
- **New Key ID**: 5B5FLK3MG7
- **Key File**: AuthKey_5B5FLK3MG7.p8
- **Team ID**: 62T6J77P6R (unchanged)

## Changes Made

### 1. Firebase Secrets Updated
✅ `APNS_AUTH_KEY` - Updated with new .p8 key content
✅ `APNS_KEY_ID` - Updated to 5B5FLK3MG7

### 2. Code Updates
✅ `LiveActivityPushService.swift` - Updated comment with new key ID
✅ `functions/.env` - Updated documentation with new key ID
✅ `manageLiveActivityUpdates.js` - Updated fallback key ID
✅ `liveActivityUpdatesSimple.js` - Updated fallback key ID

### 3. Firebase Functions Deployment
🔄 All functions being redeployed with new APNs configuration
- This will update all 5 functions using the APNs secrets:
  - testAPNsConnection
  - updateLiveActivity
  - onTimerStateChange
  - manageLiveActivityUpdates
  - updateLiveActivityTimer

## Important Notes
1. The new key must be configured in Apple Developer Portal
2. Ensure the key has proper APNs capabilities enabled
3. The deployment may take a few minutes to complete
4. Test Live Activity push updates after deployment completes

## Verification Steps
1. Check deployment status: `firebase functions:log`
2. Test APNs connection: Call `testAPNsConnection` function
3. Test Live Activity updates on physical device
4. Monitor logs for successful push notifications