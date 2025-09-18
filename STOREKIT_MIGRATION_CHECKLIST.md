# StoreKit 2 Migration Checklist

## Overview
This checklist guides you through migrating from the complex StoreKit implementation to the simplified version. The migration is designed to be gradual and safe with feature flag control.

## Phase 1: Preparation ✅ COMPLETE
- [x] Created SimplePurchaseManager.swift
- [x] Created SimpleEntitlementManager.swift  
- [x] Created SimplifiedStoreKitService.swift (bridge)
- [x] Created SimpleFeatureGate.swift
- [x] Created SimplePaywallView.swift
- [x] Documented migration guide
- [x] Feature flag enabled in debug mode

## Phase 2: Update Core Views (CURRENT PHASE)

### High Priority Views (Directly Impact User Experience)
- [ ] **CoachChatView.swift** (Line 56)
  - Replace `.featureGated(.aiCoach)` with `.simpleFeatureGated(.aiCoach)`
  
- [ ] **CreateCustomRoutineView.swift** (Line 73)
  - Replace `.featureGated(.customRoutines)` with `.simpleFeatureGated(.customRoutines)`

- [ ] **SettingsView.swift** (Lines 14-17, 55-150)
  - Replace subscription service dependencies
  - Implement SimplifiedSubscriptionSection
  - Add sheet for SimplePaywallView

### Medium Priority Views (Feature Access Points)
- [ ] **Dashboard/Home View**
  - Update any feature gates to use simple version
  - Add conditional access views for premium features

- [ ] **Method Selection Views**
  - Implement free tier limits using SimpleEntitlementManager
  - Add premium badges for locked content

- [ ] **Analytics Views**
  - Gate advanced features with simpleFeatureGated
  - Show upgrade prompts for premium analytics

### Low Priority Views (Can Migrate Later)
- [ ] Onboarding flow paywall integration
- [ ] Profile/account views with subscription status
- [ ] Any remaining feature-gated content

## Phase 3: Testing in Debug Mode

### Functionality Tests
- [ ] Launch app with simplified implementation (auto-enabled in debug)
- [ ] Verify products load in SimplePaywallView
- [ ] Test purchase flow:
  - [ ] Select product
  - [ ] Complete purchase
  - [ ] Verify AI Coach unlocks immediately
  - [ ] Check other premium features unlock
- [ ] Test restore purchases functionality
- [ ] Force quit and relaunch - verify features remain unlocked

### Feature Flag Testing
- [ ] Toggle feature flag off - verify old implementation works
- [ ] Toggle feature flag on - verify new implementation works
- [ ] Confirm no data loss when switching

### UI/UX Verification
- [ ] Paywall displays correctly
- [ ] Feature gates show appropriate locked/unlocked states
- [ ] Premium badges appear for locked features
- [ ] Settings shows correct subscription status

## Phase 4: TestFlight Beta Testing

### Pre-TestFlight Checklist
- [ ] All critical views migrated
- [ ] Debug testing complete
- [ ] Error handling verified
- [ ] Analytics events working

### TestFlight Deployment
- [ ] Keep feature flag disabled by default
- [ ] Enable for specific beta testers via remote config
- [ ] Monitor crash reports and analytics
- [ ] Gather user feedback on purchase flow

### Rollout Plan
- [ ] 10% of TestFlight users (Week 1)
- [ ] 50% of TestFlight users (Week 2)
- [ ] 100% of TestFlight users (Week 3)
- [ ] Production rollout planning

## Phase 5: Production Rollout

### Gradual Rollout
- [ ] Enable for 10% of production users
- [ ] Monitor metrics for 48 hours
- [ ] Increase to 50% if metrics are good
- [ ] Full rollout after 1 week of stable 50%

### Success Metrics to Monitor
- [ ] Purchase conversion rate (should improve)
- [ ] Time to unlock after purchase (should be instant)
- [ ] Crash rate (should remain stable)
- [ ] Customer support tickets (should decrease)

### Rollback Criteria
If any of these occur, disable feature flag immediately:
- [ ] Purchase success rate drops >5%
- [ ] Crash rate increases >1%
- [ ] Critical bug in entitlement management
- [ ] Users losing access to purchased content

## Phase 6: Cleanup (After 2 Successful Releases)

### Code Removal
- [ ] Remove old PurchaseManager.swift
- [ ] Remove SubscriptionStateManager.swift
- [ ] Remove SubscriptionEntitlementService.swift
- [ ] Remove FeatureGateService.swift
- [ ] Remove old FeatureGate.swift view modifier
- [ ] Remove PaywallCoordinator.swift
- [ ] Remove complex PaywallView.swift

### Final Steps
- [ ] Remove feature flag code
- [ ] Make simplified implementation the only path
- [ ] Update documentation
- [ ] Archive old implementation for reference

## Quick Migration Commands

```swift
// Enable simplified implementation
StoreKitFeatureFlags.enableSimplified()

// Disable (rollback) to legacy
StoreKitFeatureFlags.disableSimplified()

// Check current state
print(StoreKitFeatureFlags.useSimplifiedImplementation)

// Debug state (in debug builds)
SimplifiedStoreKitService.shared.debugPrintState()
SimpleEntitlementManager.shared.debugPrintState()
```

## Common Migration Patterns

### Old Pattern → New Pattern

1. **Feature Gating**
   ```swift
   // OLD
   .featureGated(.aiCoach)
   
   // NEW
   .simpleFeatureGated(.aiCoach)
   ```

2. **Direct Entitlement Check**
   ```swift
   // OLD
   if FeatureGateService.shared.hasAccessBool(to: .aiCoach)
   
   // NEW
   if SimpleEntitlementManager.shared.hasAICoach
   ```

3. **Purchase Flow**
   ```swift
   // OLD
   let result = await PurchaseManager.shared.purchase(productID: "premium")
   switch result { /*...*/ }
   
   // NEW
   let success = await SimplePurchaseManager.shared.purchase(productID: "premium")
   if success { /*...*/ }
   ```

4. **Subscription Status**
   ```swift
   // OLD
   SubscriptionEntitlementService.shared.currentTier
   
   // NEW
   SimpleEntitlementManager.shared.hasPremium
   ```

## Support & Troubleshooting

### If Products Don't Load
```swift
await SimplePurchaseManager.shared.loadProducts()
```

### If Entitlements Don't Update
```swift
await SimplePurchaseManager.shared.updatePurchasedProducts()
```

### Force Refresh Everything
```swift
await SimplePurchaseManager.shared.restorePurchases()
```

### Debug Token Issues
```swift
#if DEBUG
SimpleEntitlementManager.shared.debugSetPremium(true) // Force premium for testing
#endif
```

## Notes
- The simplified implementation is automatically enabled in DEBUG builds
- Both implementations coexist - no need to delete old code immediately  
- Feature flag allows instant rollback if issues occur
- Monitor analytics closely during rollout phases
- Keep old implementation for at least 2 successful releases as backup