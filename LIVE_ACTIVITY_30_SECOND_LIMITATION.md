# Live Activity 30-Second Background Update Limitation

## iOS System Limitation

iOS has a built-in limitation where Live Activities cannot be updated locally after 30 seconds in the background. This is to preserve battery life and system resources.

### What This Means:
- When your app goes to the background, you have 30 seconds to update the Live Activity locally
- After 30 seconds, calls to `activity.update()` will fail silently
- The only way to update Live Activities after 30 seconds is through push notifications from a server

## Current Implementation

We've implemented a dual-update strategy to work around this limitation:

### 1. Local Updates (First 30 seconds)
- Immediate updates via `activity.update()` for instant user feedback
- Works perfectly when app is in foreground or recently backgrounded

### 2. Push Updates (After 30 seconds)
- Firebase Functions send updates via Apple Push Notification service (APNs)
- Ensures Live Activity continues updating even when app is suspended

### 3. App Group Fallback
- Completion state is stored in shared UserDefaults
- Widget can read this state even if push updates fail
- Provides additional reliability for showing "Session Complete!" message

## Firebase Function Configuration

The `updateLiveActivity` Firebase Function handles push updates with:
- APNs authentication using P8 key
- Correct topic: `com.growthlabs.growthmethod.GrowthTimerWidget.push-type.liveactivity`
- Support for both production and development environments

## Known Issues & Solutions

### Issue: "Firebase Auth Error" in logs
**Cause**: Function is trying to verify auth tokens but failing
**Solution**: Already handled - function has `consumeAppCheckToken: false`

### Issue: APNs "BadDeviceToken" errors
**Cause**: Mismatch between token environment and APNs endpoint
**Solution**: Function dynamically determines correct topic based on token data

### Issue: Updates not reaching widget after 30 seconds
**Cause**: Push notifications not being sent successfully
**Solution**: Check Firebase Functions logs for errors, ensure APNs certificates are valid

## Testing

To test the 30-second limitation:
1. Start a timer
2. Lock the device or switch to another app
3. Wait 35+ seconds
4. Timer should still update via push notifications
5. When timer completes, "Session Complete!" should appear

## Deployment

To deploy the updated Firebase Functions:
```bash
firebase deploy --only functions:updateLiveActivity,functions:updateLiveActivityTimer,functions:onTimerStateChange
```