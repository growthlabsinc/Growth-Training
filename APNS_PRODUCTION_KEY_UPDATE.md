# APNs Production Key Update - January 12, 2025

## Update Summary
Updated the Apple Push Notification service (APNs) authentication key to the new production key.

## Key Details
- **Previous Key ID**: 5B5FLK3MG7 (development key)
- **New Key ID**: FM3P8KLCJQ (production key)
- **Key File**: AuthKey_FM3P8KLCJQ.p8
- **Team ID**: 62T6J77P6R (unchanged)

## Changes Made

### 1. Firebase Secrets Updated
✅ `APNS_AUTH_KEY` - Updated with new production .p8 key content
✅ `APNS_KEY_ID` - Updated to FM3P8KLCJQ

### 2. Code Updates
✅ `LiveActivityPushService.swift` - Updated comment with new production key ID
✅ `functions/.env` - Updated documentation with new key ID
✅ `manageLiveActivityUpdates.js` - Updated fallback key ID to FM3P8KLCJQ
✅ `liveActivityUpdatesSimple.js` - Updated fallback key ID to FM3P8KLCJQ

### 3. Firebase Functions Deployment
🔄 All functions being redeployed with new production APNs configuration
- This updates all 5 functions using the APNs secrets:
  - testAPNsConnection
  - updateLiveActivity
  - onTimerStateChange
  - manageLiveActivityUpdates
  - updateLiveActivityTimer

## Important Notes
1. This is a production key - ensure it's configured properly in Apple Developer Portal
2. The key must have APNs capabilities enabled for production use
3. Test Live Activity push updates on TestFlight/production builds
4. Previous development key (5B5FLK3MG7) can be removed from Apple Developer Portal

## Verification Steps
1. Check deployment status: `firebase functions:log`
2. Test APNs connection: Call `testAPNsConnection` function
3. Test Live Activity updates on production build
4. Monitor logs for successful push notifications

## Key Timeline
- TIFLJYQ0RT0J - Original key (replaced earlier)
- 5B5FLK3MG7 - Development key (replaced now)
- FM3P8KLCJQ - Current production key