# Live Activity Fix Summary

## Issues Fixed

### 1. Live Activity Dismissal Policy
- **Issue**: Live Activity was dismissing after only 1 second instead of staying visible for 5 minutes after timer completion
- **Fix**: Updated `LiveActivityManager.completeActivity()` to set dismissal policy to 5 minutes (300 seconds)
- **File**: `Growth/Features/Timer/Services/LiveActivityManager.swift`

### 2. Dismiss Button Behavior
- **Issue**: When users tapped the dismiss button on a completed Live Activity, it was dismissing immediately
- **Fix**: Updated `LiveActivityUpdateManager.endActivity()` to respect the 5-minute delay even when dismiss is tapped
- **File**: `GrowthTimerWidget/LiveActivityUpdateManager.swift`

### 3. Firebase Functions APNs Configuration
- **Issue**: Firebase Functions were failing with INTERNAL error due to outdated bundle ID in APNs configuration
- **Root Cause**: Bundle ID was recently changed from `com.growthtraining.Growth` to `com.growthlabs.growthmethod`
- **Fixes Applied**:
  - Updated APNs topic in `functions/liveActivityUpdates.js`
  - Updated bundle ID mappings for all environments
  - Updated `.env` file with new bundle IDs
  - Resolved environment variable conflicts by deleting and redeploying functions

### Files Modified
1. `Growth/Features/Timer/Services/LiveActivityManager.swift`
2. `GrowthTimerWidget/LiveActivityUpdateManager.swift`
3. `functions/liveActivityUpdates.js`
4. `functions/.env`
5. `functions/moderation.js` (updated to Firebase Functions v2 syntax)
6. `functions/index.js` (updated to Firebase Functions v2 syntax)

### Deployment Status
✅ All Live Activity Firebase Functions successfully deployed:
- `updateLiveActivity`
- `updateLiveActivityTimer`
- `onTimerStateChange`
- `startLiveActivity`
- `manageLiveActivityUpdates`

## Expected Behavior
1. When a timer completes, the Live Activity will show a completion message
2. The completion message will remain visible for 5 minutes
3. Users can tap the dismiss button, but the Live Activity will still remain visible for the full 5 minutes
4. After 5 minutes, the Live Activity will automatically dismiss
5. Push updates to Live Activities should now work correctly with the updated bundle ID

## Notes
- Live Activities will continue to work with local updates even if push updates fail
- The APNs auth key needs to be properly configured in Firebase for push updates to work
- Push updates require a real device (not simulator) and notification permissions