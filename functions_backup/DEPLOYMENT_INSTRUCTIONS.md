# Manual Deployment Instructions for Live Activity Push Updates

Since Firebase deployment is timing out, here are alternative approaches:

## Option 1: Deploy via Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select your project: `growth-70a85`
3. Navigate to Cloud Functions
4. Find `manageLiveActivityUpdates`
5. Click "Edit"
6. Replace the function code with the updated version from `manageLiveActivityUpdates.js`
7. Click "Deploy"

## Option 2: Use gcloud CLI

```bash
# Install/update gcloud CLI
brew install google-cloud-sdk

# Authenticate
gcloud auth login

# Set project
gcloud config set project growth-70a85

# Deploy the function directly
gcloud functions deploy manageLiveActivityUpdates \
  --runtime nodejs20 \
  --trigger-http \
  --allow-unauthenticated \
  --source . \
  --entry-point manageLiveActivityUpdates \
  --region us-central1
```

## Option 3: Deploy All Functions

Sometimes deploying all functions works better than individual ones:

```bash
firebase deploy --only functions --force
```

## What Was Fixed

The main issue was in `manageLiveActivityUpdates.js`:
- Replaced `axios` with `http2` module for APNs communication
- Fixed the "Parse Error: Expected HTTP/" error
- APNs requires HTTP/2 protocol which axios doesn't support

## Testing After Deployment

1. Start a new timer in the app
2. Lock your device
3. Watch for continuous updates in the Live Activity
4. Check logs: `firebase functions:log`

Look for:
- "Successfully sent push update" messages
- No more "Parse Error: Expected HTTP/" errors

## Current Issues to Monitor

- "BadDeviceToken" errors may indicate:
  - Development vs Production environment mismatch
  - Expired push tokens
  - Need to restart timer to get fresh token