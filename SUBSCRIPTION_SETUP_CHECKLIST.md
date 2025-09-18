# Subscription Setup Checklist for App Store Connect

## Current Issue
TestFlight users are getting "Subscription options are not available" error when trying to purchase.

## Product IDs in Code
The app expects these exact product IDs:
- `com.growthlabs.growthmethod.subscription.premium.weekly` - $4.99/week
- `com.growthlabs.growthmethod.subscription.premium.quarterly` - $29.99/3 months (40% savings)
- `com.growthlabs.growthmethod.subscription.premium.yearly` - $49.99/year (80% savings, includes 5-day trial)

## App Store Connect Configuration Checklist

### 1. Verify Product IDs Match Exactly
- [ ] Go to App Store Connect → Your App → Subscriptions
- [ ] Check that ALL three product IDs match EXACTLY (case-sensitive):
  - `com.growthlabs.growthmethod.subscription.premium.weekly`
  - `com.growthlabs.growthmethod.subscription.premium.quarterly`
  - `com.growthlabs.growthmethod.subscription.premium.yearly`

### 2. Subscription Group Setup
- [ ] All three subscriptions should be in the SAME subscription group
- [ ] The subscription group should be named something like "Growth Premium"
- [ ] Subscription group should be Active

### 3. Individual Product Configuration
For EACH subscription product:
- [ ] Status is "Ready to Submit" or "Approved"
- [ ] Pricing is configured correctly:
  - Weekly: $4.99 USD
  - Quarterly: $29.99 USD
  - Yearly: $49.99 USD
- [ ] Localization is set (at least English)
- [ ] Display name is configured
- [ ] Description is configured

### 4. Free Trial Configuration (Yearly Only)
- [ ] The yearly subscription has an Introductory Offer configured:
  - Type: Free Trial
  - Duration: 5 days
  - Countries: All territories or at least your testing regions

### 5. TestFlight Configuration
- [ ] The build uploaded to TestFlight includes the subscription entitlements
- [ ] In-App Purchases are enabled for the TestFlight build
- [ ] The app's Capabilities in Xcode include "In-App Purchase"

### 6. App Information
- [ ] Go to App Store Connect → Your App → App Information
- [ ] Verify Bundle ID matches: `com.growthlabs.growthmethod`

### 7. Agreements
- [ ] Go to App Store Connect → Agreements, Tax, and Banking
- [ ] Verify "Paid Applications" agreement is Active
- [ ] Banking and tax information is complete

### 8. Sandbox Testing
- [ ] Add TestFlight testers' Apple IDs to Sandbox testers (if needed)
- [ ] Users → Sandbox Testers → Add tester emails

## Common Issues and Solutions

### Issue: Products not loading in TestFlight
**Solution**: 
1. Wait 24-48 hours after creating products (App Store Connect propagation delay)
2. Ensure all products are in "Ready to Submit" state
3. Submit the app for review with IAPs included

### Issue: Product IDs don't match
**Solution**: 
Either update the code to match App Store Connect OR update App Store Connect to match the code.
The product IDs MUST match exactly, including case.

### Issue: Subscription group not configured
**Solution**: 
Create a subscription group and add all products to it. This enables upgrade/downgrade between tiers.

## Testing on Device

### For TestFlight Testing:
1. Install TestFlight app on device
2. Accept the beta invitation
3. Install the app from TestFlight
4. Try to purchase - real charges won't occur in TestFlight

### For Development Testing:
1. Use a Sandbox Apple ID (not your real Apple ID)
2. Sign out of App Store on device
3. Run app from Xcode
4. When prompted to sign in during purchase, use Sandbox account

## Quick Fix if Products Still Don't Load

If products still don't load after verifying everything above, the issue might be timing. 
App Store Connect can take 24-48 hours to propagate new products. 

As a temporary workaround for Apple review, you could:
1. Add a fallback that shows static pricing if products don't load
2. Implement a "retry" mechanism that attempts to reload products
3. Add better error messaging explaining the temporary issue

## Contact Apple Developer Support
If all above items are verified and products still don't load after 48 hours, contact Apple Developer Support with:
- Your app's Apple ID
- The exact product IDs
- Screenshots of your App Store Connect configuration
- Device logs showing the StoreKit errors