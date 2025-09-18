# Growth App Subscription Tiers Specification

## Overview

This document defines the complete subscription tier structure for the Growth app, including pricing, features, App Store Connect configuration, and technical implementation details.

## Subscription Tiers

### Basic Tier
- **Monthly:** $4.99/month
- **Yearly:** $49.99/year (17% discount - 2 months free)
- **Target Audience:** Users wanting core growth methods and basic progress tracking
- **Value Proposition:** Essential growth methods with basic analytics

### Premium Tier  
- **Monthly:** $9.99/month
- **Yearly:** $99.99/year (17% discount - 2 months free)
- **Target Audience:** Serious practitioners wanting AI coaching and advanced features
- **Value Proposition:** Complete growth method library with AI coaching support

### Elite Tier
- **Monthly:** $19.99/month  
- **Yearly:** $199.99/year (17% discount - 2 months free)
- **Target Audience:** Advanced users seeking personalized coaching and priority support
- **Value Proposition:** Premium features plus personalized coaching and exclusive content

## Feature Access Matrix

| Feature | Free | Basic | Premium | Elite |
|---------|------|-------|---------|-------|
| **Core Growth Methods** | Limited (3) | All Methods | All Methods | All Methods |
| **Progress Tracking** | Basic | Enhanced | Advanced Analytics | Advanced Analytics |
| **Community Access** | Read Only | Full Access | Full Access | Priority Access |
| **AI Coach** | None | None | Full Access | Full Access |
| **Personal Coaching** | None | None | None | Monthly Sessions |
| **Priority Support** | None | None | None | 24hr Response |
| **Exclusive Content** | None | None | None | Early Access |
| **Advanced Analytics** | None | None | Detailed Metrics | Custom Reports |
| **Method Customization** | None | Basic | Advanced | Complete |
| **Export Data** | None | Limited | Full Export | Full + API |

## App Store Connect Configuration

### Subscription Group
- **Group Name:** Growth Training Subscriptions
- **Reference Name:** growth_training_subs_v1
- **Review Notes:** Growth methods and AI coaching subscription tiers

### Product Configurations

#### Basic Monthly
- **Product ID:** `com.growth.subscription.basic.monthly`
- **Reference Name:** Growth Basic Monthly
- **Localized Title:** Growth Basic
- **Localized Description:** Access to all growth methods and enhanced progress tracking
- **Price:** $4.99 USD
- **Subscription Duration:** 1 Month
- **Free Trial:** 7 days
- **Subscription Group:** growth_training_subs_v1

#### Basic Yearly
- **Product ID:** `com.growth.subscription.basic.yearly`
- **Reference Name:** Growth Basic Yearly  
- **Localized Title:** Growth Basic (Annual)
- **Localized Description:** Annual access to all growth methods with 2 months free
- **Price:** $49.99 USD
- **Subscription Duration:** 1 Year
- **Free Trial:** 7 days
- **Subscription Group:** growth_training_subs_v1

#### Premium Monthly
- **Product ID:** `com.growth.subscription.premium.monthly`
- **Reference Name:** Growth Premium Monthly
- **Localized Title:** Growth Premium
- **Localized Description:** All methods plus AI coaching and advanced analytics
- **Price:** $9.99 USD
- **Subscription Duration:** 1 Month
- **Free Trial:** 7 days
- **Subscription Group:** growth_training_subs_v1

#### Premium Yearly
- **Product ID:** `com.growth.subscription.premium.yearly`
- **Reference Name:** Growth Premium Yearly
- **Localized Title:** Growth Premium (Annual)
- **Localized Description:** Annual premium access with AI coaching, 2 months free
- **Price:** $99.99 USD
- **Subscription Duration:** 1 Year
- **Free Trial:** 7 days
- **Subscription Group:** growth_training_subs_v1

#### Elite Monthly
- **Product ID:** `com.growth.subscription.elite.monthly`
- **Reference Name:** Growth Elite Monthly
- **Localized Title:** Growth Elite
- **Localized Description:** Premium features plus personal coaching and priority support
- **Price:** $19.99 USD
- **Subscription Duration:** 1 Month
- **Free Trial:** 7 days
- **Subscription Group:** growth_training_subs_v1

