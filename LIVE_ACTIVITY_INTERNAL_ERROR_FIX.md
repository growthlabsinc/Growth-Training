# Live Activity INTERNAL Error Fix - January 12, 2025

## Issue
The `updateLiveActivity` Cloud Function was returning INTERNAL errors when the iOS client tried to update Live Activities.

## Root Cause
The APNs topic was incorrect in the Cloud Functions:
- **Incorrect**: `com.growthlabs.growthmethod.GrowthTimerWidget.push-type.liveactivity`
- **Correct**: `com.growthlabs.growthmethod.push-type.liveactivity`

The topic must be the main app's bundle ID followed by `.push-type.liveactivity`, not the widget's bundle ID.

## Changes Made

### 1. Fixed APNs Topic in Functions
- `liveActivityUpdatesSimple.js`: Updated default APNs topic
- `manageLiveActivityUpdates.js`: Updated all hardcoded APNs topics (3 occurrences)

### 2. Updated Firebase Secret
- Set `APNS_TOPIC` secret to: `com.growthlabs.growthmethod.push-type.liveactivity`

### 3. Added Debug Logging
- Added contentState logging in `updateLiveActivity` to help debug future issues

### 4. Previously Fixed Issues
- Fixed `finalPushToken` undefined error
- Added proper error handling for APNs calls
- Fixed Firebase double initialization warning

## Testing
After deployment completes:
1. Run the app on a physical device
2. Start a timer session
3. Check Firebase logs for successful push updates
4. Verify Live Activity updates properly

## Key Learning
For Live Activities, the APNs topic format is strict:
- Main app bundle ID + `.push-type.liveactivity`
- NOT the widget bundle ID
- This is different from regular push notifications