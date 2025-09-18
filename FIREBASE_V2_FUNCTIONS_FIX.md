# Firebase Cloud Functions V2 Configuration Fix

## Problem
Firebase Cloud Functions were consistently returning "INTERNAL" errors because they couldn't access the APNs authentication key stored in Firebase secrets. The functions were using v1 configuration patterns that don't work properly with v2 secrets.

## Solution
Updated all Live Activity-related Firebase functions to use proper v2 configuration with explicit secret definitions.

### Changes Made

1. **Updated `liveActivityUpdatesSimple.js`**:
   - Added `defineSecret` import from `firebase-functions/params`
   - Defined `apnsAuthKeySecret` using `defineSecret('APNS_AUTH_KEY')`
   - Updated APNs key ID from old value to new value: `66LQV834DU`
   - Added `secrets: [apnsAuthKeySecret]` to all function configurations
   - Fixed `onDocumentWritten` to use v2 object configuration

2. **Updated `liveActivityUpdates.js`**:
   - Added `secrets: ['APNS_AUTH_KEY']` to all onCall function configurations
   - Updated APNs key ID to `66LQV834DU`

3. **Updated `manageLiveActivityUpdates.js`**:
   - Added `defineSecret` import and secret definition
   - Removed hardcoded APNs key
   - Updated to access key from Firebase secret using `apnsAuthKeySecret.value()`
   - Added `secrets: [apnsAuthKeySecret]` to function configuration

### Firebase Functions V2 Key Points

1. **Secrets must be explicitly defined**: Use `defineSecret('SECRET_NAME')` from `firebase-functions/params`
2. **Functions must declare secrets**: Add `secrets: [secretVariable]` to function configuration
3. **Access secrets properly**: Use `secretVariable.value()` inside functions
4. **onDocumentWritten syntax**: Must use object configuration with `document`, `region`, and `secrets` properties

### Deployment

```bash
# Delete old functions that no longer exist
firebase functions:delete handleAppStoreNotification helloWorld startLiveActivity validateSubscriptionReceipt --force

# Deploy updated functions
firebase deploy --only functions
```

### Verification

The deployment logs now show proper secret configuration:
```json
"secretEnvironmentVariables": [{
  "key": "APNS_AUTH_KEY",
  "secret": "APNS_AUTH_KEY",
  "version": "5",
  "projectId": "growth-70a85"
}]
```

## Next Steps

Monitor the function logs to ensure Live Activity updates are working properly with the new APNs authentication key.