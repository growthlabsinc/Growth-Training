# Firebase Function Authentication Fix Guide

## Problem Summary
Firebase Functions are returning `UNAUTHENTICATED` errors (401) when called from the iOS app, even though users are properly authenticated. This affects:
- AI Coach (`generateAIResponse`)
- Live Activity functions (`registerPushToStartToken`, etc.)

## Root Cause
Firebase Functions v2 use Cloud Run services under the hood, which require `allUsers` IAM permission to be publicly invokable. However, the organization policy for `growth-training-app` blocks adding `allUsers` to IAM policies, while the working project `growth-70a85` allows it.

## Solution Options (Choose One)

### Option 1: Organization Policy Override (Recommended)
**Required Access**: Organization Admin or Project Owner

1. **Contact your Google Cloud Organization admin** at growthlabs.coach
2. **Request an exception** for project `growth-training-app` to allow `allUsers` in Cloud Run IAM policies
3. **Once approved**, run these commands:
   ```bash
   # Set IAM policy for each function
   gcloud run services add-iam-policy-binding generateairesponse \
     --region=us-central1 \
     --member="allUsers" \
     --role="roles/run.invoker"

   gcloud run services add-iam-policy-binding registerpushtostarttoken \
     --region=us-central1 \
     --member="allUsers" \
     --role="roles/run.invoker"

   # Repeat for other functions as needed:
   # - updateLiveActivity
   # - updateLiveActivityTimer
   # - manageLiveActivityUpdates
   # - testAPNsConnection
   # - registerLiveActivityPushToken
   ```

### Option 2: Downgrade to Firebase Functions v1
**Note**: This is a workaround that avoids Cloud Run entirely

1. **Edit `/functions/package.json`**:
   ```json
   "dependencies": {
     "firebase-functions": "^4.9.0",  // Use v4 instead of v5
     // ... other dependencies
   }
   ```

2. **Update `/functions/index.js`**:
   ```javascript
   // Replace v2 imports:
   // const { onCall } = require('firebase-functions/v2/https');
   // const { onDocumentWritten } = require('firebase-functions/v2/firestore');

   // With v1 imports:
   const functions = require('firebase-functions');
   ```

3. **Convert function definitions**:
   ```javascript
   // From v2:
   exports.generateAIResponse = onCall(
     { cors: true, region: 'us-central1' },
     async (request) => {
       if (!request.auth) { /* ... */ }
       const data = request.data;
       // ...
     }
   );

   // To v1:
   exports.generateAIResponse = functions
     .region('us-central1')
     .https.onCall(async (data, context) => {
       if (!context.auth) { /* ... */ }
       // data is directly available
       // ...
     });
   ```

4. **Reinstall and deploy**:
   ```bash
   cd functions
   npm install
   firebase deploy --only functions
   ```

### Option 3: Project-Level Policy Override
**If you have project owner access but not org admin**

1. **Create policy file** `/tmp/allow-allusers-policy.yaml`:
   ```yaml
   name: projects/growth-training-app/policies/iam.allowedPolicyMemberDomains
   spec:
     rules:
     - allowAll: true
   ```

2. **Apply the policy**:
   ```bash
   gcloud org-policies set-policy /tmp/allow-allusers-policy.yaml \
     --project=growth-training-app
   ```

3. **Then add allUsers to functions** (same commands as Option 1)

### Option 4: Use Service Account Authentication (Complex)
**If org policies can't be changed**

1. **Create a proxy Cloud Function** that doesn't require authentication
2. **Have it verify Firebase tokens manually** and forward to the actual functions
3. **This requires significant code changes** and is not recommended

## Verification Steps

### 1. Check Current IAM Policy
```bash
gcloud run services get-iam-policy generateairesponse --region=us-central1
```

**Working output should show**:
```yaml
bindings:
- members:
  - allUsers
  role: roles/run.invoker
```

**Current broken output shows**:
```yaml
bindings:
- members:
  - domain:growthlabs.coach
  - serviceAccount:firebase-adminsdk-fbsvc@growth-training-app.iam.gserviceaccount.com
  role: roles/run.invoker
```

### 2. Test Function Calls
```bash
# Test without authentication (should work after fix)
curl -X POST https://us-central1-growth-training-app.cloudfunctions.net/testDeployment \
  -H "Content-Type: application/json" \
  -d '{}'
```

### 3. Test in App
- Open the app
- Try using AI Coach
- Check that Live Activities register properly

## Why This Works in `growth-70a85` but not `growth-training-app`

The working production project (`growth-70a85`) has:
```bash
gcloud run services get-iam-policy generateairesponse --region=us-central1
# Shows: allUsers with roles/run.invoker
```

The training project (`growth-training-app`) is blocked by organization policy from adding `allUsers`.

## Additional Commands

### List all Cloud Run services that need fixing:
```bash
gcloud run services list --region=us-central1 --format="value(name)"
```

### Apply fix to all services at once (after policy override):
```bash
for service in $(gcloud run services list --region=us-central1 --format="value(name)"); do
  echo "Fixing $service..."
  gcloud run services add-iam-policy-binding $service \
    --region=us-central1 \
    --member="allUsers" \
    --role="roles/run.invoker"
done
```

## Contact for Help
- **Organization Admin**: Someone at @growthlabs.coach domain
- **Google Cloud Console**: https://console.cloud.google.com/iam-admin/org-policies?project=growth-training-app
- **Firebase Console**: https://console.firebase.google.com/project/growth-training-app/functions

## Notes
- This is a common issue when cloning Firebase projects between organizations
- The organization policy is a security feature to prevent public access to services
- Firebase Functions v2 require public access because they handle authentication internally
- The actual authentication check happens inside the function code via `request.auth`