# App Store Webhook Error Fix

## Issue
App Store Server Notifications webhook was returning 500 errors due to:
1. Using undefined `logger` variable in `processNotification` function
2. Missing `expiresDateMs` null checks causing parseInt errors

## Fixes Applied

### 1. Logger Fix
- Changed `processNotification` to accept `enhancedLogger` parameter
- Replaced `logger` with `enhancedLogger` in processNotification function
- Other functions continue using global `logger` from firebase-functions

### 2. Missing Data Handling
- Added null checks for `expiresDateMs` before parseInt
- Changed: `new Date(parseInt(expiresDateMs))` 
- To: `expiresDateMs ? new Date(parseInt(expiresDateMs)) : null`

### 3. Function Signature Update
```javascript
// Before
async function processNotification(notification) { ... }

// After  
async function processNotification(notification, enhancedLogger) { ... }
```

## Deployment

Deploy the fixed function:
```bash
cd functions
firebase deploy --only functions:handleAppStoreNotification
```

## Testing

The webhook should now:
1. Properly log all events using enhancedLogger
2. Handle missing expiration dates gracefully
3. Return 200 OK for valid notifications
4. Return appropriate error codes (400/401/500) with proper logging

## Apple Webhook Types Handled
- SUBSCRIBED - New subscription
- DID_RENEW - Subscription renewed
- EXPIRED - Subscription expired
- DID_FAIL_TO_RENEW - Renewal failed (billing retry)
- REFUND/REVOKE - Subscription cancelled
- DID_CHANGE_RENEWAL_STATUS - Auto-renewal toggled

## Important Notes
- Apple sends test notifications periodically
- 500 errors trigger Apple's retry mechanism
- Webhook must respond within 30 seconds
- Always validate Apple's signature for security