# App Store Connect Credential Configuration Guide

## Prerequisites

Before starting, ensure you have:
1. Admin access to App Store Connect
2. Firebase CLI installed and authenticated
3. Access to the Growth Firebase project (growth-70a85)
4. The App Store Connect API private key (.p8 file)

## Step 1: Generate App Store Connect API Key

1. **Log into App Store Connect**
   - URL: https://appstoreconnect.apple.com
   - Navigate to: Users and Access > Integrations > App Store Connect API

2. **Generate API Key**
   - Click "Generate API Key" or "+"
   - Name: `Growth-Subscription-API-2025`
   - Access: **In-App Purchase** (minimum required)
   - Click "Generate"

3. **Download and Document**
   ⚠️ **CRITICAL**: Download the .p8 file immediately - you can only download it once!
   
   Document these values:
   ```
   Key ID: [Your Key ID - e.g., 66LQV834DU]
   Issuer ID: [Your Issuer ID - e.g., 69a6de89-e5bb-47e3-993b-5eaa32c47591]
   File Name: AuthKey_[YourKeyID].p8
   ```

## Step 2: Configure Local Environment

1. **Create configuration directory**
   ```bash
   cd /Users/tradeflowj/Desktop/Dev/growth-fresh/functions
   mkdir -p config keys
   ```

2. **Copy your private key**
   ```bash
   # Replace YOUR_KEY_ID with your actual key ID
   cp ~/Downloads/AuthKey_YOUR_KEY_ID.p8 ./keys/
   
   # Set secure permissions
   chmod 600 ./keys/AuthKey_*.p8
   ```

3. **Create .env file from template**
   ```bash
   cp config/.env.template config/.env
   ```

4. **Edit .env with your credentials**
   ```bash
   # Open in your editor
   nano config/.env
   ```
   
   Update with your values:
   ```
   APPSTORE_KEY_ID=YOUR_KEY_ID
   APPSTORE_ISSUER_ID=YOUR_ISSUER_ID
   APPSTORE_BUNDLE_ID=com.growth
   APPSTORE_SHARED_SECRET=YOUR_SHARED_SECRET
   ```

## Step 3: Get App-Specific Shared Secret

1. **In App Store Connect**
   - Go to My Apps > Growth
   - Navigate to: App Information > App-Specific Shared Secret
   - Click "Generate" or "Manage"
   - Copy the shared secret

2. **Update .env file**
   ```bash
   # Add the shared secret to your .env file
   APPSTORE_SHARED_SECRET=your_shared_secret_here
   ```

## Step 4: Configure Firebase Functions

1. **Run the configuration script**
   ```bash
   cd /Users/tradeflowj/Desktop/Dev/growth-fresh/functions
   ./scripts/configure-firebase.sh
   ```

2. **Verify configuration was set**
   ```bash
   firebase functions:config:get appstore
   ```
   
   Should output:
   ```json
   {
     "key_id": "YOUR_KEY_ID",
     "issuer_id": "YOUR_ISSUER_ID",
     "bundle_id": "com.growth",
     "shared_secret": "YOUR_SHARED_SECRET",
     "use_sandbox": "false"
   }
   ```

## Step 5: Validate Credentials

1. **Run validation script**
   ```bash
   cd /Users/tradeflowj/Desktop/Dev/growth-fresh/functions
   node scripts/validate-credentials.js
   ```

2. **Expected output**
   ```
   ✅ All required credentials found
   ✅ Private key file found and valid
   ✅ JWT token generated successfully
   ✅ API connection successful
   ✅ Shared secret found for webhook signature verification
   ```

## Step 6: Configure Webhooks in App Store Connect

1. **Navigate to webhook settings**
   - App Store Connect > Users and Access > Integrations
   - Click "App Store Server Notifications"

2. **Configure Production URL**
   ```
   https://us-central1-growth-70a85.cloudfunctions.net/handleAppStoreNotification
   ```

3. **Configure Sandbox URL**
   ```
   https://us-central1-growth-70a85.cloudfunctions.net/handleAppStoreNotificationSandbox
   ```

4. **Select notification types**
   Enable ALL of the following:
   - [x] INITIAL_BUY
   - [x] DID_CHANGE_RENEWAL_PREF
   - [x] DID_CHANGE_RENEWAL_STATUS
   - [x] OFFER_REDEEMED
   - [x] DID_RENEW
   - [x] EXPIRED
   - [x] GRACE_PERIOD_EXPIRED
   - [x] PRICE_INCREASE
   - [x] REFUND
   - [x] REFUND_DECLINED
   - [x] RENEWAL_EXTENDED
   - [x] REVOKE
   - [x] SUBSCRIBED

## Step 7: Deploy Functions

1. **Deploy the subscription functions**
   ```bash
   cd /Users/tradeflowj/Desktop/Dev/growth-fresh
   
   # Deploy subscription validation functions
   firebase deploy --only functions:validateSubscriptionReceipt,functions:handleAppStoreNotification,functions:handleAppStoreNotificationSandbox
   ```

2. **Verify deployment**
   ```bash
   # Check function logs
   firebase functions:log --only validateSubscriptionReceipt
   ```

## Step 8: Test the Configuration

1. **Test webhook endpoint**
   ```bash
   # This should return a 200 status
   curl -I https://us-central1-growth-70a85.cloudfunctions.net/handleAppStoreNotification
   ```

2. **Test with a sandbox purchase**
   - Use a sandbox tester account
   - Make a test purchase in the app
   - Check Firebase logs for validation

## Step 9: Monitor Initial Operations

1. **Watch real-time logs**
   ```bash
   firebase functions:log --follow
   ```

2. **Check metrics dashboard**
   - Open: https://console.firebase.google.com/project/growth-70a85/functions/logs
   - Filter by: `validateSubscriptionReceipt`

3. **Verify webhook delivery**
   - Make a test purchase
   - Check webhook logs: `handleAppStoreNotification`

## Troubleshooting

### Common Issues

**"Invalid credentials" error**
- Double-check Key ID and Issuer ID match exactly
- Ensure .p8 file is in correct location
- Verify file permissions: `ls -la functions/keys/`

**"Cannot connect to App Store" error**
- Check internet connection
- Verify API key has In-App Purchase permission
- Try regenerating the API key

**Webhooks not received**
- Verify URLs are exactly correct (no trailing slashes)
- Check Firebase Functions are deployed
- Ensure all notification types are enabled

### Emergency Rollback

If issues occur:
```bash
# Disable server validation temporarily
firebase functions:config:set appstore.emergency_mode="true"
firebase deploy --only functions:validateSubscriptionReceipt

# This allows local validation only while you fix issues
```

## Security Checklist

- [ ] Private key file has 600 permissions
- [ ] No credentials committed to git
- [ ] Shared secret is kept secure
- [ ] Access to App Store Connect is limited
- [ ] Firebase project has appropriate access controls

## Next Steps

1. Monitor metrics for 24 hours
2. Set up alerts for validation failures
3. Schedule quarterly credential rotation
4. Document any app-specific configurations

---

**Support Contact**: platform@growth.app
**Emergency Hotline**: [Your emergency contact]
**Last Updated**: January 2025