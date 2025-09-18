# Complete App Store Connect Subscription Settings

## Product IDs (Already Created)
- Weekly: `com.growthlabs.growthmethod.subscription.premium.weekly`
- Quarterly: `com.growthlabs.growthmethod.subscription.premium.quarterly`
- Annual: `com.growthlabs.growthmethod.subscription.premium.yearly`

---

## WEEKLY SUBSCRIPTION
### Localization (English U.S.)
**Display Name:** Growth Premium - Weekly  
**Description:** Unlock all premium features. Billed weekly.

### Pricing
**Price:** $4.99 USD (Tier 5)  
**Currency:** USD  

### Subscription Details
**Duration:** 1 Week  
**Free Trial:** None (not recommended for weekly)  
**Subscription Group:** Growth Premium  
**Rank:** 3 (lowest priority)

---

## QUARTERLY SUBSCRIPTION (3 MONTHS)
### Localization (English U.S.)
**Display Name:** Growth Premium - 3 Months  
**Description:** Save 40% with quarterly billing  

### Pricing
**Price:** $29.99 USD (Tier 30)  
**Currency:** USD  

### Subscription Details
**Duration:** 3 Months  
**Free Trial:** Optional 3-day or 7-day trial  
**Subscription Group:** Growth Premium  
**Rank:** 2 (medium priority)

### Promotional Text (Optional)
"Get 3 months for the price of 2! Perfect for committed users who want to save."

---

## ANNUAL SUBSCRIPTION
### Localization (English U.S.)
**Display Name:** Growth Premium - Annual  
**Description:** Best value - Save 75%  

### Pricing
**Price:** $49.99 USD (Tier 50)  
**Currency:** USD  

### Subscription Details
**Duration:** 1 Year  
**Free Trial:** 7-day free trial (HIGHLY RECOMMENDED)  
**Introductory Offer (Optional):** First year at $39.99  
**Subscription Group:** Growth Premium  
**Rank:** 1 (highest priority - Apple prefers annual)

### Promotional Text (Optional)
"Try 7 days free! Best value with 75% savings compared to weekly billing."

---

## SUBSCRIPTION GROUP SETTINGS

### Group Name: Growth Premium
**Reference Name:** Growth Premium Subscriptions  
**Display Name:** Growth Premium Membership  

### Group Localization
**Subscription Group Display Name:** Growth Premium  
**Description:** "Unlock unlimited access to all premium features"  
**Custom Badge (Optional):** "PREMIUM MEMBER"

---

## IMPORTANT CONFIGURATION TIPS

### 1. Subscription Ranking (Critical!)
Set the rank in your subscription group:
- **Rank 1:** Annual (highest priority - Apple promotes this)
- **Rank 2:** 3 Months (middle option)
- **Rank 3:** Weekly (lowest priority)

*Apple uses this ranking to determine upgrade/downgrade paths and which option to feature.*

### 2. Free Trial Recommendations
- **Weekly:** NO free trial (too short for meaningful trial)
- **3 Months:** Optional 3-7 day trial
- **Annual:** ALWAYS offer 7-14 day trial (increases conversions by 200%+)

### 3. Grace Period Settings
**Recommended:** Enable 16-day grace period for all subscriptions
- Helps retain users with payment issues
- Reduces involuntary churn
- Apple recommends this for all subscriptions

### 4. Billing Retry
**Enable:** Billing retry for failed payments
- Duration: 60 days for annual, 30 days for quarterly, 7 days for weekly

### 5. Price Increase Settings
- Enable "Preserve current price for existing subscribers"
- Require consent for price increases over 50%

---

## REVIEW NOTES FOR APPLE

When submitting, include these review notes:

"Growth Premium provides access to:
1. AI-powered fitness coaching
2. Custom workout routine creation
3. Advanced progress analytics
4. Live activity tracking during workouts
5. Cloud sync across devices
6. Priority customer support

All subscriptions auto-renew. Users can manage or cancel anytime in Settings. We comply with all App Store subscription guidelines including:
- Clear pricing display before purchase
- Restore purchases functionality
- Account deletion with subscription info
- Privacy policy and terms of service links"

---

## COMMON MISTAKES TO AVOID

### ❌ DON'T:
- Use "Pro", "Plus", or "Premium" alone as the display name
- Hide the price or billing frequency
- Make false savings claims
- Use competitor comparisons
- Include emoji in display names
- Use ALL CAPS except for acronyms
- Mention other platforms or services

### ✅ DO:
- Clearly state billing frequency
- Include actual savings percentages
- List real features users get
- Use sentence case for display names
- Keep descriptions concise (under 100 characters)
- Highlight the value proposition
- Make annual the most attractive option

---

## METADATA FOR APP DESCRIPTION

Add this to your main app description:

"Subscription Options:
• Growth Premium Weekly ($4.99/week)
• Growth Premium 3 Months ($29.99/quarter, save 40%)
• Growth Premium Annual ($49.99/year, save 75%, includes 7-day free trial)

Subscriptions automatically renew unless turned off at least 24 hours before the end of the current period. Payment will be charged to your iTunes Account at confirmation of purchase. You can manage subscriptions and turn off auto-renewal in your Account Settings after purchase. Any unused portion of a free trial period will be forfeited when you purchase a subscription.

Privacy Policy: [your-url]
Terms of Service: [your-url]"

---

## STOREKIT CONFIGURATION FILE

Ensure your StoreKit Configuration file matches:
```json
{
  "subscriptions": [
    {
      "productId": "com.growthlabs.growthmethod.subscription.premium.weekly",
      "referenceName": "Growth Premium - Weekly",
      "type": "autoRenewable",
      "duration": "P1W",
      "price": 4.99
    },
    {
      "productId": "com.growthlabs.growthmethod.subscription.premium.quarterly",
      "referenceName": "Growth Premium - 3 Months",
      "type": "autoRenewable",
      "duration": "P3M",
      "price": 29.99
    },
    {
      "productId": "com.growthlabs.growthmethod.subscription.premium.yearly",
      "referenceName": "Growth Premium - Annual",
      "type": "autoRenewable",
      "duration": "P1Y",
      "price": 49.99,
      "offers": [
        {
          "type": "introductory",
          "duration": "P1W",
          "price": 0
        }
      ]
    }
  ]
}
```