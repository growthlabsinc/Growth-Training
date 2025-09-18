# App Store Server Notifications Webhook Configuration

## ✅ Completed Setup

### API Credentials
- **Key ID**: `2A6PYJ67CD`
- **Issuer ID**: `87056e63-dddd-4e67-989e-e0e4950b84e5`
- **Bundle ID**: `com.growthlabs.growthmethod`
- **Shared Secret**: `a0023e4976154ebe84aa547f475e20d1`

### Functions Deployed
- ✅ `validateSubscriptionReceipt` - Receipt validation endpoint
- ✅ `handleAppStoreNotification` - Production webhook handler
- ✅ `handleAppStoreNotificationSandbox` - Sandbox webhook handler

### Product IDs Updated
All product IDs have been updated to use the correct bundle ID prefix:
- `com.growthlabs.growthmethod.subscription.basic.monthly`
- `com.growthlabs.growthmethod.subscription.basic.yearly`
- `com.growthlabs.growthmethod.subscription.premium.monthly`
- `com.growthlabs.growthmethod.subscription.premium.yearly`
- `com.growthlabs.growthmethod.subscription.elite.monthly`
- `com.growthlabs.growthmethod.subscription.elite.yearly`

## 🔔 Required: Configure Webhooks in App Store Connect

### Step 1: Access Webhook Settings
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to: **Users and Access > Integrations**
3. Click on **App Store Server Notifications**

### Step 2: Configure URLs

#### Production URL
```
https://us-central1-growth-70a85.cloudfunctions.net/handleAppStoreNotification
```

#### Sandbox URL
```
https://us-central1-growth-70a85.cloudfunctions.net/handleAppStoreNotificationSandbox
```

### Step 3: Enable Notification Types
Enable **ALL** of the following notification types:

- ☐ INITIAL_BUY
- ☐ DID_CHANGE_RENEWAL_PREF
- ☐ DID_CHANGE_RENEWAL_STATUS
- ☐ OFFER_REDEEMED
- ☐ DID_RENEW
- ☐ EXPIRED
- ☐ GRACE_PERIOD_EXPIRED
- ☐ PRICE_INCREASE
- ☐ REFUND
- ☐ REFUND_DECLINED
- ☐ RENEWAL_EXTENDED
- ☐ REVOKE
- ☐ SUBSCRIBED

### Step 4: Save Configuration
Click **Save** to activate the webhook notifications.

## 🧪 Testing the Configuration

### 1. Test Webhook Endpoints
```bash
# Test production endpoint
curl -I https://us-central1-growth-70a85.cloudfunctions.net/handleAppStoreNotification

# Test sandbox endpoint
curl -I https://us-central1-growth-70a85.cloudfunctions.net/handleAppStoreNotificationSandbox
```

Both should return `200 OK` status.

### 2. Monitor Function Logs
```bash
# Watch real-time logs
firebase functions:log --follow

# Filter for subscription functions
firebase functions:log --only validateSubscriptionReceipt,handleAppStoreNotification
```

### 3. Test with Sandbox Purchase
1. Use a sandbox tester account
2. Make a test subscription purchase in the app
3. Monitor Firebase logs for:
   - Receipt validation calls
   - Webhook notifications
   - User document updates in Firestore

## 📊 Monitoring Dashboard

View real-time metrics and logs:
- [Firebase Console](https://console.firebase.google.com/project/growth-70a85/functions)
- [Function Logs](https://console.firebase.google.com/project/growth-70a85/functions/logs)
- [Firestore Users Collection](https://console.firebase.google.com/project/growth-70a85/firestore/data/~2Fusers)

## ✅ Verification Checklist

After configuring webhooks:
- [ ] Both webhook URLs are saved in App Store Connect
- [ ] All notification types are enabled
- [ ] Made a test sandbox purchase
- [ ] Verified receipt validation in logs
- [ ] Confirmed webhook received in logs
- [ ] Checked user document updated in Firestore

## 🚨 Troubleshooting

### Webhooks Not Received
1. Verify URLs are exactly as shown (no trailing slashes)
2. Check all notification types are enabled
3. Ensure "Version 2" notifications are selected
4. Test with a real sandbox purchase (not just restore)

### Validation Errors
1. Check Firebase logs for detailed error messages
2. Verify shared secret matches App Store Connect
3. Ensure product IDs exist in App Store Connect

### Need Help?
- Check logs: `firebase functions:log`
- Review troubleshooting guide: `/docs/subscription-troubleshooting-guide.md`
- Contact: platform@growth.app

---

**Last Updated**: January 2025
**Epic 23 Status**: Implementation Complete ✅