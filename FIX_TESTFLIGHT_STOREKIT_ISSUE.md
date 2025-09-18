# TestFlight StoreKit Products Not Found - Fix

## Problem
Products not loading in TestFlight with error: "Finance Authentication Error No delegate to perform authentication"

## Root Cause
The sandbox environment is failing to authenticate the user account, causing the products API to return empty results.

## Solution

### 1. Ensure User is Signed into Sandbox Account
**TestFlight users must be signed into their sandbox Apple ID account:**
- Go to Settings → App Store
- Scroll to bottom → Sandbox Account
- Sign in with sandbox test account (if not already)

### 2. Update StoreKitService to Handle Sandbox Authentication

Add this to `StoreKitService.swift`:

```swift
// Add after line 51 in loadProducts()
do {
    print("[StoreKit] Loading products for IDs: \(SubscriptionProductIDs.allProductIDs)")
    
    // Force AppStore sync for TestFlight to ensure authentication
    #if !targetEnvironment(simulator)
    if Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt" {
        print("[StoreKit] Detected sandbox environment, syncing with App Store...")
        try? await AppStore.sync()
    }
    #endif
    
    availableProducts = try await Product.products(for: SubscriptionProductIDs.allProductIDs)
    
    if availableProducts.isEmpty {
        print("[StoreKit] Warning: No products loaded. Possible causes:")
        print("  - Not signed into sandbox account (Settings > App Store > Sandbox Account)")
        print("  - Products not approved in App Store Connect")
        print("  - Bundle ID mismatch")
    } else {
        print("[StoreKit] Successfully loaded \(availableProducts.count) products")
    }
    
    productsLoaded = true
} catch {
    print("[StoreKit] Failed to load products: \(error)")
    print("[StoreKit] Error details: \(error.localizedDescription)")
}
```

### 3. Add Retry Logic for TestFlight

Create a new method in `StoreKitService.swift`:

```swift
// Add after updatePurchasedProducts() method
public func loadProductsWithRetry() async {
    for attempt in 1...3 {
        print("[StoreKit] Loading products, attempt \(attempt)...")
        await loadProducts()
        
        if !availableProducts.isEmpty {
            print("[StoreKit] Products loaded successfully on attempt \(attempt)")
            break
        }
        
        if attempt < 3 {
            print("[StoreKit] No products loaded, retrying in 2 seconds...")
            try? await Task.sleep(nanoseconds: 2_000_000_000)
        }
    }
    
    if availableProducts.isEmpty {
        print("[StoreKit] Failed to load products after 3 attempts")
    }
}
```

### 4. Update PaywallView Usage

In any view that shows the paywall, update the onAppear:

```swift
.onAppear {
    Task {
        await StoreKitService.shared.loadProductsWithRetry()
    }
}
```

### 5. Add TestFlight Specific Instructions

Create a TestFlight note for users:

```
If subscriptions don't appear:
1. Go to Settings → App Store
2. Scroll to bottom → Sandbox Account
3. Sign in with your Apple ID
4. Restart the app
```

## Testing Instructions

1. **Before uploading to TestFlight:**
   - Ensure using "Growth Production" scheme
   - Archive with proper provisioning profile
   - NO StoreKit configuration file in Production scheme

2. **In TestFlight:**
   - Install TestFlight build
   - Ensure signed into sandbox account
   - Open app and navigate to subscription screen
   - Products should load after 1-3 attempts

## Verification

Check Console logs for:
- `[StoreKit] Loading products for IDs:`
- `[StoreKit] Successfully loaded 3 products`

If still seeing empty products, verify:
1. Products are "Ready for Sale" in App Store Connect
2. Bundle ID exactly matches: `com.growthlabs.growthmethod`
3. Products IDs match exactly:
   - `com.growthlabs.growthmethod.subscription.premium.yearly`
   - `com.growthlabs.growthmethod.subscription.premium.quarterly`
   - `com.growthlabs.growthmethod.subscription.premium.weekly`