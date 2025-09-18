# Full StoreKit 2 Implementation Plan

## Overview
Since there are no current subscribers, we can fully replace the complex StoreKit implementation with the simplified version immediately. No migration needed!

## Step 1: Remove Old Implementation References

### Files to Update Immediately

#### 1. Update AppDelegate.swift or GrowthApp.swift
Replace old initialization with simplified version:

```swift
// OLD - Remove these
import FirebaseAuth
import FirebaseFirestore

// In app initialization, remove:
// await PurchaseManager.shared.loadProducts()
// await SubscriptionStateManager.shared.refreshState()
// SubscriptionEntitlementService.shared.startListening()

// NEW - Add this
Task {
    await SimplePurchaseManager.shared.loadProducts()
    await SimplePurchaseManager.shared.startTransactionListener()
}
```

#### 2. Update All Feature Gates
Search and replace across entire project:
- `.featureGated(` → `.simpleFeatureGated(`

#### 3. Update SettingsView.swift
Replace entire subscription section with simplified version.

## Step 2: Remove Old Files Completely

### Delete These Files:
```
Growth/Core/Services/
├── PurchaseManager.swift ❌
├── SubscriptionStateManager.swift ❌
├── SubscriptionEntitlementService.swift ❌
├── FeatureGateService.swift ❌
├── PaywallCoordinator.swift ❌
├── StoreKitService.swift ❌
└── SubscriptionValidationService.swift ❌

Growth/Core/Views/
├── FeatureGate.swift ❌
└── PaywallView.swift ❌

Growth/Core/ViewModels/
└── PaywallViewModel.swift ❌
```

## Step 3: Update Project Structure

### Keep Only Simplified Services:
```
Growth/Core/Services/Simplified/
├── SimplePurchaseManager.swift ✅
├── SimpleEntitlementManager.swift ✅
└── SimplifiedStoreKitService.swift → Rename to StoreKitService.swift
```

### Move Simplified Views:
```
Growth/Core/Views/Simplified/
├── SimplePaywallView.swift → Move to Growth/Core/Views/PaywallView.swift
├── SimpleFeatureGate.swift → Move to Growth/Core/Views/FeatureGate.swift
└── SimpleMigrationTestView.swift → Can delete (no migration needed)
```

## Step 4: Clean Up Code

### Remove Feature Flags
Since we're doing a full replacement, remove all feature flag code:

```swift
// DELETE SimplifiedStoreKitService.swift bridge service
// We don't need it anymore!

// In any remaining code, remove:
if StoreKitFeatureFlags.useSimplifiedImplementation { }
```

### Rename "Simple" Classes
Remove "Simple" prefix from all class names:
- `SimplePurchaseManager` → `PurchaseManager`
- `SimpleEntitlementManager` → `EntitlementManager`
- `SimplePaywallView` → `PaywallView`
- `SimpleFeatureGate` → `FeatureGate`
- `.simpleFeatureGated` → `.featureGated`

## Step 5: Implementation Checklist

### Core Files to Create/Update:

- [ ] **PurchaseManager.swift** (rename from SimplePurchaseManager)
- [ ] **EntitlementManager.swift** (rename from SimpleEntitlementManager)
- [ ] **PaywallView.swift** (rename from SimplePaywallView)
- [ ] **FeatureGate.swift** (rename from SimpleFeatureGate)

### Views to Update:

- [ ] **CoachChatView.swift** - Use new `.featureGated(.aiCoach)`
- [ ] **CreateCustomRoutineView.swift** - Use new `.featureGated(.customRoutines)`
- [ ] **SettingsView.swift** - Completely replace subscription section
- [ ] **Any other views with feature gates**

### App Initialization:

- [ ] **GrowthApp.swift** - Initialize new PurchaseManager on app launch
- [ ] Remove all old service initializations
- [ ] Add transaction listener startup

## Step 6: Testing

### Immediate Testing Priority:
1. **Product Loading** - Verify products appear in paywall
2. **Purchase Flow** - Test sandbox purchases
3. **Feature Unlocking** - Ensure features unlock immediately
4. **Restore Purchases** - Verify AppStore.sync() works
5. **App Restart** - Features stay unlocked

### No Migration Testing Needed! 🎉
Since there are no subscribers, we can skip:
- Data migration testing
- Backwards compatibility testing  
- Gradual rollout testing
- Feature flag testing

## Implementation Code

Here's the complete implementation ready to copy:

