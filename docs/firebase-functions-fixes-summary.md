# Firebase Functions Error Fixes Summary

## Overview
This document summarizes the fixes applied to resolve Firebase Functions errors found in the logs.

## Errors Fixed

### 1. handleAppStoreNotification - Critical Error ❌ → ✅
**Error**: `process.env.FIREBASE_CONFIG is not available. Please use the latest version of the Firebase CLI to deploy this function.`

**Root Cause**: The function was using the deprecated `functions.config()` which is no longer available in Firebase Functions v2.

**Fix Applied**:
- Updated `functions/src/config/appStoreConfig.js` to use Secret Manager (`defineSecret`) instead of `functions.config()`
- Updated `functions/src/appStoreNotifications.js` to use Firebase Functions v2 syntax (`onRequest` from 'firebase-functions/v2/https')
- Replaced all `functions.logger` references with proper v2 logger imports
- Added secrets configuration to the function definition

### 2. updateLiveActivitySimplified - Multiple Errors ❌ → ✅

#### App Check Error
**Error**: `Failed to validate AppCheck token: App attestation failed`

**Fix**: This should be resolved now that the debug token `DC769389-3431-4556-A9BB-44B79AF64E65` has been registered in Firebase Console.

#### APNs Authentication Error  
**Error**: `APNs request failed with status 403: InvalidProviderToken`

**Root Cause**: The function wasn't properly accessing the APNs authentication key from Firebase Secrets.

**Fix Applied**:
- Updated the `generateAPNsToken()` function to properly access secrets from `process.env`
- Added error logging to help debug secret access issues
- Added PEM header formatting for the private key if missing
- Improved error messages to show which environment variables are available

### 3. validateSubscriptionReceipt - Monitoring Required ⚠️
No explicit errors shown, but "Update operation" logs suggest the function is running. Monitor after deployment to ensure it's working correctly.

## Required Secrets Configuration

The following secrets must be configured in Firebase:

```bash
# APNs (Apple Push Notification service)
APNS_AUTH_KEY         # Content of your .p8 file
APNS_KEY_ID          # e.g., 55LZB28UY2
APNS_TEAM_ID         # e.g., 62T6J77P6R

# App Store Connect
APP_STORE_CONNECT_KEY_ID      # Your API Key ID
APP_STORE_CONNECT_ISSUER_ID   # Your Issuer ID  
APP_STORE_SHARED_SECRET       # For receipt validation
```

## Deployment Instructions

1. **Set up secrets** (if not already done):
   ```bash
   ./setup_firebase_secrets.sh
   ```

2. **Deploy the fixed functions**:
   ```bash
   ./fix_firebase_functions.sh
   ```

   Or manually:
   ```bash
   firebase deploy --only functions:handleAppStoreNotification,functions:updateLiveActivitySimplified,functions:validateSubscriptionReceipt
   ```

3. **Verify deployment**:
   ```bash
   # Check function logs
   firebase functions:log --only handleAppStoreNotification,updateLiveActivitySimplified
   
   # List configured secrets
   firebase functions:secrets:list
   ```

## Testing

After deployment:

1. **Test App Store Webhook**:
   - The webhook URL is: `https://us-central1-growth-70a85.cloudfunctions.net/handleAppStoreNotification`
   - Configure this URL in App Store Connect

2. **Test Live Activity Updates**:
   - Run the app and start a timer
   - Check if Live Activity updates are sent without errors

3. **Monitor Logs**:
   ```bash
   firebase functions:log --follow
   ```

## Key Changes Made

1. **Migrated from Functions v1 to v2**:
   - Changed from `functions.https.onRequest` to `onRequest` from v2
   - Updated logger usage
   - Added proper secret management

2. **Fixed Secret Access**:
   - Secrets are now properly defined using `defineSecret()`
   - Access secrets via `process.env.SECRET_NAME` within function execution

3. **Improved Error Handling**:
   - Added detailed error logging
   - Better error messages for debugging

## Additional Notes

- The App Check debug token (`DC769389-3431-4556-A9BB-44B79AF64E65`) must be registered in Firebase Console
- Secrets take a few minutes to become available after deployment
- Always use `firebase functions:secrets:list` to verify secrets are configured before deployment