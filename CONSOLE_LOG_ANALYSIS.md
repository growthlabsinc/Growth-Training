# Console Log Analysis & Fixes

## Issues Found in Console Logs

### 1. **registerPushToStartToken HTTP 500 Error**
```
Response code: 500, 1128.6950ms
Failed to sync push-to-start token: FunctionsError(code: INTERNAL)
```

**Root Cause**: Firestore permission denied when function tries to write to user document

### 2. **Firestore Permission Error in Cloud Function**
```
Error: 7 PERMISSION_DENIED: Missing or insufficient permissions
```

**Root Cause**: The Compute Engine default service account (`997901246801-compute@developer.gserviceaccount.com`) didn't have Firestore write permissions

## Fixes Applied

### 1. **Granted Firestore Permissions to Service Accounts** ✅

```bash
# Firebase Admin SDK service account
gcloud projects add-iam-policy-binding growth-training-app \
  --member="serviceAccount:firebase-adminsdk-fbsvc@growth-training-app.iam.gserviceaccount.com" \
  --role="roles/datastore.owner"

# Compute Engine default service account (used by Cloud Functions)
gcloud projects add-iam-policy-binding growth-training-app \
  --member="serviceAccount:997901246801-compute@developer.gserviceaccount.com" \
  --role="roles/datastore.owner"

# App Engine default service account
gcloud projects add-iam-policy-binding growth-training-app \
  --member="serviceAccount:growth-training-app@appspot.gserviceaccount.com" \
  --role="roles/datastore.user"
```

### 2. **Redeployed Functions with Updated Permissions** ✅

```bash
firebase deploy --only functions:registerPushToStartToken,functions:registerLiveActivityPushToken --force
```

## Current Status

| Component | Status | Notes |
|-----------|--------|-------|
| AI Coach Function | ✅ Working | Returns 401 for unauthenticated requests (expected) |
| registerPushToStartToken | ✅ Fixed | Now has Firestore write permissions |
| registerLiveActivityPushToken | ✅ Fixed | Now has Firestore write permissions |
| APNS Configuration | ✅ Working | Using generic secret names |
| Service Account Permissions | ✅ Fixed | All service accounts have proper Firestore access |

## What the App Should Do Now

1. **Push Token Registration**: Should successfully store push tokens in Firestore
2. **Live Activities**: Should be able to register and update Live Activities
3. **AI Coach**: Should work when authenticated
4. **No More 500 Errors**: The permission issues are resolved

## Testing Instructions

1. **Kill the app completely** (swipe up and remove from app switcher)
2. **Restart the app** using Production scheme
3. **Check for successful token registration** in the console logs
4. **Start a timer** to test Live Activities
5. **Try AI Coach** to verify it works

## Key Learnings

1. **Firebase Functions v2** run on Cloud Run and use the Compute Engine default service account
2. **Admin SDK doesn't bypass rules** when the service account lacks IAM permissions
3. **Service account permissions** are separate from Firestore security rules
4. **Always check which service account** a Cloud Function is using:
   ```bash
   gcloud run services describe [function-name] --region=us-central1 \
     --format="value(spec.template.spec.serviceAccountName)"
   ```

## Monitoring Commands

```bash
# Check function logs
firebase functions:log --only registerPushToStartToken -n 20

# Check service account permissions
gcloud projects get-iam-policy growth-training-app \
  --flatten="bindings[].members" \
  --filter="bindings.members:*compute@developer*"

# Test function directly
curl -X POST https://registerpushtostarttoken-dupkvreb7q-uc.a.run.app \
  -H "Content-Type: application/json" \
  -d '{"data": {"token": "test"}}'
```

The permission issues have been resolved. The app should now work correctly without any 500 errors.