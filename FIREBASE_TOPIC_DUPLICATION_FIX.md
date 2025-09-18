# Firebase Live Activity Topic Duplication Fix

## Problem
Firebase logs showed "TopicDisallowed" error with duplicated `.push-type.liveactivity` suffix:
```
topic: 'com.growthlabs.growthmethod.push-type.liveactivity.push-type.liveactivity'
```

## Root Cause
The topic was being constructed with `.push-type.liveactivity` suffix in two places:

1. **liveActivityUpdates.js** (line 656):
   ```javascript
   topicOverride = `${tokenData.bundleId}.push-type.liveactivity`;
   ```

2. **apnsHelper.js** (line 187):
   ```javascript
   'apns-topic': `${topic}.push-type.liveactivity`
   ```

This resulted in the suffix being appended twice when `topicOverride` was passed to `sendToAPNs`.

## Solution
Updated `apnsHelper.js` to check if the topic already contains `.push-type.liveactivity` before appending:

```javascript
// Check if topic already contains .push-type.liveactivity to avoid duplication
const apnsTopic = topic.includes('.push-type.liveactivity') 
  ? topic 
  : `${topic}.push-type.liveactivity`;

console.log(`📱 [sendToAPNs] Using APNS topic: ${apnsTopic}`);

const headers = {
  // ...
  'apns-topic': apnsTopic,
  // ...
};
```

## Files Modified
- `/functions/apnsHelper.js` - Added check to prevent duplicate suffix

## Deployment
```bash
firebase deploy --only functions:updateLiveActivityTimer,functions:liveActivityUpdates
```

## Result
✅ Topic duplication issue fixed
✅ APNS requests will now use correct topic format: `com.growthlabs.growthmethod.push-type.liveactivity`
✅ Live Activity push notifications should work correctly

## Testing
Monitor Firebase logs for successful push notifications:
```bash
firebase functions:log --only updateLiveActivityTimer --lines 50
```

Look for:
- Correct topic format in logs
- No more "TopicDisallowed" errors
- Successful APNS responses (200 status)