# App Store Connect Webhook Configuration

## Overview

Webhooks are essential for real-time subscription status updates. This guide covers configuring App Store Server Notifications V2 webhooks in App Store Connect.

## Prerequisites

- [x] App Store Connect Admin or App Manager role
- [x] Firebase Functions deployed (`handleAppStoreNotification`)
- [x] Production Firebase project configured
- [x] Shared secret configured in Firebase

## Webhook URL

Your production webhook URL is:
```
https://us-central1-growth-70a85.cloudfunctions.net/handleAppStoreNotification
```

## Configuration Steps

### 1. Sign in to App Store Connect
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Sign in with your Apple Developer account
3. Navigate to your app

### 2. Configure App Store Server Notifications

1. **Navigate to App Information**
   - Select your app
   - Click on "App Information" in the sidebar

2. **Scroll to "App Store Server Notifications"**
   - Find the section near the bottom of the page

3. **Configure Production Server URL**
   - Click "Edit" next to "Production Server URL"
   - Enter: `https://us-central1-growth-70a85.cloudfunctions.net/handleAppStoreNotification`
   - Click "Save"

4. **Configure Sandbox Server URL** (Optional but recommended)
   - Click "Edit" next to "Sandbox Server URL"
   - Enter the same URL (your function handles both environments)
   - Click "Save"

5. **Select Notification Version**
   - Choose "Version 2" (recommended)
   - Version 2 provides more detailed information and better structure

### 3. Select Notification Types

Enable all relevant notifications for comprehensive subscription tracking:

#### Essential Notifications
- [x] **INITIAL_BUY** - First subscription purchase
- [x] **DID_RENEW** - Successful renewal
- [x] **DID_FAIL_TO_RENEW** - Renewal failure
- [x] **EXPIRED** - Subscription expired
- [x] **REFUND** - Refund processed

#### Important Notifications
- [x] **DID_CHANGE_RENEWAL_STATUS** - Auto-renewal toggled
- [x] **DID_CHANGE_RENEWAL_PREF** - Plan change scheduled
- [x] **SUBSCRIBED** - Resubscribe after expiration
- [x] **GRACE_PERIOD_EXPIRED** - Billing retry period ended

#### Additional Notifications
- [x] **OFFER_REDEEMED** - Promotional offer used
- [x] **PRICE_INCREASE_CONSENT** - User accepted price increase
- [x] **REFUND_DECLINED** - Refund request denied
- [x] **RENEWAL_EXTENDED** - Renewal date extended
- [x] **REVOKE** - Family sharing access revoked
- [x] **TEST** - Test notification

### 4. Verify Shared Secret

The shared secret is already configured in Firebase:
```
APP_STORE_SHARED_SECRET=a0023e4976154ebe84aa547f475e20d1
```

This is used to verify webhook authenticity.

## Testing the Webhook

### 1. Send Test Notification
1. In App Store Connect, click "Send Test Notification"
2. Monitor Firebase Functions logs:
   ```bash
   firebase functions:log --only handleAppStoreNotification
   ```
3. Verify successful receipt (should see 200 OK)

### 2. Expected Log Output
```
✅ Received App Store Server Notification
- Type: TEST
- Environment: Production
- Bundle ID: com.growthlabs.growthmethod
✅ Notification processed successfully
```

### 3. Troubleshooting

If test fails, check:
1. **Function URL is correct** - No typos, correct project ID
2. **Function is deployed** - Run `firebase deploy --only functions:handleAppStoreNotification`
3. **Shared secret matches** - Verify in Firebase config
4. **Function has proper error handling** - Check logs for errors

## Notification Flow

1. **User Action** → Subscription purchase/change in app
2. **App Store** → Processes transaction
3. **Webhook Triggered** → Sends notification to your URL
4. **Firebase Function** → Receives and validates notification
5. **Database Update** → Updates user subscription status
6. **App Response** → Updates UI based on new status

## Security Considerations

1. **HTTPS Required** - Webhook URL must use HTTPS
2. **Shared Secret** - Validates notifications are from Apple
3. **Request Validation** - Function verifies signature
4. **Idempotency** - Handle duplicate notifications gracefully

## Monitoring

### Firebase Console
Monitor webhook activity:
```bash
# View recent function invocations
firebase functions:log --only handleAppStoreNotification -n 50

# View specific time range
firebase functions:log --only handleAppStoreNotification --since "2 hours ago"
```

### Metrics to Track
- Webhook success rate
- Processing time
- Error frequency
- Notification types received

## Common Issues

### 1. 404 Not Found
- Verify function is deployed
- Check URL for typos
- Ensure correct Firebase project

### 2. 401 Unauthorized
- Shared secret mismatch
- Check Firebase config

### 3. 500 Internal Error
- Check function logs
- Verify database permissions
- Review error handling

### 4. No Notifications Received
- Verify URL saved in App Store Connect
- Check notification types selected
- Test with sandbox purchases

## Checklist

- [ ] Production webhook URL configured
- [ ] Sandbox webhook URL configured (optional)
- [ ] Version 2 notifications selected
- [ ] All relevant notification types enabled
- [ ] Test notification successful
- [ ] Function logs show activity
- [ ] Shared secret verified
- [ ] Error handling tested

## Next Steps

1. **Test with Sandbox**
   - Make test purchase
   - Verify webhook fires
   - Check database updates

2. **Monitor Production**
   - Set up alerts for failures
   - Track webhook metrics
   - Regular log reviews

3. **Document Issues**
   - Keep log of any problems
   - Document solutions
   - Update this guide as needed

The webhook configuration enables real-time subscription tracking for a seamless user experience!