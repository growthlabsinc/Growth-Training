# Firebase Functions Deployment Guide

## Current Status
The functions are ready for deployment but require some APIs and secrets to be configured first.

## Required APIs to Enable

You need to enable these APIs in Google Cloud Console:

1. **Secret Manager API** (for storing APNS keys)
   - URL: https://console.developers.google.com/apis/api/secretmanager.googleapis.com/overview?project=growth-training-app
   - Click "Enable"

2. **Cloud Functions API** (being enabled automatically)
3. **Cloud Build API** (being enabled automatically)
4. **Artifact Registry API** (being enabled automatically)
5. **Firebase Extensions API** (being enabled automatically)

## Secrets Configuration

The functions reference several secrets that need to be created or removed:

### Option 1: Create the Required Secrets (If you have APNS keys)

```bash
# If you have APNS authentication keys from Apple Developer Portal:
firebase functions:secrets:set APNS_AUTH_KEY_DQ46FN4PQU
firebase functions:secrets:set APNS_AUTH_KEY_55LZB28UY2
firebase functions:secrets:set APNS_KEY_ID
firebase functions:secrets:set APNS_TEAM_ID
firebase functions:secrets:set APP_STORE_CONNECT_KEY_ID
firebase functions:secrets:set APP_STORE_CONNECT_ISSUER_ID
firebase functions:secrets:set APP_STORE_CONNECT_SHARED_SECRET
```

### Option 2: Deploy Without Secrets (Recommended for initial deployment)

Modify the functions to make secrets optional. The functions are already checking for environment variables as fallback.

## Deployment Steps

### Step 1: Enable Required APIs
Click and enable each API link above in your browser.

### Step 2: Deploy Functions
```bash
# Deploy all functions
firebase deploy --only functions --project growth-training-app

# Or deploy specific functions
firebase deploy --only functions:generateAIResponse --project growth-training-app
```

### Step 3: If Deployment Fails Due to Secrets

You can either:

1. **Create dummy secrets** (they won't work but will allow deployment):
```bash
echo "dummy-value" | firebase functions:secrets:set APNS_AUTH_KEY_DQ46FN4PQU
echo "dummy-value" | firebase functions:secrets:set APNS_AUTH_KEY_55LZB28UY2
```

2. **Or comment out secret requirements** in the code temporarily

## Functions Being Deployed

Based on `index.js`, these functions will be deployed:

1. **generateAIResponse** - AI Coach functionality (uses Vertex AI)
2. **onTimerStateChange** - Timer state tracking
3. **liveActivityUpdates** - Live Activity push notifications (requires APNS)
4. **subscriptionWebhook** - App Store subscription handling
5. **checkUsernameAvailability** - Username validation

## Post-Deployment Configuration

### 1. Set Function Permissions
```bash
# Allow unauthenticated access to webhook (if needed)
gcloud functions add-iam-policy-binding subscriptionWebhook \
  --member="allUsers" \
  --role="roles/cloudfunctions.invoker" \
  --project=growth-training-app
```

### 2. Get Function URLs
After deployment, Firebase will show the function URLs. Save these for your iOS app configuration.

Example output:
```
Function URL (generateAIResponse): https://us-central1-growth-training-app.cloudfunctions.net/generateAIResponse
```

### 3. Update iOS App Configuration
Add the function URLs to your iOS app configuration.

## Environment Variables

The functions use these environment variables (set automatically by Firebase):
- `FIREBASE_CONFIG` - Firebase project configuration
- `GCLOUD_PROJECT` - Project ID (growth-training-app)

## Monitoring

After deployment:
1. Check function logs: `firebase functions:log`
2. Monitor in Google Cloud Console: https://console.cloud.google.com/functions?project=growth-training-app
3. View metrics and errors in Firebase Console

## Troubleshooting

### If Secret Manager API error:
1. Enable the API at the URL provided in the error
2. Wait 2-3 minutes for propagation
3. Retry deployment

### If authentication errors:
```bash
# Re-authenticate
gcloud auth login
firebase login --reauth
```

### If functions fail after deployment:
```bash
# Check logs
firebase functions:log --only generateAIResponse

# Test locally
firebase emulators:start --only functions
```

## Important Notes

1. **Vertex AI**: The generateAIResponse function requires Vertex AI API to be enabled (done in Story 1.3)
2. **APNS**: Live Activity functions won't work without valid APNS certificates/keys
3. **Billing**: Ensure Blaze plan is active for Cloud Functions to work
4. **Region**: Functions deploy to us-central1 by default