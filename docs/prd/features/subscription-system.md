# Subscription System - Feature Specification
<!-- Powered by BMAD™ Core -->

## Feature Overview

The Subscription System manages monetization through a freemium model with in-app purchases, featuring a 3-day trial, multiple subscription tiers, and sophisticated entitlement management.

## User Stories

### As a user, I want to:
1. Try the app for free before subscribing
2. Choose a subscription plan that fits my budget
3. Manage my subscription easily
4. Access premium features immediately after purchase
5. Restore purchases on new devices

## Functional Requirements

### Trial System

#### 3-Day Free Trial
- **Activation**: Automatic on first app launch
- **Duration**: 72 hours from first launch
- **Access Level**: Full premium features
- **Daily Limits During Trial**:
  - AI Coach: 3 interactions per day
  - Guided Sessions: 2 per day
  - Timer: Unlimited duration
- **Expiration Handling**: Graceful downgrade to free tier

#### Trial Tracking
```swift
enum TrialStatus {
    case checking
    case active(daysRemaining: Int)
    case expired
    case notEligible
    case disabled  // Remote config override
    case error(String)
}
```

### Subscription Tiers

#### 1. Free Tier (Post-Trial)
- **Timer Limit**: 5 minutes per session
- **Growth Methods**: View only (no custom)
- **Routines**: Basic pre-built only
- **AI Coach**: No access
- **Progress Tracking**: Last 7 days only
- **Ads**: None (clean experience)

#### 2. Premium Monthly ($9.99/month)
- **Timer**: Unlimited duration
- **All Growth Methods**: Full access
- **Custom Routines**: Create and save
- **AI Coach**: 10 interactions/day
- **Progress Tracking**: Full history
- **Priority Support**: 24-hour response

#### 3. Premium Annual ($59.99/year)
- **All Monthly Features**: Plus...
- **Savings**: 50% discount
- **Bonus Content**: Exclusive routines
- **Early Access**: New features
- **Annual Report**: Progress summary

#### 4. Lifetime ($149.99)
- **All Premium Features**: Forever
- **One-Time Payment**: No recurring charges
- **Legacy Pricing**: Protected from increases
- **Lifetime Support**: Priority assistance
- **Future Features**: All included

### Paywall Presentation

#### Trigger Points
1. **Onboarding**: After initial setup (skippable)
2. **Timer Limit**: When 5-minute limit reached
3. **Feature Gate**: Attempting premium feature
4. **Trial Expiration**: Automatic presentation
5. **Settings**: Manual upgrade option

#### Paywall UI Components
- **Hero Section**: Value proposition
- **Feature Comparison**: Free vs Premium
- **Plan Selector**: Visual pricing cards
- **Social Proof**: User testimonials
- **Guarantee**: 30-day money back
- **Restore Button**: For existing subscribers

### Purchase Flow

#### StoreKit2 Integration
```swift
// Product IDs
enum ProductID: String {
    case monthlySubscription = "com.growthlabs.growth.monthly"
    case annualSubscription = "com.growthlabs.growth.annual"
    case lifetimePurchase = "com.growthlabs.growth.lifetime"
}
```

#### Purchase Process
1. **Product Loading**: Fetch from App Store
2. **Price Display**: Localized pricing
3. **Purchase Initiation**: StoreKit2 sheet
4. **Verification**: Server-side validation
5. **Entitlement Update**: Immediate access
6. **Receipt Storage**: For restoration

### Entitlement Management

#### SimplifiedEntitlementManagerWithTrial
```swift
class SimplifiedEntitlementManagerWithTrial: ObservableObject {
    @Published var subscriptionTier: SubscriptionTier
    @Published var trialStatus: TrialStatus
    @Published var hasPremium: Bool
    @Published var trialDaysRemaining: Int

    // Usage tracking
    @Published var aiCoachUsageToday: Int
    @Published var guidedSessionsToday: Int

    // Business logic
    func canAccessPremiumFeature() -> Bool
    func canStartTimer(duration: TimeInterval) -> Bool
    func incrementAICoachUsage() async
}
```

