# App Store Connect Metadata for Subscription Approval

## Required Actions in App Store Connect

### 1. App Information Section
- **Privacy Policy URL**: Add `https://www.growthlabs.coach/privacy-policy`
- **License Agreement**: 
  - Option A (Recommended): Use Apple's Standard EULA (no action needed)
  - Option B: Upload custom EULA or add link to `https://www.growthlabs.coach/terms`

### 2. App Description Update
Add this text to your App Description:

```
SUBSCRIPTION INFORMATION:
• Growth Premium Weekly - $4.99/week
• Growth Premium Quarterly - $29.99/3 months (Save 40%)
• Growth Premium Annual - $49.99/year (Save 80%, includes 5-day free trial)

Payment will be charged to your iTunes Account at confirmation of purchase. Subscription automatically renews unless auto-renew is turned off at least 24-hours before the end of the current period. Your account will be charged for renewal within 24-hours prior to the end of the current period. You can manage or turn off auto-renew in your Account settings after purchase. No cancellation of the current subscription is allowed during the active subscription period.

Terms of Use: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Privacy Policy: https://www.growthlabs.coach/privacy-policy
```

### 3. Subscription Configuration
Ensure all three subscriptions are configured:

#### Weekly Subscription
- Product ID: `com.growthlabs.growthmethod.subscription.premium.weekly`
- Reference Name: Growth Pro Weekly
- Duration: 1 week
- Price: $4.99 USD
- Display Name: Growth Premium Weekly
- Description: Full access to all premium features billed weekly

#### Quarterly Subscription  
- Product ID: `com.growthlabs.growthmethod.subscription.premium.quarterly`
- Reference Name: Growth Pro Quarterly
- Duration: 3 months
- Price: $29.99 USD
- Display Name: Growth Premium (3 Months)
- Description: Full access to all premium features with 40% savings

#### Annual Subscription
- Product ID: `com.growthlabs.growthmethod.subscription.premium.yearly`
- Reference Name: Growth Pro Annual
- Duration: 1 year
- Price: $49.99 USD
- Display Name: Growth Premium Annual
- Description: Full access to all premium features with 80% savings
- **Introductory Offer**: 5-day free trial (configure this separately)

### 4. Submit Subscriptions with App
When submitting your app:
1. Go to the app version page
2. Scroll to "In-App Purchases and Subscriptions" section
3. Click the "+" button
4. Add all three subscriptions
5. Submit them together with your app version

### 5. App Review Information
Add this note to reviewers:

```
The subscription products are newly created and pending review along with this app submission. 
The app includes proper error handling for cases where products are not yet available.

Terms of Use: Using Apple's Standard EULA
Privacy Policy: https://www.growthlabs.coach/privacy-policy

All subscription information including pricing, duration, and auto-renewal details are displayed 
in the app's paywall before purchase.
```

## Website Requirements

Make sure your website has these pages:
- `https://www.growthlabs.coach/privacy-policy` - Privacy Policy  
- `https://www.growthlabs.coach/terms` - Terms of Service (optional if using Apple's EULA)

## Changes Made to App Code

1. **Added LegalURLs.swift** - Central location for all legal document URLs
2. **Updated PaywallView.swift** - Terms and Privacy buttons now open web links
3. **Enhanced error handling** - Better messages when subscriptions aren't available
4. **Subscription info display** - All required subscription details are shown in-app

## Testing Checklist

Before resubmitting:
- [ ] Privacy Policy URL works and displays content
- [ ] Terms of Use URL works (or using Apple's standard)
- [ ] All three subscriptions are in "Waiting for Review" or "Ready to Submit"
- [ ] App Description includes subscription information
- [ ] Subscription details are displayed in the app's paywall
- [ ] Error handling works when products don't load