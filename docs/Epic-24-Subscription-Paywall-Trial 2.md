# Epic 24: Subscription Paywall & Trial Period Implementation

## Overview
Implement a comprehensive subscription paywall system with a 5-day free trial, including signup flow integration and feature gating after trial expiration.

## Business Goals
- **Monetization**: Convert free users to paid subscribers after trial period
- **User Acquisition**: Allow users to experience premium features before committing
- **Revenue Growth**: Implement feature gating to drive subscription conversions
- **User Experience**: Smooth onboarding with optional paywall bypass during signup

## Current State
Based on Epic 23 implementation:
- ✅ Subscription tiers defined (Basic $4.99, Premium $9.99, Elite $19.99)
- ✅ SubscriptionStateManager for state management
- ✅ SubscriptionEntitlementService for feature access
- ✅ Backend receipt validation via Firebase Functions
- ❌ No paywall UI
- ❌ No trial period tracking
- ❌ No feature gating implementation
- ❌ No subscription purchase UI

## Epic Scope

### 1. Signup Paywall Flow
- **Skippable paywall** during signup process
- Show after account creation but before main app
- "Start Free Trial" and "Skip for Now" options
- Track whether user saw paywall during onboarding

### 2. Trial Period Management
- **5-day free trial** for all new users
- Trial start date tracking in User model
- Trial expiration calculations
- Trial status display throughout app
- Push notifications for trial expiration warnings (day 3, day 4, day 5)

### 3. Feature Gating System
**Free Tier Limitations** (after trial):
- Limited to 3 growth methods
- No AI Coach access
- Basic analytics only
- No routine customization
- No export features

**Premium/Elite Features**:
- All growth methods unlocked
- AI Coach access (Premium+)
- Advanced analytics
- Custom routines
- Data export
- Priority support (Elite)

### 4. Paywall UI Components
- Full-screen paywall view
- Pricing comparison cards
- Feature comparison matrix
- Purchase button states
- Loading/processing views
- Success/error handling
- Restore purchases functionality

### 5. Post-Trial Enforcement
- Hard paywall when accessing gated features
- Soft prompts in UI for locked content
- Lock indicators on methods/features
- Upgrade CTAs throughout app

## User Stories

### Story 24.1: Signup Paywall Flow
**As a** new user  
**I want to** see subscription options during signup  
**So that** I can start a trial or skip for later  

**Acceptance Criteria:**
- Paywall appears after email/auth signup
- Can start 5-day trial with one tap
- Can skip and continue to app
- Paywall state tracked for analytics

### Story 24.2: Trial Period Tracking
**As a** user on trial  
**I want to** see my trial status  
**So that** I know when it expires  

**Acceptance Criteria:**
- Trial countdown in settings
- Trial banner on dashboard
- Push notifications on day 3, 4, 5
- Graceful transition when trial ends

### Story 24.3: Feature Gating Implementation
**As a** free user after trial  
**I want to** see what features require subscription  
**So that** I understand upgrade benefits  

**Acceptance Criteria:**
- Methods beyond 3 show lock icon
- AI Coach tab shows paywall
- Locked features show upgrade prompt
- Clear messaging about limitations

### Story 24.4: Paywall UI Components
**As a** user hitting a paywall  
**I want to** easily compare and purchase plans  
**So that** I can upgrade quickly  

**Acceptance Criteria:**
- Clean pricing display
- Feature comparison visible
- Native payment sheet integration
- Purchase confirmation
- Error handling

### Story 24.5: Subscription Management
**As a** subscribed user  
**I want to** manage my subscription  
**So that** I can change or cancel plans  

**Acceptance Criteria:**
- View current plan details
- Change subscription tier
- Cancel subscription
- View billing history
- Restore purchases

## Technical Architecture

### Data Model Updates
```swift
// User model extension
extension User {
    var trialStartDate: Date?
    var hasSeenSignupPaywall: Bool
    var subscriptionStatus: SubscriptionState
    
    var isInTrial: Bool {
        guard let startDate = trialStartDate else { return false }
        return Date().timeIntervalSince(startDate) < 5 * 24 * 60 * 60
    }
    
    var trialDaysRemaining: Int {
        guard let startDate = trialStartDate else { return 0 }
        let elapsed = Date().timeIntervalSince(startDate)
        let remaining = (5 * 24 * 60 * 60) - elapsed
        return max(0, Int(remaining / (24 * 60 * 60)))
    }
}
```

### Feature Gating Service
```swift
class FeatureGatingService {
    static func canAccessMethod(_ method: GrowthMethod) -> Bool
    static func canAccessAICoach() -> Bool
    static func canCreateCustomRoutine() -> Bool
    static func canExportData() -> Bool
    static func getAccessibleMethodCount() -> Int
}
```

### Paywall Trigger Points
1. **Signup Flow**: After authentication
2. **Method Selection**: When selecting 4th+ method
3. **AI Coach Tab**: When tapping AI Coach
4. **Routine Creation**: Custom routine button
5. **Settings**: Upgrade button
6. **Trial Expiration**: Automatic on day 5

## Implementation Plan

### Phase 1: Core Infrastructure (Week 1)
- [ ] Update User model with trial fields
- [ ] Create FeatureGatingService
- [ ] Implement trial period calculations
- [ ] Add trial tracking to user creation

### Phase 2: Signup Paywall (Week 1-2)
- [ ] Create PaywallView component
- [ ] Integrate into signup flow
- [ ] Add skip functionality
- [ ] Track paywall presentation

### Phase 3: Feature Gating (Week 2)
- [ ] Implement method limiting
- [ ] Add AI Coach gating
- [ ] Create LockedContentOverlay
- [ ] Add upgrade prompts

### Phase 4: Trial Management (Week 3)
- [ ] Trial status displays
- [ ] Countdown components
- [ ] Expiration handling
- [ ] Push notification scheduling

### Phase 5: Purchase Flow (Week 3-4)
- [ ] StoreKit integration UI
- [ ] Purchase processing views
- [ ] Success/error handling
- [ ] Receipt validation UI

### Phase 6: Post-Trial UX (Week 4)
- [ ] Full paywall implementation
- [ ] Subscription management view
- [ ] Settings integration
- [ ] Analytics tracking

## Success Metrics
- **Trial Start Rate**: % of new users starting trial from signup
- **Trial Conversion Rate**: % of trials converting to paid
- **Day 5 Retention**: % of users active on day 5
- **Feature Engagement**: Usage of gated features pre/post trial
- **Paywall Conversion**: % converting when hitting paywall
- **Subscription Revenue**: MRR growth from implementation

## Dependencies
- Epic 23: Subscription Infrastructure (COMPLETED)
- Firebase Functions for receipt validation (COMPLETED)
- StoreKit configuration in App Store Connect (COMPLETED)
- Push notification infrastructure (EXISTING)

## Risks & Mitigations
- **Risk**: Users churning due to aggressive gating
  - **Mitigation**: Carefully chosen free tier limits, clear value messaging
- **Risk**: Technical issues with trial tracking
  - **Mitigation**: Server-side trial validation, multiple checkpoints
- **Risk**: App Store rejection for paywall placement
  - **Mitigation**: Follow Apple guidelines, skippable signup paywall

## Future Enhancements
- A/B testing different trial lengths
- Personalized paywall messaging
- Win-back campaigns for expired trials
- Annual subscription discounts
- Referral program integration