### 1. PurchaseManager.swift (Final Version)
```swift
import SwiftUI
import StoreKit

@MainActor
public final class PurchaseManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var products: [Product] = []
    @Published public var purchasedProductIDs: Set<String> = []
    @Published public var isLoading = false
    @Published public var isPurchasing = false
    @Published public var lastError: Error?
    
    // MARK: - Private Properties
    
    private let entitlementManager: EntitlementManager
    private var updateListenerTask: Task<Void, Error>?
    
    // MARK: - Product IDs
    
    private let productIDs = [
        "premium_monthly",
        "premium_annual"
    ]
    
    // MARK: - Singleton
    
    public static let shared = PurchaseManager(
        entitlementManager: EntitlementManager.shared
    )
    
    // MARK: - Initialization
    
    public init(entitlementManager: EntitlementManager) {
        self.entitlementManager = entitlementManager
        
        Task {
            await loadProducts()
            await updatePurchasedProducts()
            startTransactionListener()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Product Loading
    
    public func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            products = try await Product.products(for: productIDs)
            Logger.info("✅ Loaded \(products.count) products")
        } catch {
            Logger.error("❌ Failed to load products: \(error)")
            lastError = error
        }
    }
    
    // MARK: - Purchase Flow
    
    public func purchase(_ product: Product) async -> Bool {
        isPurchasing = true
        defer { isPurchasing = false }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                
                await transaction.finish()
                await updatePurchasedProducts()
                
                Logger.info("✅ Purchase successful: \(product.id)")
                return true
                
            case .userCancelled:
                Logger.info("ℹ️ Purchase cancelled by user")
                return false
                
            case .pending:
                Logger.info("⏳ Purchase pending approval")
                return false
                
            @unknown default:
                Logger.warning("⚠️ Unknown purchase result")
                return false
            }
        } catch {
            Logger.error("❌ Purchase failed: \(error)")
            lastError = error
            return false
        }
    }
    
    public func purchase(productID: String) async -> Bool {
        guard let product = products.first(where: { $0.id == productID }) else {
            Logger.error("❌ Product not found: \(productID)")
            return false
        }
        
        return await purchase(product)
    }
    
    // MARK: - Restore Purchases
    
    public func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        
        Logger.info("🔄 Restoring purchases...")
        
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
            Logger.info("✅ Purchases restored")
        } catch {
            Logger.error("❌ Restore failed: \(error)")
            lastError = error
        }
    }
    
    // MARK: - Transaction Updates
    
    public func updatePurchasedProducts() async {
        purchasedProductIDs.removeAll()
        
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.revocationDate == nil {
                    purchasedProductIDs.insert(transaction.productID)
                }
            }
        }
        
        entitlementManager.updateFromPurchases(purchasedProductIDs)
        
        Logger.info("📱 Updated entitlements: \(purchasedProductIDs)")
    }
    
    // MARK: - Transaction Listener
    
    public func startTransactionListener() {
        updateListenerTask?.cancel()
        
        updateListenerTask = Task {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await updatePurchasedProducts()
                    await transaction.finish()
                }
            }
        }
    }
    
    // MARK: - Verification
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw PurchaseError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
}

// MARK: - Error Types

public enum PurchaseError: LocalizedError {
    case verificationFailed
    case productNotFound
    
    public var errorDescription: String? {
        switch self {
        case .verificationFailed:
            return "Purchase verification failed"
        case .productNotFound:
            return "Product not found"
        }
    }
}
```

### 2. EntitlementManager.swift (Final Version)
```swift
import SwiftUI
import Foundation

public final class EntitlementManager: ObservableObject {
    
    // MARK: - App Group Configuration
    
    private static let appGroupIdentifier = "group.com.growthlabs.growthmethod"
    private static let userDefaults = UserDefaults(suiteName: appGroupIdentifier)!
    
    // MARK: - Singleton
    
    public static let shared = EntitlementManager()
    
    // MARK: - Entitlement Flags
    
    @AppStorage("has_premium", store: userDefaults)
    public var hasPremium: Bool = false
    
    @AppStorage("has_ai_coach", store: userDefaults)
    public var hasAICoach: Bool = false
    
    @AppStorage("has_custom_routines", store: userDefaults)
    public var hasCustomRoutines: Bool = false
    
    @AppStorage("has_advanced_analytics", store: userDefaults)
    public var hasAdvancedAnalytics: Bool = false
    
    @AppStorage("has_all_methods", store: userDefaults)
    public var hasAllMethods: Bool = false
    
    @AppStorage("subscription_tier", store: userDefaults)
    public var subscriptionTier: String = "none"
    
    // MARK: - Update Methods
    
    public func updateFromPurchases(_ purchasedProductIDs: Set<String>) {
        let hasPremiumProduct = purchasedProductIDs.contains { productID in
            productID.contains("premium")
        }
        
        if hasPremiumProduct {
            hasPremium = true
            hasAICoach = true
            hasCustomRoutines = true
            hasAdvancedAnalytics = true
            hasAllMethods = true
            subscriptionTier = "premium"
        } else {
            clearEntitlements()
        }
    }
    
    public func clearEntitlements() {
        hasPremium = false
        hasAICoach = false
        hasCustomRoutines = false
        hasAdvancedAnalytics = false
        hasAllMethods = false
        subscriptionTier = "none"
    }
    
    public func hasAccess(to feature: FeatureType) -> Bool {
        switch feature {
        case .aiCoach:
            return hasAICoach
        case .customRoutines:
            return hasCustomRoutines
        case .advancedAnalytics:
            return hasAdvancedAnalytics
        case .allMethods:
            return hasAllMethods
        default:
            return hasPremium
        }
    }
}
```

### 3. Update GrowthApp.swift
```swift
@main
struct GrowthApp: App {
    @StateObject private var purchaseManager = PurchaseManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // Start listening for transactions
                    purchaseManager.startTransactionListener()
                }
        }
    }
}
```

## Benefits of Full Implementation

### Immediate Benefits:
- **80% less code** to maintain
- **Instant feature unlocking** after purchase
- **No complex state synchronization**
- **Trust StoreKit 2** to handle everything
- **Clean, simple architecture**

### No Technical Debt:
- No migration code needed
- No backwards compatibility concerns
- No feature flags to manage
- No old code to maintain

### Better Performance:
- Fewer services = less memory usage
- Direct StoreKit 2 integration = faster
- No complex dependency chains
- Simpler state management

## Timeline

Since there are no subscribers to migrate:

**Day 1 (Today):**
- [ ] Delete all old StoreKit files
- [ ] Rename simplified files (remove "Simple" prefix)
- [ ] Update all import statements
- [ ] Update all feature gates

**Day 2:**
- [ ] Test in sandbox environment
- [ ] Verify all features work
- [ ] Update any missed references

**Day 3:**
- [ ] Deploy to TestFlight
- [ ] Final testing
- [ ] Ship it! 🚀

## Success! 
You can now have a clean, simple StoreKit 2 implementation without any legacy code or migration complexity!