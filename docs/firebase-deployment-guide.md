# Firebase Functions Deployment Guide

## Current Status

Firebase Functions deployment is experiencing timeout issues during the build phase. The secrets have been successfully created in Firebase Secret Manager.

## Secrets Status

✅ Secrets created in Firebase Secret Manager:
- APP_STORE_CONNECT_KEY_ID (Version 2)
- APP_STORE_CONNECT_ISSUER_ID (Version 2)
- APP_STORE_SHARED_SECRET (Version 2)

## Deployment Issue

```
Error: User code failed to load. Cannot determine backend specification. Timeout after 10000.
```

This typically occurs when:
1. Heavy dependencies are loaded at module initialization
2. Circular dependencies exist
3. Secrets are accessed outside of function context

## Manual Deployment Steps

### Option 1: Deploy All Functions
```bash
# From project root
firebase deploy --only functions

# If timeout occurs, try increasing timeout
firebase deploy --only functions --timeout 600
```

### Option 2: Deploy Specific Functions
```bash
# Deploy subscription functions only
firebase deploy --only functions:validateSubscriptionReceipt
firebase deploy --only functions:handleAppStoreNotification
```

### Option 3: Use Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: growth-70a85
3. Navigate to Functions
4. Check deployment status

## Verifying Deployment

### Check Function Status
```bash
# List deployed functions
firebase functions:list

# View function logs
firebase functions:log --only validateSubscriptionReceipt
firebase functions:log --only handleAppStoreNotification
```

### Test Function Execution
```javascript
// Test receipt validation
const functions = firebase.functions();
const validate = functions.httpsCallable('validateSubscriptionReceipt');

try {
  const result = await validate({
    receipt: 'base64-encoded-receipt',
    isProduction: false
  });
  console.log('Validation result:', result);
} catch (error) {
  console.error('Validation error:', error);
}
```

## Alternative: Local Testing

### 1. Set Environment Variables
```bash
export APP_STORE_CONNECT_KEY_ID="2AK48N7L5J"
export APP_STORE_CONNECT_ISSUER_ID="69a6de85-a1f9-47e3-e053-5b8c7c11a4d1"
export APP_STORE_SHARED_SECRET="a0023e4976154ebe84aa547f475e20d1"
```

### 2. Run Functions Locally
```bash
# Start emulator
firebase emulators:start --only functions

# Test with shell
firebase functions:shell
```

## Troubleshooting

### 1. Check Node Version
```bash
node --version
# Should be 18 or higher for Firebase Functions v2
```

### 2. Clear Cache
```bash
cd functions
rm -rf node_modules
npm install
```

### 3. Check for Syntax Errors
```bash
cd functions
npm run lint
```

### 4. Review Function Logs
```bash
firebase functions:log
```

## Production Checklist

- [ ] Secrets configured in Firebase Secret Manager
- [ ] Functions deployed successfully
- [ ] Webhook URLs configured in App Store Connect
- [ ] Test receipt validation working
- [ ] Server notifications being received

## Support

If deployment continues to fail:
1. Check [Firebase Status](https://status.firebase.google.com/)
2. Review [Firebase Functions Documentation](https://firebase.google.com/docs/functions)
3. Use Firebase Support for critical issues

## Next Steps After Deployment

1. Test receipt validation with sandbox receipts
2. Monitor function logs for errors
3. Verify webhook notifications are received
4. Update app code to use the functions

---

Last updated: July 23, 2025
Secrets configured with shared secret: a0023e4976154ebe84aa547f475e20d1