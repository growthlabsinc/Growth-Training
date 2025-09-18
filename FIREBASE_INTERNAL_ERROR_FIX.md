# Firebase Functions INTERNAL Error - Diagnosis & Fix

## Error
```
Failed to send push update: FunctionsError(code: FirebaseFunctions.FunctionsErrorCode, errorUserInfo: ["NSLocalizedDescription": "INTERNAL"])
```

## Common Causes

### 1. Function Not Deployed
The Firebase function might not be properly deployed due to HTTP 409 errors.

**Solution:**
```bash
# Wait for any pending operations to complete, then retry
firebase deploy --only functions:updateLiveActivity
```

### 2. Missing Secrets/Environment Variables
The function requires APNs credentials stored as secrets:
- `APNS_AUTH_KEY_55LZB28UY2` (Development)
- `APNS_AUTH_KEY_DQ46FN4PQU` (Production)
- `APNS_TEAM_ID`
- `APNS_TOPIC`

**Check secrets:**
```bash
firebase functions:secrets:list
```

**Set missing secrets:**
```bash
# Set APNs Team ID
firebase functions:secrets:set APNS_TEAM_ID

# Set APNs Topic (Bundle ID)
firebase functions:secrets:set APNS_TOPIC

# Set APNs Auth Keys (paste the .p8 file contents)
firebase functions:secrets:set APNS_AUTH_KEY_DQ46FN4PQU
firebase functions:secrets:set APNS_AUTH_KEY_55LZB28UY2
```

### 3. App Check Validation Issues
Even though `consumeAppCheckToken: false` is set, App Check might still be interfering.

**Solution:**
1. Ensure debug token is registered in Firebase Console
2. Or temporarily disable App Check enforcement for this function

### 4. Authentication Issues
The function requires authentication but might not be receiving valid auth tokens.

**Debug in iOS app:**
```swift
// In LiveActivityManager.swift, add logging
print("📤 Calling updateLiveActivity with auth: \(Auth.auth().currentUser != nil)")
```

## Quick Fix Steps

### Step 1: Check Function Status
```bash
# Check if function is deployed
firebase functions:list | grep updateLiveActivity

# Check function logs
firebase functions:log --only updateLiveActivity --lines 50
```

### Step 2: Verify Secrets
```bash
# List all secrets
firebase functions:secrets:list

# Verify each secret is set
firebase functions:secrets:access APNS_TEAM_ID
firebase functions:secrets:access APNS_TOPIC
```

### Step 3: Force Redeploy
```bash
# Delete and redeploy the function
firebase functions:delete updateLiveActivity --force
firebase deploy --only functions:updateLiveActivity
```

### Step 4: Test Directly
Create a test script to call the function directly:

```javascript
// test-update-live-activity.js
const admin = require('firebase-admin');
const { getFunctions, httpsCallable } = require('firebase-functions');

admin.initializeApp();

async function testUpdateLiveActivity() {
    const functions = getFunctions();
    const updateLiveActivity = httpsCallable(functions, 'updateLiveActivity');
    
    try {
        const result = await updateLiveActivity({
            activityId: 'test-activity',
            contentState: {
                startedAt: new Date().toISOString(),
                pausedAt: null,
                duration: 300,
                methodName: 'Test Timer',
                sessionType: 'countdown'
            },
            pushToken: 'test-token'
        });
        console.log('Success:', result);
    } catch (error) {
        console.error('Error:', error);
    }
}

testUpdateLiveActivity();
```

## Temporary Workaround

If the Firebase function continues to fail, you can temporarily bypass it:

1. **Disable push updates** - Live Activity will still work with local updates only
2. **Use simplified function** - Deploy the simplified version:
   ```bash
   firebase deploy --only functions:updateLiveActivitySimplified
   ```

## Root Cause

The INTERNAL error typically means:
1. Function initialization failed (missing secrets)
2. Function timed out during initialization
3. Unhandled exception in the function code
4. Authentication/authorization failure

## Next Steps

1. **Check logs in Firebase Console**
   - Go to Firebase Console → Functions → Logs
   - Filter by `updateLiveActivity`
   - Look for initialization errors

2. **Verify all secrets are properly set**
   - All APNs credentials must be valid
   - Bundle ID must match

3. **Test with minimal payload**
   - Remove unnecessary fields from contentState
   - Test with hardcoded values first

4. **Consider using the simplified function**
   - Less complex initialization
   - Fewer dependencies
   - More reliable for basic updates