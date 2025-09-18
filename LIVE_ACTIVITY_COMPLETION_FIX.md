# Live Activity Completion Display Fix

## Issue Found
The Live Activity shows "Complete!" but was dismissing after only 6 seconds instead of the intended 5 minutes.

## Root Cause
In `manageLiveActivityUpdates.js`, the dismissal date was set to:
```javascript
const dismissalDate = Math.floor(Date.now() / 1000) + 6; // Dismiss after 6 seconds
```

## Fix Applied
Changed to:
```javascript
const dismissalDate = Math.floor(Date.now() / 1000) + 300; // Dismiss after 5 minutes
```

## How Completion Works

1. **App Side** (TimerService.swift):
   - When timer completes, calls `LiveActivityManager.shared.completeActivity()`
   - Sends completion message: "Great job completing your [methodName] session!"

2. **Widget Side** (GrowthTimerWidgetLiveActivity.swift):
   - Shows "Complete!" when `isCompleted` is true
   - Checks both content state and App Group for completion status
   - Displays completion UI with checkmark icon

3. **Firebase Functions** (manageLiveActivityUpdates.js):
   - Detects when countdown reaches 0
   - Sends completion state with `isCompleted: true`
   - Sets stale date and dismissal date to 5 minutes

## APNs Token Issue (Separate Problem)

The BadDeviceToken error is unrelated to completion display. It's caused by:
- Development tokens (from Xcode) being sent to production APNs
- Need to test with TestFlight/Ad Hoc build for production tokens

## Testing Steps

1. Start a 1-minute timer
2. Wait for completion
3. Should see "Complete!" message
4. Activity should remain visible for 5 minutes
5. Auto-dismisses after 5 minutes

## Status
- Completion display logic: ✅ Working
- 5-minute visibility: ✅ Fixed (pending deployment)
- Push updates: ❌ Needs production build or APNs fix