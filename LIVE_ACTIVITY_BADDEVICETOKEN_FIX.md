# Live Activity BadDeviceToken Fix

## Issue
When running the app from Xcode in debug mode, iOS generates development/sandbox push tokens, but we were sending them to the production APNs endpoint, causing "BadDeviceToken" errors.

## Solution Implemented
Updated the `updateLiveActivity` function to:
1. First try the production APNs endpoint (`api.push.apple.com`)
2. If it fails with "BadDeviceToken", automatically retry with the development endpoint (`api.development.push.apple.com`)

This ensures the Live Activity updates work in both:
- **Development**: When running from Xcode (uses sandbox tokens)
- **Production**: When installed from TestFlight/App Store (uses production tokens)

## Code Changes
```javascript
// Added both endpoints
const APNS_HOST_PROD = 'api.push.apple.com';
const APNS_HOST_DEV = 'api.development.push.apple.com';

// Added retry logic
try {
  await sendLiveActivityUpdate(finalPushToken, activityId, contentState, null, topicOverride, false);
} catch (error) {
  if (error.message && error.message.includes('BadDeviceToken')) {
    console.log('🔄 Retrying with development APNs endpoint...');
    await sendLiveActivityUpdate(finalPushToken, activityId, contentState, null, topicOverride, true);
  } else {
    throw error;
  }
}
```

## Testing
1. Run the app from Xcode
2. Start a timer
3. The function will:
   - Try production endpoint first
   - Get "BadDeviceToken" error
   - Automatically retry with development endpoint
   - Successfully update the Live Activity

## Production Behavior
When the app is distributed via TestFlight or App Store:
- Tokens will be production tokens
- First attempt with production endpoint will succeed
- No retry needed

## Summary
This fix allows the same Firebase Function to work seamlessly in both development and production environments without any configuration changes.