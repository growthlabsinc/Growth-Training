# StoreKit 2 Simplification Action Plan

## Overview
This plan outlines specific steps to simplify your StoreKit 2 implementation based on best practices from RevenueCat, Superwall, and Nami tutorials.

## Phase 1: Immediate Fixes (Day 1)
**Goal:** Fix the AI Coach unlock issue

### ✅ Already Completed
- Fixed async/await pattern in PurchaseManager
- Changed to use `await FeatureGateService.forceRefresh()`

### Add Debug Logging
Add logging to track the subscription state flow:

```swift
// In PurchaseManager.swift after successful purchase
Logger.info("🎯 Purchase Success - Product: \(product.id)")
Logger.info("🎯 Before update - AI Coach Access: \(FeatureGateService.shared.hasAccessBool(to: .aiCoach))")
await SubscriptionStateManager.shared.forceRefresh()
await FeatureGateService.shared.forceRefresh()
Logger.info("🎯 After update - AI Coach Access: \(FeatureGateService.shared.hasAccessBool(to: .aiCoach))")
```

### Create Debug View
Add a debug section in Settings to show real-time subscription state:

```swift
// DebugSubscriptionView.swift
struct DebugSubscriptionView: View {
    @EnvironmentObject var storeKit: StoreKitService
    @EnvironmentObject var subscriptionState: SubscriptionStateManager
    @EnvironmentObject var featureGate: FeatureGateService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Debug Subscription Info")
                .font(.headline)
            
            Text("StoreKit: \(storeKit.hasActiveSubscription ? "✅" : "❌") Active")
            Text("State Manager: \(subscriptionState.subscriptionState.hasActiveAccess ? "✅" : "❌") Active")
            Text("AI Coach: \(featureGate.hasAccessBool(to: .aiCoach) ? "✅" : "❌") Unlocked")
            Text("Products Loaded: \(storeKit.purchasedProductIDs.count)")
            
            Button("Force Refresh") {
                Task {
                    await storeKit.updatePurchasedProducts()
                    await subscriptionState.forceRefresh()
                    await featureGate.forceRefresh()
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}
```

## Phase 2: State Consolidation (Week 1)

### Step 1: Create Unified Subscription Manager
Replace multiple services with one:

```swift
// UnifiedSubscriptionManager.swift
import SwiftUI
import StoreKit
import Combine

@MainActor
class UnifiedSubscriptionManager: ObservableObject {
    // MARK: - Single Source of Truth
    @Published var hasActiveSubscription = false
    @Published var products: [Product] = []
    @Published var purchasedProductIDs = Set<String>()
    
    // MARK: - Persistence
    @AppStorage("subscription_active") private var cachedActive = false
    @AppStorage("subscription_products") private var cachedProducts = ""
    
    // MARK: - StoreKit
    private var transactionListener: Task<Void, Never>?
    
    init() {
        // Load cached state immediately
        hasActiveSubscription = cachedActive
        if !cachedProducts.isEmpty {
            purchasedProductIDs = Set(cachedProducts.split(separator: ",").map(String.init))
        }
        
        // Start transaction listener
        transactionListener = listenForTransactions()
        
        // Refresh from StoreKit
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - Product Management
    func loadProducts() async {
        do {
            products = try await Product.products(for: SubscriptionProductIDs.allProductIDs)
        } catch {
            Logger.error("Failed to load products: \(error)")
        }
    }
    
    // MARK: - Purchase Flow
    func purchase(productID: String) async -> Bool {
        guard let product = products.first(where: { $0.id == productID }) else {
            return false
        }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await updatePurchasedProducts()
                    return true
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            Logger.error("Purchase failed: \(error)")
        }
        
        return false
    }
    
    // MARK: - Entitlement Updates
    func updatePurchasedProducts() async {
        purchasedProductIDs.removeAll()
        
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.revocationDate == nil {
                    purchasedProductIDs.insert(transaction.productID)
                }
            }
        }
        
        // Update state
        hasActiveSubscription = !purchasedProductIDs.isEmpty
        
        // Persist
        cachedActive = hasActiveSubscription
        cachedProducts = purchasedProductIDs.joined(separator: ",")
        
        Logger.info("✅ Subscription state updated: \(hasActiveSubscription ? "Active" : "Inactive")")
    }
    
    // MARK: - Transaction Listener
    private func listenForTransactions() -> Task<Void, Never> {
        Task(priority: .background) {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await updatePurchasedProducts()
                }
            }
        }
    }
    
    // MARK: - Restore
    func restorePurchases() async {
        try? await AppStore.sync()
        await updatePurchasedProducts()
    }
    
    // MARK: - Feature Access (Direct)
    var hasAICoachAccess: Bool {
        hasActiveSubscription
    }
    
    var hasAllMethodsAccess: Bool {
        hasActiveSubscription
    }
    
    var hasPremiumContent: Bool {
        hasActiveSubscription
    }
}
```

