/**
 * SimplifiedPurchaseManager.swift
 * Growth App Simplified StoreKit 2 Implementation
 *
 * Based on Apple's recommended patterns and RevenueCat demo
 * Replaces complex multi-manager setup with single, clean implementation
 */

import Foundation
import StoreKit

@MainActor
class SimplifiedPurchaseManager: NSObject, ObservableObject {
    
    // MARK: - Product Configuration
    private let productIds = [
        "com.growthlabs.growthmethod.subscription.premium.weekly",
        "com.growthlabs.growthmethod.subscription.premium.quarterly", 
        "com.growthlabs.growthmethod.subscription.premium.yearly"
    ]
    
    // MARK: - Published State
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs = Set<String>()
    @Published var isLoading = false
    
    // MARK: - Private State
    private var productsLoaded = false
    private var updates: Task<Void, Never>? = nil
    private let entitlementManager: SimplifiedEntitlementManager
    
    // MARK: - Computed Properties
    var hasActiveSubscription: Bool {
        return !purchasedProductIDs.isEmpty
    }
    
    var availableProducts: [Product] {
        return products
    }
    
    // MARK: - Initialization
    init(entitlementManager: SimplifiedEntitlementManager) {
        self.entitlementManager = entitlementManager
        super.init()
        self.updates = observeTransactionUpdates()
        
        // Support promoted purchases from App Store
        SKPaymentQueue.default().add(self)
        
        // Check for existing entitlements on startup
        Task {
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        self.updates?.cancel()
        SKPaymentQueue.default().remove(self)
    }
    
    // MARK: - Product Loading
    func loadProducts() async throws {
        guard !self.productsLoaded else { return }
        
        do {
            print("📱 Loading StoreKit products...")
            self.products = try await Product.products(for: productIds)
            self.productsLoaded = true
            print("✅ Loaded \(products.count) products")
        } catch {
            print("❌ Failed to load products: \(error)")
            throw error
        }
    }
    
    // MARK: - Purchase Flow
    func purchase(productID: String) async -> Bool {
        isLoading = true
        defer { isLoading = false }
        
        guard let product = products.first(where: { $0.id == productID }) else {
            print("❌ Product not found: \(productID)")
            return false
        }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case let .success(.verified(transaction)):
                print("✅ Purchase successful: \(transaction.productID)")
                
                // Immediately update entitlements for this transaction
                self.purchasedProductIDs.insert(transaction.productID)
                self.entitlementManager.hasPremium = true
                print("📱 Immediate entitlement granted: hasPremium = true")
                
                // Finish the transaction AFTER setting entitlements
                await transaction.finish()
                
                // Force a sync with App Store to ensure entitlements are up to date
                Task {
                    try? await AppStore.sync()
                    await self.updatePurchasedProducts()
                }
                
                return true
            case let .success(.unverified(_, error)):
                print("⚠️ Purchase unverified: \(error)")
                // Handle unverified transactions - could be jailbroken device
                return false
            case .pending:
                print("⏳ Purchase pending - waiting for approval")
                // Transaction waiting on SCA or Ask to Buy
                return false
            case .userCancelled:
                print("🚫 Purchase cancelled by user")
                return false
            @unknown default:
                return false
            }
        } catch {
            print("❌ Purchase failed: \(error)")
            return false
        }
    }
    
    // MARK: - Entitlement Updates
    func updatePurchasedProducts() async {
        var tempPurchasedIDs = Set<String>()
        
        // Use StoreKit 2's built-in currentEntitlements
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }
            
            // Only include active (non-revoked) transactions
            if transaction.revocationDate == nil {
                tempPurchasedIDs.insert(transaction.productID)
                print("📱 Found active subscription: \(transaction.productID)")
            }
        }
        
        // If no entitlements found, also check unfinished transactions
        if tempPurchasedIDs.isEmpty {
            print("⚠️ No currentEntitlements found, checking unfinished transactions...")
            for await result in Transaction.unfinished {
                guard case .verified(let transaction) = result else {
                    continue
                }
                
                // Check if this is a valid subscription product
                if productIds.contains(transaction.productID) && transaction.revocationDate == nil {
                    tempPurchasedIDs.insert(transaction.productID)
                    print("📱 Found unfinished transaction: \(transaction.productID)")
                    // Finish the transaction
                    await transaction.finish()
                }
            }
        }
        
        // Update state only if we found changes or if this is a reset (empty set)
        if self.purchasedProductIDs != tempPurchasedIDs {
            self.purchasedProductIDs = tempPurchasedIDs
            
            // Update entitlement flags
            self.entitlementManager.hasPremium = !tempPurchasedIDs.isEmpty
            
            print("📱 Updated entitlements: \(tempPurchasedIDs.count) active")
            if !tempPurchasedIDs.isEmpty {
                print("📱 Active products: \(tempPurchasedIDs.joined(separator: ", "))")
            }
        } else {
            print("📱 No entitlement changes detected")
        }
    }
    
    // MARK: - Restore Purchases
    func restorePurchases() async throws {
        print("🔄 Restoring purchases...")
        try await AppStore.sync()
        await updatePurchasedProducts()
        print("✅ Purchases restored")
    }
    
    // MARK: - Transaction Listener
    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) { [unowned self] in
            for await _ in Transaction.updates {
                print("📱 Transaction update received")
                // Update entitlements whenever transactions change
                await self.updatePurchasedProducts()
            }
        }
    }
    
    // MARK: - Helper Methods
    func product(for productId: String) -> Product? {
        return products.first { $0.id == productId }
    }
    
    func isProductPurchased(_ productId: String) -> Bool {
        return purchasedProductIDs.contains(productId)
    }
    
    func hasProduct(_ product: Product) -> Bool {
        return purchasedProductIDs.contains(product.id)
    }
}

// MARK: - App Store Promoted Purchases Support
extension SimplifiedPurchaseManager: SKPaymentTransactionObserver {
    nonisolated func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        // StoreKit 2 handles transactions automatically
    }
    
    nonisolated func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        // Allow promoted purchases from App Store
        return true
    }
}