#### Elite Yearly
- **Product ID:** `com.growth.subscription.elite.yearly`
- **Reference Name:** Growth Elite Yearly
- **Localized Title:** Growth Elite (Annual)
- **Localized Description:** Annual elite access with personal coaching, 2 months free
- **Price:** $199.99 USD
- **Subscription Duration:** 1 Year
- **Free Trial:** 7 days
- **Subscription Group:** growth_training_subs_v1

## Technical Implementation

### Product ID Constants

```swift
enum SubscriptionProductIDs {
    static let basicMonthly = "com.growth.subscription.basic.monthly"
    static let basicYearly = "com.growth.subscription.basic.yearly"
    static let premiumMonthly = "com.growth.subscription.premium.monthly"
    static let premiumYearly = "com.growth.subscription.premium.yearly"
    static let eliteMonthly = "com.growth.subscription.elite.monthly"
    static let eliteYearly = "com.growth.subscription.elite.yearly"
}
```

### Tier Hierarchy

For upgrade/downgrade logic:
1. **Free** (none) - Base tier
2. **Basic** - Entry paid tier
3. **Premium** - Mid-tier with AI features
4. **Elite** - Top tier with personal coaching

### Feature Entitlements

```swift
struct FeatureEntitlements {
    let hasAllMethods: Bool
    let hasAICoach: Bool
    let hasPersonalCoaching: Bool
    let hasPrioritySupport: Bool
    let hasAdvancedAnalytics: Bool
    let hasExclusiveContent: Bool
    let maxExportData: ExportLevel
    let analyticsDetail: AnalyticsLevel
}
```

## Localization Requirements

### Supported Languages
- English (US) - Primary
- Spanish (ES, MX)
- French (FR)
- German (DE)
- Portuguese (BR)
- Japanese (JP)

### Key Localization Points
- Subscription tier names and descriptions
- Feature benefit descriptions
- Upgrade prompt messaging
- Trial period language
- Billing cycle descriptions

## Business Logic Rules

### Free Trial
- **Duration:** 7 days
- **Availability:** New subscribers only
- **Tier Access:** Full tier features during trial
- **Conversion:** Auto-renewal after trial unless cancelled

### Upgrades/Downgrades
- **Timing:** Immediate upgrade access, downgrade at next billing cycle
- **Proration:** Apple handles automatic proration for upgrades
- **Trial Handling:** No new trial periods for tier changes

### Grace Period
- **Duration:** 16 days (Apple default)
- **Access:** Maintained during grace period
- **Recovery:** Automatic on successful payment

### Family Sharing
- **Enabled:** Yes, for all subscription tiers
- **Organizer Benefits:** Full subscription benefits
- **Family Member Benefits:** Read-only access to methods, no AI coaching

## Revenue Projections

### Monthly Revenue Targets (Year 1)
- **Basic Tier:** 1,000 users × $4.99 = $4,990/month
- **Premium Tier:** 500 users × $9.99 = $4,995/month  
- **Elite Tier:** 100 users × $19.99 = $1,999/month
- **Total Monthly:** $11,984/month
- **Annual Projection:** $143,808/year

### Conversion Assumptions
- **Trial to Paid:** 15% conversion rate
- **Basic to Premium:** 20% upgrade rate
- **Premium to Elite:** 10% upgrade rate
- **Annual vs Monthly:** 30% choose annual billing

## Implementation Notes

### Phase 1 (Current Story)
- Define tier structure and features
- Configure App Store Connect products
- Implement core data models
- Create entitlement service

### Phase 2 (Story 23.2)
- StoreKit 2 integration
- Purchase flow implementation
- Receipt validation
- Trial period handling

### Phase 3 (Story 23.3)
- Feature gating implementation
- Paywall UI creation
- Settings integration
- User experience optimization

---

**Document Version:** 1.0  
**Last Updated:** 2025-07-04  
**Next Review:** Post-Story 23.1 completion