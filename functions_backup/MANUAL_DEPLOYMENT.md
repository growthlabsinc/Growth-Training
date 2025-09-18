# Manual Deployment Instructions for Firebase Functions

Due to Firebase CLI timeout issues, follow these steps to deploy manually:

## 1. Prepare the deployment

The `functions-deploy.zip` file has been created with all necessary files.

## 2. Deploy via Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select project: `growth-70a85`
3. Navigate to Cloud Functions
4. Click "CREATE FUNCTION" or select an existing function to update

## 3. For the manageLiveActivityUpdates function:

### Function Configuration:
- **Function name**: manageLiveActivityUpdates
- **Region**: us-central1
- **Trigger type**: Cloud Firestore
- **Event type**: providers/cloud.firestore/eventTypes/document.write
- **Document path**: timerState/{userId}
- **Runtime**: Node.js 20
- **Entry point**: manageLiveActivityUpdates

### Environment Variables:
```
APPLE_TEAM_ID=YY379XWXUK
APNs_KEY_ID=3G84L8G52R
APNs_BUNDLE_ID=com.growthtraining.Growth
WIDGET_BUNDLE_ID=com.growthtraining.Growth.GrowthTimerWidget
```

### Code:
Upload the `functions-deploy.zip` file or copy the code from `manageLiveActivityUpdates.js`

## 4. Key Changes Made

The main fix was replacing axios with http2 for Apple Push Notification service:

```javascript
// OLD (not working)
const axios = require('axios');

// NEW (fixed)
const http2 = require('http2');
```

## 5. Deploy Other Functions

Repeat the process for other functions if needed:
- generateAIResponse
- updateLiveActivityTimer
- onTimerStateChange
- updateLiveActivity
- startLiveActivity

## 6. Verify Deployment

After deployment, check:
1. Function logs in Cloud Console
2. Test Live Activity updates with device locked
3. Monitor for "Parse Error: Expected HTTP/" errors (should be gone)

## Alternative: Use gcloud CLI

If manual deployment fails, try:

```bash
gcloud functions deploy manageLiveActivityUpdates \
  --runtime nodejs20 \
  --trigger-event providers/cloud.firestore/eventTypes/document.write \
  --trigger-resource "projects/growth-70a85/databases/(default)/documents/timerState/{userId}" \
  --region us-central1 \
  --source . \
  --entry-point manageLiveActivityUpdates \
  --set-env-vars APPLE_TEAM_ID=YY379XWXUK,APNs_KEY_ID=3G84L8G52R,APNs_BUNDLE_ID=com.growthtraining.Growth,WIDGET_BUNDLE_ID=com.growthtraining.Growth.GrowthTimerWidget
```