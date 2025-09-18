# Subscription System Troubleshooting Guide

## Table of Contents
1. [Common Issues](#common-issues)
2. [Credential Problems](#credential-problems)
3. [Receipt Validation Errors](#receipt-validation-errors)
4. [Webhook Issues](#webhook-issues)
5. [Performance Problems](#performance-problems)
6. [Emergency Procedures](#emergency-procedures)

## Common Issues

### Issue: User Cannot Purchase Subscription
**Symptoms:**
- Purchase button disabled or unresponsive
- "Cannot connect to App Store" error
- Purchase fails immediately

**Resolution Steps:**
1. Check StoreKit service status:
   ```swift
   // In app console
   print(StoreKitService.shared.isAvailable)
   ```

2. Verify product IDs match App Store Connect:
   ```bash
   firebase functions:config:get appstore
   ```

3. Check user's device restrictions:
   - Settings > Screen Time > Content & Privacy Restrictions
   - In-App Purchases must be allowed

4. Test with sandbox account:
   - Sign out of production App Store account
   - Use test account from App Store Connect

### Issue: Subscription Not Recognized After Purchase
**Symptoms:**
- Purchase completes but features remain locked
- User charged but no access granted

**Resolution Steps:**
1. Force refresh subscription state:
   ```swift
   await SubscriptionStateManager.shared.forceRefresh()
   ```

2. Check Firebase logs:
   ```bash
   firebase functions:log --only validateSubscriptionReceipt
   ```

3. Verify webhook processing:
   - Check Firestore `users/{userId}` document
   - Look for `lastValidated` timestamp

4. Manual receipt validation:
   ```bash
   cd functions
   node scripts/validate-credentials.js
   ```

## Credential Problems

### Issue: "Invalid Credentials" Error
**Symptoms:**
- Receipt validation returns 401 Unauthorized
- JWT generation fails

**Resolution Steps:**
1. Verify credential configuration:
   ```bash
   firebase functions:config:get appstore
   ```

2. Check private key file:
   ```bash
   ls -la functions/keys/AuthKey_*.p8
   # Should show your .p8 file with proper permissions
   ```

3. Validate JWT generation:
   ```javascript
   // Test JWT generation
   cd functions
   node -e "require('./scripts/validate-credentials.js')"
   ```

4. Regenerate credentials if needed:
   - App Store Connect > Users and Access > Keys
   - Generate new key (one-time download)
   - Update Firebase config

### Issue: "Key Not Found" Error
**Symptoms:**
- Firebase Functions cannot find private key
- "ENOENT" errors in logs

**Resolution Steps:**
1. Check key file location:
   ```bash
   # Expected location
   functions/keys/AuthKey_YOUR_KEY_ID.p8
   ```

2. Verify Firebase Storage upload (if using):
   ```bash
   gsutil ls gs://growth-70a85.appspot.com/keys/
   ```

3. Update key path in config:
   ```bash
   firebase functions:config:set appstore.key_path="./keys/AuthKey_NEW_KEY_ID.p8"
   ```

## Receipt Validation Errors

### Error Code Reference
| Code | Meaning | Resolution |
|------|---------|------------|
| 21000 | Bad JSON | Check receipt data format |
| 21002 | Malformed receipt | Ensure base64 encoding |
| 21003 | Authentication failed | Verify receipt authenticity |
| 21004 | Wrong shared secret | Update webhook secret |
| 21005 | Server unavailable | Retry with backoff |
| 21006 | Subscription expired | Normal - update state |
| 21007 | Sandbox receipt to prod | Use sandbox endpoint |
| 21008 | Prod receipt to sandbox | Use production endpoint |

### Issue: Validation Always Fails
**Resolution Steps:**
1. Check environment mismatch:
   ```javascript
   // In Firebase config
   firebase functions:config:get appstore.use_sandbox
   // Should match your testing environment
   ```

2. Verify shared secret:
   ```bash
   firebase functions:config:get appstore.shared_secret
   ```

3. Test with curl:
   ```bash
   curl -X POST https://us-central1-growth-70a85.cloudfunctions.net/validateSubscriptionReceipt \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer YOUR_ID_TOKEN" \
     -d '{"receiptData":"BASE64_RECEIPT"}'
   ```

## Webhook Issues

### Issue: Webhooks Not Received
**Symptoms:**
- Subscription changes not reflected
- No webhook logs in Firebase

**Resolution Steps:**
1. Verify webhook URLs in App Store Connect:
   - Production: `https://us-central1-growth-70a85.cloudfunctions.net/handleAppStoreNotification`
   - Sandbox: `https://us-central1-growth-70a85.cloudfunctions.net/handleAppStoreNotificationSandbox`

2. Check notification types enabled:
   - All subscription event types should be checked

3. Test webhook endpoint:
   ```bash
   curl -X POST YOUR_WEBHOOK_URL \
     -H "Content-Type: application/json" \
     -d '{"signedPayload":"test"}'
   ```

4. Monitor webhook logs:
   ```bash
   firebase functions:log --only handleAppStoreNotification
   ```

### Issue: Webhook Signature Verification Fails
**Resolution Steps:**
1. Verify shared secret matches App Store Connect
2. Check signature verification code:
   ```javascript
   // In webhook handler
   const isValid = verifyWebhookSignature(payload, signature, sharedSecret);
   ```

## Performance Problems

### Issue: Slow Receipt Validation
**Symptoms:**
- Validation takes > 5 seconds
- Timeouts during purchase flow

**Resolution Steps:**
1. Check cache hit rate:
   ```javascript
   // Monitor cache performance
   SELECT COUNT(*) FROM subscriptionCache WHERE expiresAt > NOW()
   ```

2. Optimize Firebase Functions:
   ```bash
   # Increase memory allocation
   firebase functions:config:set runtime.memory="512MB"
   ```

3. Enable connection pooling:
   ```javascript
   // In Firebase Functions
   const https = require('https');
   https.globalAgent.keepAlive = true;
   ```

### Issue: High Error Rate
**Symptoms:**
- > 5% validation failures
- Circuit breaker activating

**Resolution Steps:**
1. Check error patterns:
   ```sql
   SELECT errorMessage, COUNT(*) 
   FROM subscriptionValidationLogs 
   WHERE status = 'error' 
   GROUP BY errorMessage
   ```

2. Monitor Apple system status:
   - https://developer.apple.com/system-status/

3. Implement retry logic:
   ```javascript
   // Already implemented in SubscriptionServerValidator
   // Check retry configuration
   ```

## Emergency Procedures

### Complete Service Outage
1. **Immediate Actions:**
   - Enable local-only validation mode
   - Notify stakeholders via Slack
   - Check Firebase status page

2. **Fallback to Local Validation:**
   ```javascript
   // In SubscriptionStateManager
   isServerValidationEnabled = false
   ```

3. **Communication Template:**
   ```
   URGENT: Subscription Service Disruption
   Status: Investigating
   Impact: New purchases may be delayed
   Workaround: Local validation active
   ETA: Updates every 30 minutes
   ```

### Credential Compromise
1. **Immediate Actions:**
   - Revoke compromised key in App Store Connect
   - Generate new credentials
   - Update Firebase configuration

2. **Rotation Steps:**
   ```bash
   # 1. Generate new key in App Store Connect
   # 2. Download new .p8 file
   # 3. Update Firebase
   firebase functions:config:set appstore.key_id="NEW_KEY_ID"
   # 4. Deploy functions
   firebase deploy --only functions
   ```

### Mass Validation Failures
1. **Diagnosis:**
   ```bash
   # Check recent error rate
   firebase functions:log --only validateSubscriptionReceipt --lines=100 | grep ERROR
   ```

2. **Mitigation:**
   - Increase cache duration temporarily
   - Enable generous grace period
   - Monitor recovery

## Quick Reference Commands

### Debug Commands
```bash
# View current configuration
firebase functions:config:get

# Check function logs
firebase functions:log --only validateSubscriptionReceipt

# Test webhook endpoint
curl -X POST https://us-central1-growth-70a85.cloudfunctions.net/test

# Validate credentials
cd functions && node scripts/validate-credentials.js
```

### Recovery Commands
```bash
# Clear validation cache
firebase firestore:delete subscriptionCache --recursive

# Force redeployment
firebase deploy --only functions --force

# Reset circuit breaker
firebase functions:config:unset circuitbreaker && firebase deploy --only functions
```

## Support Escalation

### Level 1: Engineering Team
- Slack: #subscription-alerts
- On-call: Check PagerDuty

### Level 2: Platform Team
- Email: platform@growth.app
- Response time: 1 hour

### Level 3: Apple Developer Support
- Portal: https://developer.apple.com/contact/
- Phone: 1-800-633-2152
- Have Team ID ready

## Monitoring Links

- [Firebase Console](https://console.firebase.google.com/project/growth-70a85)
- [App Store Connect](https://appstoreconnect.apple.com)
- [Subscription Dashboard](https://growth.app/admin/subscriptions)
- [Error Tracking](https://console.firebase.google.com/project/growth-70a85/crashlytics)

---

**Last Updated:** January 2025
**Document Version:** 1.0
**Next Review:** February 2025