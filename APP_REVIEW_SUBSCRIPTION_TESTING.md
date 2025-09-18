# App Review - Subscription Testing Guide

## Overview
This document provides guidance for testing in-app subscriptions during the App Store review process.

## Current Status
- **Paywalls Temporarily Disabled**: We have temporarily disabled paywall presentations (via FeatureFlags.swift) while subscriptions are being reviewed
- **Subscriptions Fully Implemented**: All subscription infrastructure is complete and ready for testing

## Subscription Products

Our app offers three subscription tiers with monthly and annual options:

### Basic Tier
- Monthly: `com.growthlabs.growthmethod.subscription.basic.monthly` - $6.99
- Annual: `com.growthlabs.growthmethod.subscription.basic.yearly` - $59.99

### Premium Tier (Most Popular)
- Monthly: `com.growthlabs.growthmethod.subscription.premium.monthly` - $9.99 (7-day free trial)
- Annual: `com.growthlabs.growthmethod.subscription.premium.yearly` - $89.99 (7-day free trial)

### Elite Tier
- Monthly: `com.growthlabs.growthmethod.subscription.elite.monthly` - $19.99 (14-day free trial)
- Annual: `com.growthlabs.growthmethod.subscription.elite.yearly` - $179.99 (14-day free trial)

## Testing Instructions

### 1. Sandbox Account Setup
1. Use a sandbox test account configured in App Store Connect
2. Sign out of production App Store account on test device
3. Sign into sandbox account when prompted during purchase

### 2. Testing Subscription Purchase
1. Once paywalls are re-enabled (FeatureFlags.paywallsEnabled = true)
2. Navigate to Settings → Subscription
3. Tap "Upgrade to Premium"
4. Select a subscription option
5. Complete purchase with sandbox account

### 3. Receipt Validation

Our app implements Apple's recommended receipt validation flow:

1. **Production First**: Always attempts production validation first
2. **Sandbox Fallback**: If production returns error 21007 (sandbox receipt), automatically retries with sandbox endpoint
3. **App Review Detection**: Special handling for App Review scenarios with enhanced error messages

### Implementation Details

#### Receipt Validation Flow (Firebase Function)
```javascript
// Always try production first
let response = await validateWithProduction(receipt);

// If sandbox receipt detected (error 21007)
if (response.status === 21007) {
    // Retry with sandbox
    response = await validateWithSandbox(receipt);
}
```

#### Client-Side Handling
- `AppReviewSubscriptionHandler.swift`: Detects App Review testing and applies appropriate fallbacks
- `StoreKitEnvironmentHandler.swift`: Automatically detects sandbox vs production environment
- Enhanced error messages for App Review scenarios

### 4. Common Issues and Solutions

#### Issue: "Subscriptions aren't available"
**Solution**: This is typically caused by:
1. Products not loading from App Store Connect
2. Sandbox account not properly configured
3. Network connectivity issues

Our app handles this with:
- Automatic retry logic (up to 3 attempts)
- Fallback to individual product loading
- Clear error messaging for users

#### Issue: "Cannot connect to iTunes Store"
**Solution**: 
- Verify sandbox account is signed in
- Check network connectivity
- App automatically retries with exponential backoff

### 5. Testing Restore Purchases
1. Make a purchase with sandbox account
2. Delete and reinstall app
3. Navigate to Settings → Subscription
4. Tap "Restore Purchases"
5. Verify subscription is restored

## Environment Detection

The app automatically detects the environment:
- **Xcode Testing**: StoreKit configuration file used
- **Sandbox**: Detected via receipt validation response
- **Production**: Default for App Store builds

## Error Handling

We provide specific error messages for App Review:
- "Subscription options are temporarily unavailable"
- "This is a known issue that should be resolved within 24 hours"
- "Please try again later or contact support"

## Support Information

If you encounter any issues during testing:
- Support Email: support@growthlabs.com
- Technical Contact: [Your contact info]

## Additional Notes

1. **Free Trial Periods**: Premium and Elite tiers include free trials (7 and 14 days respectively)
2. **Subscription Groups**: All products are in the same subscription group, allowing upgrades/downgrades
3. **Auto-Renewal**: Sandbox subscriptions auto-renew at accelerated intervals for testing
4. **Server Notifications**: We support App Store Server Notifications for real-time updates

## Verification Checklist

- [ ] Sandbox account configured in App Store Connect
- [ ] Products visible in purchase flow
- [ ] Purchase completes successfully
- [ ] Receipt validation works
- [ ] Subscription status updates correctly
- [ ] Restore purchases functions properly
- [ ] Appropriate error messages displayed

## Re-enabling Paywalls

To re-enable paywalls after subscription approval:
1. Open `Growth/Core/Configuration/FeatureFlags.swift`
2. Change `paywallsEnabled` from `false` to `true`
3. Rebuild and submit update

---

Thank you for reviewing our app. We've implemented comprehensive subscription handling following Apple's best practices and guidelines.