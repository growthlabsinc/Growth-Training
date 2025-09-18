# StoreKit 2 Simplification Migration Guide

## Overview
This guide explains how to migrate from the complex multi-service architecture to the simplified StoreKit 2 implementation.

## New Architecture

### Before (Complex - 12+ Services)
```
StoreKitService → PurchaseManager → SubscriptionStateManager → 
SubscriptionEntitlementService → FeatureGateService → UI
```

### After (Simple - 2 Services)
```
SimplePurchaseManager → SimpleEntitlementManager → UI
```

## Files Created

### Core Services
1. **SimplePurchaseManager.swift** (~180 lines)
   - Direct StoreKit 2 integration
   - Transaction.currentEntitlements for state
   - Automatic transaction listener
   - One-line restore with AppStore.sync()

2. **SimpleEntitlementManager.swift** (~150 lines)
   - @AppStorage for persistence
   - Simple boolean flags for features
   - Works with App Extensions via App Group

3. **SimplifiedStoreKitService.swift** (Bridge)
   - Feature flag controlled migration
   - Routes to old or new implementation
   - Allows gradual rollout

### UI Components
1. **SimpleFeatureGate.swift**
   - Simple view modifier for feature gating
   - Direct entitlement checks
   - No complex service dependencies

2. **SimplePaywallView.swift**
   - Clean paywall implementation
   - Direct use of SimplePurchaseManager
   - Auto-dismisses on successful purchase

## Migration Steps

### Step 1: Enable in Debug Mode

The simplified implementation is already enabled in debug mode. Test it:

```swift
// Already set in SimplifiedStoreKitService
#if DEBUG
return true  // Always use simplified in debug
#endif
```

### Step 2: Update UI Components

Replace complex feature gating:

**Old Way:**
```swift
CoachChatView()
    .featureGated(.aiCoach)  // Complex, uses 5+ services
```

**New Way (Option 1 - Modifier):**
```swift
CoachChatView()
    .simpleFeatureGated(.aiCoach)  // Simple, uses 1 service
```

**New Way (Option 2 - Direct Check):**
```swift
@ObservedObject var entitlements = SimpleEntitlementManager.shared

if entitlements.hasAICoach {
    CoachChatView()
} else {
    UpgradePromptView()
}
```

### Step 3: Update Purchase Calls

**Old Way:**
```swift
let result = await PurchaseManager.shared.purchase(productID: "premium_annual")
switch result {
    case .success:
        // Complex state updates
    // ...
}
```

**New Way:**
```swift
let success = await SimplePurchaseManager.shared.purchase(productID: "premium_annual")
if success {
    // Entitlements automatically updated!
}
```

### Step 4: Test Feature Flag Toggle

```swift
// Enable simplified (already on in debug)
StoreKitFeatureFlags.enableSimplified()

// Disable to rollback
StoreKitFeatureFlags.disableSimplified()
```

## Testing Checklist

### Basic Functionality
- [ ] Products load and display prices
- [ ] Purchase flow completes successfully
- [ ] AI Coach unlocks immediately after purchase
- [ ] Other premium features unlock
- [ ] Restore purchases works

### State Persistence
- [ ] Force quit app - features remain unlocked
- [ ] Delete app, reinstall, restore - features restored
- [ ] Airplane mode - cached entitlements work

### Migration
- [ ] Toggle feature flag - both implementations work
- [ ] No data loss when switching implementations

## Code Examples

### Example 1: AI Coach View

```swift
import SwiftUI

struct AICoachTabView: View {
    @ObservedObject var entitlements = SimpleEntitlementManager.shared
    
    var body: some View {
        if entitlements.hasAICoach {
            CoachChatView()
        } else {
            SimplePaywallView()
        }
    }
}
```

### Example 2: Settings Subscription Section

```swift
struct SubscriptionSettingsView: View {
    @ObservedObject var entitlements = SimpleEntitlementManager.shared
    @StateObject var purchaseManager = SimplePurchaseManager(
        entitlementManager: SimpleEntitlementManager.shared
    )
    
    var body: some View {
        Section("Subscription") {
            if entitlements.hasPremium {
                HStack {
                    Label("Premium Active", systemImage: "star.fill")
                    Spacer()
                    Text(entitlements.subscriptionTier)
                        .foregroundColor(.secondary)
                }
            } else {
                Button("Upgrade to Premium") {
                    // Show paywall
                }
            }
            
            Button("Restore Purchases") {
                Task {
                    await purchaseManager.restorePurchases()
                }
            }
        }
    }
}
```

### Example 3: Feature-Gated Button

```swift
struct AnalyticsButton: View {
    @ObservedObject var entitlements = SimpleEntitlementManager.shared
    
    var body: some View {
        Button(action: { /* */ }) {
            HStack {
                Label("Advanced Analytics", systemImage: "chart.line.uptrend.xyaxis")
                
                if !entitlements.hasAdvancedAnalytics {
                    SimplePremiumBadge()
                }
            }
        }
        .disabled(!entitlements.hasAdvancedAnalytics)
    }
}
```

## Performance Improvements

### Before (Complex)
- 12+ services initialized
- Multiple async chains for state updates
- Complex caching mechanisms
- 2000+ lines of code

### After (Simple)
- 2 services only
- Direct state updates
- StoreKit 2's built-in caching
- ~400 lines of code

## Rollback Plan

If issues occur:

1. **Immediate Rollback:**
   ```swift
   StoreKitFeatureFlags.disableSimplified()
   ```

2. **Force Legacy:**
   ```swift
   // In SimplifiedStoreKitService.swift
   public static var useSimplifiedImplementation: Bool {
       return false  // Force legacy
   }
   ```

3. **Keep Both Implementations:**
   - Old services remain untouched
   - Can switch back anytime
   - Remove after 2 successful releases

## Common Issues & Solutions

### Issue: Products not loading
**Solution:** StoreKit 2 handles this automatically. Just retry:
```swift
await purchaseManager.loadProducts()
```

### Issue: Entitlements not updating
**Solution:** Force refresh:
```swift
await purchaseManager.updatePurchasedProducts()
```

### Issue: Feature still locked after purchase
**Solution:** Check entitlement manager state:
```swift
entitlements.debugPrintState()  // In debug mode
```

## Benefits Realized

1. **Immediate UI Updates** - No more restart needed
2. **Simpler Code** - 80% less code to maintain
3. **Better Performance** - Fewer services, less memory
4. **Easier Debugging** - Clear, linear flow
5. **Trust StoreKit 2** - Let Apple handle the complexity

## Next Steps

1. **Week 1:** Test in debug mode thoroughly
2. **Week 2:** TestFlight with feature flag
3. **Week 3:** Gradual production rollout (10% → 50% → 100%)
4. **Week 4:** Remove old services (keep as backup)

## Support

For questions or issues:
1. Check debug state: `SimplifiedStoreKitService.shared.debugPrintState()`
2. Toggle feature flag to compare behaviors
3. File issues with logs from both implementations