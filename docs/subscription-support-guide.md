# Subscription Support Team Guide

## Quick Reference

**Common Issues & Solutions**
- [Cannot Purchase](#cannot-purchase) - Device restrictions, payment methods
- [Purchase Not Recognized](#purchase-not-recognized) - Refresh state, restore purchases  
- [Cannot Access Premium Features](#cannot-access-premium-features) - Verify subscription status
- [Billing Questions](#billing-questions) - Refunds, changes, cancellations
- [Technical Issues](#technical-issues) - App crashes, sync problems

**Subscription Tiers**
- **Basic**: $4.99/mo or $49.99/yr - All methods, enhanced tracking
- **Premium**: $9.99/mo or $99.99/yr - Includes AI Coach
- **Elite**: $19.99/mo or $199.99/yr - Personal coaching, priority support

## Support Tier Response Times

| Issue Priority | Basic | Premium | Elite |
|---------------|-------|---------|-------|
| Critical | 48h | 24h | 4h |
| High | 72h | 48h | 24h |
| Normal | 5 days | 72h | 48h |
| Low | 7 days | 5 days | 72h |

## Common Support Scenarios

### Cannot Purchase

**User Says:** "I can't buy a subscription" / "Purchase button doesn't work"

**Diagnostic Questions:**
1. What happens when you tap the purchase button?
2. Do you see an error message?
3. Are you signed into the App Store?
4. Have you purchased from this device before?

**Solutions:**

✅ **Check Device Restrictions**
```
Ask user to check:
Settings > Screen Time > Content & Privacy Restrictions > iTunes & App Store Purchases > In-app Purchases

Should be set to "Allow"
```

✅ **Verify Payment Method**
```
Direct user to:
Settings > [Apple ID] > Payment & Shipping

Ensure valid payment method is present
```

✅ **Sign Out/In App Store**
```
1. Settings > [Apple ID] > Media & Purchases
2. Sign Out
3. Restart device
4. Sign back in
5. Try purchase again
```

✅ **Network Issues**
```
1. Check WiFi/cellular connection
2. Try on different network
3. Reset network settings if needed
```

**Escalation Trigger:** If none of above work, escalate to Technical Team

### Purchase Not Recognized

**User Says:** "I paid but don't have premium" / "Subscription disappeared"

**Diagnostic Questions:**
1. When did you purchase?
2. Do you have the receipt email from Apple?
3. Did the payment process complete?
4. Are you signed in with the same Apple ID?

**Solutions:**

✅ **Restore Purchases**
```
In Growth app:
1. Go to Settings > Subscription
2. Tap "Restore Purchases"
3. Enter Apple ID password if prompted
4. Wait for confirmation
```

✅ **Force Refresh**
```
In Growth app:
1. Settings > Advanced > Debug
2. Tap "Force Refresh Subscription"
3. Restart app
```

✅ **Check Apple ID**
```
Ensure user is signed in with the Apple ID that made the purchase:
Settings > [Apple ID] - Check email address
```

✅ **Verify with Receipt**
```
If user has Apple receipt:
1. Note Transaction ID
2. Check our admin panel for user
3. Manually verify if needed
```

**Escalation Path:** Include Transaction ID and user email

### Cannot Access Premium Features

**User Says:** "AI Coach not working" / "Features still locked"

**Check Subscription Status:**
```
Admin Panel > Users > [Search by email]
Check:
- Current Tier
- Expiration Date
- Last Validated
```

**Solutions:**

✅ **Verify Correct Tier**
```
Basic tier does NOT include:
- AI Coach
- Personal Coaching
- Advanced Analytics

User may need to upgrade
```

✅ **App Version Check**
```
Ensure user has latest version:
1. App Store > Updates
2. Update Growth app if available
3. Restart app after update
```

✅ **Re-authenticate**
```
1. Settings > Account > Sign Out
2. Close app completely
3. Open app and sign in again
4. Check feature access
```

### Billing Questions

#### How to Cancel Subscription

**iOS Instructions:**
```
1. Settings > [Apple ID] > Subscriptions
2. Tap "Growth"
3. Tap "Cancel Subscription"
4. Confirm cancellation

Note: Access continues until end of billing period
```

**Important Notes:**
- We cannot cancel on user's behalf
- Refunds must go through Apple
- Cancellation is immediate but access continues until period ends

#### How to Change Subscription Tier

**Upgrade:**
```
1. Growth app > Settings > Subscription
2. Choose new tier
3. Tap "Upgrade"
4. Confirm with Apple ID
```

**Downgrade:**
```
1. Cancel current subscription (see above)
2. Let it expire
3. Purchase new tier
OR
1. Contact Apple Support for immediate change
```

#### Refund Requests

**Apple's Refund Policy:**
- Within 14 days: Usually approved
- After 14 days: Case by case
- Multiple refunds: May be denied

**Direct User to:**
```
https://reportaproblem.apple.com
1. Sign in with Apple ID
2. Find Growth subscription
3. Report a Problem
4. Select reason and submit
```

**Our Policy:** We don't process refunds directly - all through Apple

### Family Sharing

**Setup Instructions:**
```
Organizer:
1. Settings > [Apple ID] > Subscriptions
2. Tap Growth subscription
3. Tap "Share with Family"

Family Members:
1. Should see Growth as "Shared"
2. Download app
3. Premium features auto-unlock
```

**Limitations:**
- Only organizer's subscription tier applies
- Personal coaching sessions not shared
- AI Coach history is separate per user

## Technical Troubleshooting

### Subscription Not Syncing

**Solutions:**
1. Check internet connection
2. Sign out/in of Growth account
3. Delete and reinstall app
4. Check if user has multiple Apple IDs

### App Crashes on Purchase

**Gather Info:**
- iOS version
- Device model
- When crash occurs
- Error messages

**Immediate Fix:**
1. Force quit app
2. Restart device
3. Try purchase again

**Escalate with:** Crash logs from Settings > Privacy > Analytics

### "Cannot Connect to App Store"

**Common Fixes:**
1. Check date/time settings (must be automatic)
2. Sign out of App Store and back in
3. Reset network settings
4. Try on WiFi instead of cellular

## Admin Panel Tasks

### Looking Up User Subscription
```
1. Admin Panel > Users
2. Search by email or user ID
3. Check "Subscription" section:
   - Current Tier
   - Status (Active/Expired/Trial)
   - Expiration Date
   - Transaction History
```

### Manual Subscription Sync
```
1. Find user in admin panel
2. Actions > Force Sync Subscription
3. Wait for confirmation
4. Ask user to restart app
```

### Viewing Transaction Logs
```
1. Admin Panel > Logs > Subscriptions
2. Filter by user ID
3. Look for:
   - Validation attempts
   - Error messages
   - Webhook updates
```

## Response Templates

### Cannot Purchase Template
```
Hi [Name],

I understand you're having trouble purchasing a subscription. Let's fix this!

Please try these steps:
1. Go to Settings > Screen Time > Content & Privacy Restrictions
2. Make sure In-app Purchases are set to "Allow"
3. Restart your device
4. Try the purchase again

If this doesn't work, please let me know:
- What error message you see (if any)
- Your iOS version
- Whether you've purchased from this device before

We'll get this sorted out quickly!

Best regards,
[Your name]
```

### Subscription Not Recognized Template
```
Hi [Name],

I see you've purchased a subscription but it's not showing up. Let's restore it:

1. Open Growth app
2. Go to Settings > Subscription
3. Tap "Restore Purchases"
4. Enter your Apple ID password if asked

This should recognize your purchase immediately. Make sure you're using the same Apple ID that made the purchase.

If this doesn't work, please send me:
- Your Apple receipt (check email)
- The email used for your Apple ID

I'll investigate further!

Best regards,
[Your name]
```

### Refund Request Template
```
Hi [Name],

I understand you'd like a refund. Since purchases are processed by Apple, you'll need to request this through them:

1. Visit https://reportaproblem.apple.com
2. Sign in with your Apple ID
3. Find your Growth subscription
4. Click "Report a Problem"
5. Choose your reason and submit

Apple typically responds within 48 hours. Refunds within 14 days are usually approved.

Is there anything about the app I can help with that might change your mind?

Best regards,
[Your name]
```

## Escalation Guide

### When to Escalate

**To Technical Team:**
- Purchase fails after all troubleshooting
- Subscription state inconsistencies
- App crashes during purchase flow
- Webhook processing errors

**To Finance Team:**
- Disputed charges
- Business account questions
- Revenue recognition issues

**To Legal Team:**
- Threats of legal action
- Compliance questions
- Privacy concerns

**To Product Team:**
- Feature requests
- Significant UX issues
- Patterns of user confusion

### Escalation Format
```
Subject: [ESCALATION] Subscription Issue - [User Email]

Priority: [High/Medium/Low]
User: [Email]
Tier: [Current subscription tier]
Issue: [Brief description]

Timeline:
- [Date]: User first contacted
- [Date]: Troubleshooting attempted
- [Date]: Current status

What We've Tried:
1. [Action taken]
2. [Action taken]

Technical Details:
- User ID: [from admin panel]
- Transaction ID: [if available]
- Error Messages: [exact text]

Requested Action:
[What you need from the escalation team]

[Your name]
[Timestamp]
```

## Resources

### Internal Tools
- Admin Panel: https://growth.app/admin
- Subscription Dashboard: https://growth.app/admin/subscriptions
- User Lookup: https://growth.app/admin/users
- Transaction Logs: https://growth.app/admin/logs

### External Resources
- Apple Subscription Guidelines: https://developer.apple.com/subscriptions/
- App Store Support: https://getsupport.apple.com
- System Status: https://developer.apple.com/system-status/

### Quick Links
- Our Refund Policy: https://growth.app/legal/refunds
- Terms of Service: https://growth.app/legal/terms
- Privacy Policy: https://growth.app/legal/privacy
- FAQ: https://growth.app/support/faq

## Best Practices

### Do's
✅ Always verify user's subscription tier before troubleshooting
✅ Check admin panel for user status
✅ Be empathetic - subscription issues involve money
✅ Document all troubleshooting steps
✅ Follow up within 24 hours
✅ Escalate if unsure

### Don'ts
❌ Never share user subscription details publicly
❌ Don't process refunds directly (Apple only)
❌ Avoid technical jargon with users
❌ Don't promise features not in their tier
❌ Never share internal tools/passwords

## Monthly Metrics to Track

- Average resolution time by tier
- Most common issues
- Escalation rate
- Customer satisfaction scores
- Refund request reasons
- Feature confusion patterns

---

**Last Updated:** January 2025
**Version:** 1.0
**Next Training:** February 2025
**Contact:** support-team@growth.app