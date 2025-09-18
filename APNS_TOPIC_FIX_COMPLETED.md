# APNs Topic Fix - January 2025

## Problem
The `updateLiveActivity` Firebase function was failing with `InvalidProviderToken` errors because it was using the wrong APNs topic.

## Root Cause
The function was using the widget bundle ID for the APNs topic:
```
com.growthlabs.growthmethod.GrowthTimerWidget.push-type.liveactivity
```

According to Apple's documentation, the topic must be the main app's bundle ID:
```
com.growthlabs.growthmethod.push-type.liveactivity
```

## Fix Applied
Updated the following Firebase functions to use the main app bundle ID (`tokenData.bundleId`) instead of the widget bundle ID (`tokenData.widgetBundleId`):

### Files Updated:
1. **`functions/liveActivityUpdatesSimple.js`**
   - Changed `tokenData.widgetBundleId` to `tokenData.bundleId` for topic construction
   - Lines 323-326, 432-435, 737-740

2. **`functions/liveActivityUpdates.js`**
   - Changed `tokenData.widgetBundleId` to `tokenData.bundleId` for topic construction
   - Lines 297-300, 398-401, 553-555

### Code Changes:
```javascript
// Before (incorrect):
if (tokenData?.widgetBundleId) {
  topicOverride = `${tokenData.widgetBundleId}.push-type.liveactivity`;
}

// After (correct):
if (tokenData?.bundleId) {
  // Use main app bundle ID, not widget bundle ID for APNs topic
  topicOverride = `${tokenData.bundleId}.push-type.liveactivity`;
}
```

## Deployment
Successfully deployed the updated functions:
- `updateLiveActivity`
- `updateLiveActivityTimer`
- `onTimerStateChange`

## Expected Result
Live Activity push updates should now work correctly without `InvalidProviderToken` errors.

## Verification
To verify the fix:
1. Start a new Live Activity timer
2. Check Firebase function logs: `firebase functions:log --only updateLiveActivity`
3. Confirm the topic is now: `com.growthlabs.growthmethod.push-type.liveactivity`
4. Verify push updates are working (pause/resume/stop)

## Related Documentation
- [Apple Developer - Live Activities Push Notifications](https://developer.apple.com/documentation/activitykit/updating-live-activities-with-push-notifications)
- APNs topic format: `<app-bundle-id>.push-type.liveactivity`