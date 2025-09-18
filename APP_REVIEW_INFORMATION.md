# App Review Information

## Test Account Credentials:
**Email:** apple@growthlabs.coach  
**Password:** Growthreview!01

## Key Features to Test:
1. **Timer functionality with Live Activities** (requires iOS 16.0+)
2. **In-app purchases** (3 subscription tiers: Weekly, 3-Months, Annual)
3. **AI Coach feature** accessible from Dashboard
4. **Growth Methods** educational content

## Testing Instructions:

### 1. Initial Setup
- Sign in with the provided test account
- Complete onboarding flow (subscription paywall will appear)

### 2. Subscription Testing
- **Paywalls are ENABLED** in this build
- Subscription options appear during onboarding after initial assessment
- All 3 tiers are available:
  - **Growth Premium - Weekly** ($4.99/week)
  - **Growth Premium - 3 Months** ($29.99/quarter, save 40%)
  - **Growth Premium - Annual** ($49.99/year, save 75%, includes 7-day trial)
- Test purchase using sandbox account
- Verify subscription management in Settings → Subscription

### 3. Core Features Testing
- From Dashboard, tap any Growth Method to start a timer session
- Test Live Activity by starting a timer and returning to home screen
- AI Coach can be tested from the Dashboard floating button (premium feature)
- Progress tracking and analytics available with active subscription

### 4. Important Notes:
- Subscriptions are submitted WITH this binary for review
- Receipt validation implements production-first with sandbox fallback
- All subscription features are fully functional in this build
- Users can manage subscriptions in Settings or iOS Settings app

## Technical Implementation Details:

### Subscription Configuration:
- **Product IDs:** 
  - `com.growthlabs.growthmethod.subscription.premium.weekly`
  - `com.growthlabs.growthmethod.subscription.premium.quarterly`
  - `com.growthlabs.growthmethod.subscription.premium.yearly`
- **StoreKit 2** implementation with iOS 15.0+ support
- **Receipt Validation:** Server-side validation via Firebase Functions
- **Sandbox Detection:** Automatic environment detection for proper testing

### What Changed Since Last Submission:
1. **Paywalls RE-ENABLED** (`FeatureFlags.paywallsEnabled = true`)
2. **Binary included** with subscription submission (per Guideline 2.1)
3. **Product names updated** to avoid rejection:
   - Removed "Pro" terminology
   - Clear billing frequency in descriptions
   - Simplified naming structure
4. **Full subscription flow** implemented and tested

### Contact Information:
**Developer Contact:** jon@growthlabs.coach  
**Support Email:** support@growthlabs.coach

---

# Submission Notes for App Review Team

This submission includes both the app binary AND subscription products as required. The subscriptions are fully integrated and functional within the app.

## Key Points:
1. **First-time subscription submission** with app binary (addressing previous return)
2. **All 3 subscription tiers** are active and purchasable
3. **Sandbox testing** works correctly with automatic environment detection
4. **Receipt validation** follows Apple's guidelines (production-first, sandbox fallback)
5. **Family Sharing** enabled for all subscriptions
6. **Restore purchases** functionality implemented

## Subscription Value Proposition:
Premium subscribers receive:
- AI-powered coaching with personalized recommendations
- Custom workout routine creation
- Advanced progress analytics and insights
- Live Activity support for timer sessions
- Cloud sync across all devices
- Priority customer support

## Compliance:
- ✅ Clear pricing displayed before purchase
- ✅ Subscription terms visible in app
- ✅ Links to Privacy Policy and Terms of Service
- ✅ Restore purchases functionality
- ✅ Subscription management UI
- ✅ Works across all user's devices

Thank you for reviewing our app. We're confident the subscription implementation meets all App Store guidelines.