### Step 2: Update App Initialization
```swift
// Caffeine_PalApp.swift (or your App file)
@main
struct GrowthApp: App {
    @StateObject private var subscriptionManager = UnifiedSubscriptionManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(subscriptionManager)
        }
    }
}
```

### Step 3: Update UI Components
```swift
// In any view that needs subscription state
struct AICoachView: View {
    @EnvironmentObject var subscriptions: UnifiedSubscriptionManager
    
    var body: some View {
        if subscriptions.hasAICoachAccess {
            // Show AI Coach
        } else {
            // Show paywall
        }
    }
}
```

## Phase 3: Remove Redundant Services (Week 2)

### Services to Deprecate:
1. `SubscriptionEntitlementService` - Functionality moved to UnifiedSubscriptionManager
2. `SubscriptionStateManager` - Replaced by UnifiedSubscriptionManager
3. `FeatureGateService` - Direct property checks instead

### Migration Path:
```swift
// Old way
if FeatureGateService.shared.hasAccessBool(to: .aiCoach) {
    // Show feature
}

// New way
if subscriptionManager.hasAICoachAccess {
    // Show feature
}
```

## Phase 4: Server Validation (Week 3)

### Implement Firebase Function
```javascript
// functions/validatePurchase.js
exports.validatePurchase = functions.https.onCall(async (data, context) => {
    const { transactionId, productId, originalTransactionId } = data;
    
    // Verify with Apple
    const verification = await verifyWithApple(transactionId);
    
    // Store in Firestore
    await admin.firestore()
        .collection('purchases')
        .doc(context.auth.uid)
        .set({
            transactionId,
            productId,
            originalTransactionId,
            verified: verification.valid,
            timestamp: admin.firestore.FieldValue.serverTimestamp()
        });
    
    return { valid: verification.valid };
});
```

### Update Purchase Flow
```swift
func validateWithServer(_ transaction: Transaction) async -> Bool {
    let functions = Functions.functions()
    
    do {
        let result = try await functions.httpsCallable("validatePurchase").call([
            "transactionId": transaction.id,
            "productId": transaction.productID,
            "originalTransactionId": transaction.originalID
        ])
        
        return (result.data as? [String: Any])?["valid"] as? Bool ?? false
    } catch {
        Logger.error("Server validation failed: \(error)")
        // Fail open in debug, fail closed in production
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}
```

## Phase 5: Testing & Monitoring (Week 4)

### Test Cases:
1. **Purchase Flow**
   - Purchase subscription → Verify immediate AI Coach access
   - Purchase on Device A → Verify sync to Device B
   
2. **Restoration**
   - Delete app → Reinstall → Restore → Verify access
   
3. **Offline**
   - Enable airplane mode → Launch app → Verify cached access

### Monitoring:
```swift
// Add analytics
func trackSubscriptionEvent(_ event: String, properties: [String: Any] = [:]) {
    var props = properties
    props["has_subscription"] = hasActiveSubscription
    props["product_count"] = purchasedProductIDs.count
    
    Analytics.logEvent(event, parameters: props)
}
```

## Success Metrics

### Before Simplification:
- 5+ services
- 2000+ lines of code
- Multiple state sources
- Complex async chains
- Synchronization issues

### After Simplification:
- 1 unified manager
- ~300 lines of code
- Single source of truth
- Direct state updates
- Immediate UI updates

## Timeline

| Week | Phase | Deliverable |
|------|-------|------------|
| 1 | Immediate Fixes | AI Coach unlock working |
| 1 | State Consolidation | UnifiedSubscriptionManager implemented |
| 2 | Service Removal | Deprecated services removed |
| 3 | Server Validation | Firebase validation live |
| 4 | Testing | Full test coverage |

## Risk Mitigation

### During Migration:
1. Keep old services running in parallel
2. Add feature flag to switch between implementations
3. Test thoroughly in TestFlight before production

### Rollback Plan:
```swift
// Feature flag for gradual rollout
var useSimplifiedSubscriptions: Bool {
    #if DEBUG
    return true
    #else
    return RemoteConfig.getValue("use_simplified_subscriptions").boolValue
    #endif
}
```

## Conclusion

This simplification will:
1. **Fix** the immediate AI Coach unlock issue
2. **Reduce** code complexity by 85%
3. **Improve** maintainability and debugging
4. **Align** with Apple's recommended patterns
5. **Eliminate** state synchronization issues

The key insight from all tutorials: **StoreKit 2 handles the complexity, you don't need to.**