#### Feature Gates
- **Method-Level**: `requiresPremium` flag
- **View-Level**: Conditional rendering
- **Service-Level**: API access control
- **Time-Based**: Session duration limits

### Subscription Management

#### User Actions
1. **View Status**: Current plan and expiry
2. **Change Plan**: Upgrade/downgrade
3. **Cancel**: With retention offer
4. **Restore**: Cross-device sync
5. **History**: Past transactions

#### Backend Sync
- **Real-time Updates**: Via Firebase
- **Webhook Processing**: App Store notifications
- **Grace Period**: 3 days for failed payments
- **Reactivation**: Immediate on payment

### Analytics & Metrics

#### Conversion Tracking
- `trial_started`: First app launch
- `trial_converted`: Subscription after trial
- `subscription_started`: Plan type, price
- `subscription_cancelled`: Reason, tenure
- `subscription_renewed`: Retention tracking
- `paywall_shown`: Trigger point
- `paywall_dismissed`: Without purchase
- `feature_gated`: Which feature blocked

#### Revenue Metrics
- **MRR**: Monthly Recurring Revenue
- **LTV**: Customer Lifetime Value
- **Churn Rate**: Monthly cancellations
- **ARPU**: Average Revenue Per User
- **Trial Conversion**: % converting

## Technical Implementation

### StoreKit2 Architecture
```swift
// Purchase Manager
class SimplifiedPurchaseManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []

    func loadProducts() async throws
    func purchase(_ product: Product) async throws
    func restorePurchases() async throws
    func handleTransactionUpdate(_ transaction: Transaction) async
}
```

### Server Verification
```javascript
// Firebase Function
exports.verifySubscription = functions.https.onCall(async (data, context) => {
    const { receiptData } = data;

    // 1. Verify with Apple
    const validation = await verifyWithApple(receiptData);

    // 2. Update Firestore
    await updateUserSubscription(context.auth.uid, validation);

    // 3. Return entitlements
    return {
        tier: validation.tier,
        expiresAt: validation.expiresAt
    };
});
```

### Remote Configuration
```javascript
// Remote Config Parameters
{
    "trial_enabled": true,
    "trial_duration_days": 3,
    "ai_coach_daily_limit_trial": 3,
    "guided_sessions_daily_limit_trial": 2,
    "free_tier_timer_limit_minutes": 5,
    "show_lifetime_option": true,
    "monthly_price": 9.99,
    "annual_price": 59.99,
    "lifetime_price": 149.99
}
```

## Error Handling

### Purchase Failures
1. **Network Error**: Retry with backoff
2. **Payment Declined**: Clear error message
3. **Product Unavailable**: Fallback options
4. **Verification Failed**: Contact support

### Restoration Issues
1. **No Purchases Found**: Clear messaging
2. **Partial Restoration**: List what worked
3. **Account Mismatch**: Guide to correct account

## Compliance & Policies

### App Store Guidelines
- **Clear Pricing**: Displayed before purchase
- **Subscription Terms**: In paywall and settings
- **Cancellation**: Easy access to manage
- **Restore**: Prominent button
- **Privacy**: No payment data stored

### Legal Requirements
- **Auto-Renewal Disclosure**: Clear terms
- **Price Changes**: 30-day notice
- **Refund Policy**: Apple's standard
- **Data Deletion**: Subscription data removal

## Future Enhancements

### Phase 2
- Family Sharing support
- Promo codes and offers
- Win-back campaigns
- A/B testing paywalls
- Referral program

### Phase 3
- Corporate/Team plans
- Student discounts
- Seasonal promotions
- Loyalty rewards
- Cross-platform sync

---

## Related Documentation
- [Trial System Architecture](../../architecture/trial-system.md)
- [StoreKit2 Implementation](../../technical/storekit2.md)
- [Revenue Analytics](../../analytics/revenue.md)