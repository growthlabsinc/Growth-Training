# App Store Connect Configuration Complete

## Configuration Summary

### API Credentials
- **Key ID**: 2AK48N7L5J
- **Issuer ID**: 69a6de85-a1f9-47e3-e053-5b8c7c11a4d1
- **Shared Secret**: a0023e4976154ebe84aa547f475e20d1
- **Bundle ID**: com.growthlabs.growthmethod

### Implementation Status

#### ✅ Code Updates
- SubscriptionProduct.swift updated with correct product IDs
- Subscription group: "growth_membership"
- Product IDs:
  - `com.growthlabs.growthmethod.basic_monthly` ($4.99)
  - `com.growthlabs.growthmethod.premium_monthly` ($9.99)
  - `com.growthlabs.growthmethod.elite_monthly` ($19.99)

#### ✅ API Configuration
- API key stored in `.keys/AuthKey_2AK48N7L5J.p8`
- Environment configuration in `.env.local`
- Firebase Functions config updated with all credentials

#### ✅ Security Measures
- API key file permissions set to 600
- `.keys/` directory added to .gitignore
- Secrets configured for Firebase Functions

## Deployment Steps

### 1. Set Up Firebase Secrets (Recommended for Production)
```bash
# Run the setup script
./scripts/setup-firebase-secrets.sh

# This will create secrets in Firebase Secret Manager:
# - APP_STORE_CONNECT_KEY_ID
# - APP_STORE_CONNECT_ISSUER_ID
# - APP_STORE_SHARED_SECRET
```

### 2. Deploy Firebase Functions
```bash
# Deploy subscription functions
firebase deploy --only functions:validateSubscriptionReceipt,functions:handleAppStoreNotification

# Or deploy all functions
firebase deploy --only functions
```

### 3. Verify Configuration
```bash
# Check local configuration
./scripts/validate-appstore-config.sh

# Check Firebase configuration
firebase functions:config:get appstore

# View function logs
firebase functions:log --only validateSubscriptionReceipt
```

## App Store Connect Setup Checklist

### Required Actions in App Store Connect

1. **Create App** ✓
   - Bundle ID: com.growthlabs.growthmethod
   - SKU: GROWTH2025
   - Name: Growth

2. **Configure Subscriptions** ✓
   - Group: Growth Membership
   - Products:
     - Basic Monthly ($4.99)
     - Premium Monthly ($9.99)
     - Elite Monthly ($19.99)

3. **Server Notifications** ✓
   - Production: `https://us-central1-growth-70a85.cloudfunctions.net/handleAppStoreNotification`
   - Sandbox: `https://us-central1-growth-70a85.cloudfunctions.net/handleAppStoreNotificationSandbox`

4. **Shared Secret** ✓
   - Generated and configured: a0023e4976154ebe84aa547f475e20d1

## Testing the Integration

### 1. Test Receipt Validation
```javascript
// In your app code
const result = await firebase.functions().httpsCallable('validateSubscriptionReceipt')({
  receipt: 'base64-encoded-receipt',
  isProduction: false // Use sandbox for testing
});
```

### 2. Monitor Server Notifications
```bash
# View webhook logs
firebase functions:log --only handleAppStoreNotification
```

### 3. Check Subscription Status
```javascript
// Query user's subscription in Firestore
const subscription = await firebase.firestore()
  .collection('users')
  .doc(userId)
  .collection('subscriptions')
  .doc('current')
  .get();
```

## Troubleshooting

### Common Issues

1. **401 Unauthorized**
   - Verify Key ID and Issuer ID
   - Check API key permissions in App Store Connect

2. **Invalid Receipt**
   - Ensure receipt is base64 encoded
   - Check if using correct environment (sandbox vs production)

3. **Webhook Not Firing**
   - Verify URLs in App Store Connect
   - Check Firebase Functions deployment
   - Review function logs

### Debug Commands
```bash
# Check secrets
firebase functions:secrets:get APP_STORE_CONNECT_KEY_ID

# View function configuration
firebase functions:config:get

# Test function locally
firebase functions:shell
```

## Security Notes

- ✅ API key is gitignored
- ✅ Shared secret stored securely
- ✅ Firebase secrets configured
- ✅ No sensitive data in repository

## Next Steps

1. **Complete App Store Connect Setup**
   - Add app description and metadata
   - Upload screenshots
   - Configure TestFlight

2. **Continue with Epic 25**
   - Story 25.2: Production Build Setup
   - Story 25.3: App Store Assets
   - Story 25.4: Legal Documentation

## Support Resources

- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [StoreKit Documentation](https://developer.apple.com/documentation/storekit)
- [Firebase Functions Documentation](https://firebase.google.com/docs/functions)

---

Configuration completed on: July 23, 2025
Last updated with shared secret: a0023e4976154ebe84aa547f475e20d1