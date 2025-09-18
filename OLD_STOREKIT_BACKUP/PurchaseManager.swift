/**
 * PurchaseManager.swift
 * Growth App Purchase Flow Orchestration
 *
 * Manages the complete purchase flow including initiation, validation,
 * and integration with subscription entitlements.
 */

import Foundation
import StoreKit
import Combine

/// Service for orchestrating subscription purchase flows
@available(iOS 15.0, *)
@MainActor
class PurchaseManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current purchase state
    @Published var purchaseState: PurchaseState = .idle
    
    /// Last purchase result
    @Published var lastPurchaseResult: PurchaseResult?
    
    /// Current purchase progress message
    @Published var progressMessage: String = ""
    
    // MARK: - Private Properties
    
    private let storeKitService: StoreKitService
    private var cancellables = Set<AnyCancellable>()
    private var transactionObserver: Task<Void, Never>?
    
    // MARK: - Singleton
    
    static let shared = PurchaseManager()
    
    private init(
        storeKitService: StoreKitService
    ) {
        self.storeKitService = storeKitService
        
        setupSubscriptions()
        observeTransactionUpdates()
    }
    
    private convenience init() {
        self.init(
            storeKitService: StoreKitService.shared
        )
    }
    
    deinit {
        transactionObserver?.cancel()
    }
    
    // MARK: - Setup
    
    private func setupSubscriptions() {
        // Listen to StoreKit service state changes
        storeKitService.$isLoadingProducts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.purchaseState = .loadingProducts
                    self?.progressMessage = "Loading subscription options..."
                } else if self?.purchaseState == .loadingProducts {
                    self?.purchaseState = self?.storeKitService.hasAvailableProducts == true ? .readyToPurchase : .idle
                    self?.progressMessage = ""
                }
            }
            .store(in: &cancellables)
    }
    
    /// Observe transaction updates for purchases made outside the app
    private func observeTransactionUpdates() {
        transactionObserver = Task(priority: .background) { [weak self] in
            for await _ in Transaction.updates {
                // Refresh entitlements when transactions change
                await self?.updatePurchasedProducts()
            }
        }
    }
    
    /// Update purchased products using Transaction.currentEntitlements
    private func updatePurchasedProducts() async {
        Logger.info("PurchaseManager: Updating purchased products from currentEntitlements")
        
        // Refresh subscription status
        await storeKitService.updatePurchasedProducts()
        
        // Force subscription state refresh
        await SubscriptionStateManager.shared.refreshState()
        
        // Update feature gate access
        FeatureGateService.shared.refreshAccessState()
    }
    
    // MARK: - Purchase Flow
    
    /// Initiate purchase for a subscription product
    func purchase(productID: String) async -> PurchaseResult {
        Logger.info("PurchaseManager: Starting purchase for product ID: \(productID)")
        Logger.info("PurchaseManager: Environment: \(StoreKitEnvironmentHandler.shared.currentEnvironment.displayName)")
        
        purchaseState = .purchasing
        progressMessage = "Starting purchase..."
        
        // Ensure products are loaded, retry if needed
        if storeKitService.availableProducts.isEmpty {
            Logger.info("PurchaseManager: No products available, attempting to load...")
            
            // Force reload products for TestFlight/Production environments
            await storeKitService.loadProducts()
            
            // Wait for products to load
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            // If still no products, try direct StoreKit load as fallback
            if storeKitService.availableProducts.isEmpty {
                Logger.info("PurchaseManager: Still no products, attempting direct StoreKit product load")
                
                do {
                    let products = try await Product.products(for: SubscriptionProductIDs.allProductIDs)
                    if !products.isEmpty {
                        Logger.info("PurchaseManager: Direct load found \(products.count) products")
                        await storeKitService.updateProducts(products)
                    } else {
                        Logger.error("PurchaseManager: Direct load returned empty products")
                    }
                } catch {
                    Logger.error("PurchaseManager: Direct product load failed: \(error)")
                    Logger.error("PurchaseManager: Error type: \(type(of: error))")
                    if let nsError = error as NSError? {
                        Logger.error("PurchaseManager: Error domain: \(nsError.domain), code: \(nsError.code)")
                    }
                }
            }
        }
        
        // Debug: Check if products are loaded
        Logger.info("PurchaseManager: Available products count: \(storeKitService.availableProducts.count)")
        for product in storeKitService.availableProducts {
            Logger.info("PurchaseManager: Available product - ID: \(product.id)")
        }
        
        // Get the product
        guard let product = storeKitService.product(for: productID) else {
            let error = PurchaseError.invalidProduct
            Logger.error("PurchaseManager: Product not found - ID: \(productID)")
            Logger.error("PurchaseManager: Available product IDs: \(storeKitService.availableProducts.map { $0.id })")
            Logger.error("PurchaseManager: Expected product IDs: \(SubscriptionProductIDs.allProductIDs)")
            let environment = StoreKitEnvironmentHandler.shared.currentEnvironment
            Logger.error("PurchaseManager: Environment: \(environment.displayName)")
            
            // Check if user has an active subscription despite products not loading
            let hasSubscription = storeKitService.hasActiveSubscription
            if hasSubscription {
                Logger.warning("PurchaseManager: User has active subscription but product not found - TestFlight issue")
            }
            
            // In sandbox/app review, provide more helpful error message
            let errorMessage: String
            if environment == .sandbox || environment == .xcode {
                if hasSubscription {
                    errorMessage = "Your subscription is active but products are temporarily unavailable. This is a known TestFlight issue. Please try again later or contact support."
                } else {
                    errorMessage = "Products temporarily unavailable. This may be due to App Store sandbox configuration. Please try again."
                }
            } else {
                errorMessage = "Product not available"
            }
            
            self.purchaseState = .failed(error)
            self.lastPurchaseResult = .failed(error)
            self.progressMessage = errorMessage
            return .failed(error)
        }
        
        Logger.info("PurchaseManager: Found product - ID: \(product.id), Name: \(product.displayName), Price: \(product.displayPrice)")
        
        do {
            self.progressMessage = "Processing purchase..."
            
            // Attempt purchase
            Logger.info("PurchaseManager: Attempting purchase for product: \(product.id)")
            let result = try await product.purchase()
            Logger.info("PurchaseManager: Purchase attempt completed with result type: \(type(of: result))")
            
            return await handlePurchaseResult(result)
            
        } catch {
            let purchaseError = PurchaseError.storeKitError(error)
            Logger.error("PurchaseManager: Purchase failed with error: \(error)")
            Logger.error("PurchaseManager: Purchase error details: \(error.localizedDescription)")
            
            if let storeKitError = error as? StoreKitError {
                Logger.error("PurchaseManager: StoreKitError type: \(storeKitError)")
            }
            
            self.purchaseState = .failed(purchaseError)
            self.lastPurchaseResult = .failed(purchaseError)
            self.progressMessage = "Purchase failed: \(error.localizedDescription)"
            return .failed(purchaseError)
        }
    }
    
    /// Handle the result from StoreKit purchase attempt
    private func handlePurchaseResult(_ result: Product.PurchaseResult) async -> PurchaseResult {
        Logger.info("PurchaseManager: Handling purchase result")
        
        switch result {
        case .success(let verification):
            Logger.info("PurchaseManager: Purchase succeeded, verifying transaction")
            return await handleSuccessfulPurchase(verification)
            
        case .userCancelled:
            Logger.info("PurchaseManager: Purchase was cancelled by user")
            let purchaseResult = PurchaseResult.cancelled
            self.purchaseState = .completed(purchaseResult)
            self.lastPurchaseResult = purchaseResult
            self.progressMessage = ""
            return purchaseResult
            
        case .pending:
            Logger.info("PurchaseManager: Purchase is pending approval")
            let purchaseResult = PurchaseResult.pending
            self.purchaseState = .completed(purchaseResult)
            self.lastPurchaseResult = purchaseResult
            self.progressMessage = "Purchase pending approval..."
            return purchaseResult
            
        @unknown default:
            Logger.error("PurchaseManager: Unknown purchase result type")
            let error = PurchaseError.unknownError
            self.purchaseState = .failed(error)
            self.lastPurchaseResult = .failed(error)
            self.progressMessage = ""
            return .failed(error)
        }
    }
    
    /// Handle successful purchase verification
    private func handleSuccessfulPurchase(_ verification: VerificationResult<Transaction>) async -> PurchaseResult {
        self.purchaseState = .processing
        self.progressMessage = "Verifying purchase..."
        
        do {
            let transaction = try checkVerified(verification)
            
            // Validate with server (integrate with Story 23.0 Firebase Functions)
            self.progressMessage = "Activating subscription..."
            
            let isValid = await validateWithServer(transaction)
            
            if isValid {
                // Update subscription status
                await updatePurchasedProducts()
                
                // Force refresh subscription state
                await SubscriptionStateManager.shared.forceRefresh()
                
                // Notify feature gate service to refresh after state is updated
                await FeatureGateService.shared.forceRefresh()
                
                // Finish the transaction
                await transaction.finish()
                
                let purchaseResult = PurchaseResult.success(transaction)
                self.purchaseState = .completed(purchaseResult)
                self.lastPurchaseResult = purchaseResult
                self.progressMessage = "Subscription activated!"
                
                // Clear progress message after delay
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    self.progressMessage = ""
                }
                
                return purchaseResult
            } else {
                let error = PurchaseError.serverValidationFailed
                self.purchaseState = .failed(error)
                self.lastPurchaseResult = .failed(error)
                self.progressMessage = ""
                return .failed(error)
            }
            
        } catch {
            let purchaseError = PurchaseError.verificationFailed
            self.purchaseState = .failed(purchaseError)
            self.lastPurchaseResult = .failed(purchaseError)
            self.progressMessage = ""
            return .failed(purchaseError)
        }
    }
    
    // MARK: - Server Validation
    
    /// Validate transaction with server (Story 23.0 integration)
    private func validateWithServer(_ transaction: Transaction) async -> Bool {
        // TODO: Integrate with Firebase Functions from Story 23.0
        // For now, return true as basic local validation passed
        // This will be enhanced when Story 23.4 credentials are configured
        
        Logger.info("PurchaseManager: Server validation for transaction \(transaction.id)")
        
        // Simulate server validation delay
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        return true
    }
    
    // MARK: - Restore Purchases
    
    /// Restore previous purchases
    func restorePurchases() async -> RestoreResult {
        purchaseState = .processing
        progressMessage = "Restoring purchases..."
        
        do {
            try await storeKitService.restorePurchases()
            
            // Refresh subscription status after restore
            await updatePurchasedProducts()
            
            // Get current entitlements after restore
            let entitlements = await storeKitService.getCurrentEntitlements()
            
            self.purchaseState = .idle
            self.progressMessage = ""
            
            if entitlements.isEmpty {
                return .noEntitlementsFound
            } else {
                return .success(entitlements)
            }
            
        } catch {
            self.purchaseState = .idle
            self.progressMessage = ""
            
            if let storeKitError = error as? StoreKitError {
                return .failed(.storeKitError(storeKitError))
            } else {
                return .failed(.storeKitError(error))
            }
        }
    }
    
    // MARK: - State Management
    
    /// Reset purchase state to idle
    func resetPurchaseState() {
        purchaseState = .idle
        lastPurchaseResult = nil
        progressMessage = ""
    }
    
    /// Check if purchase flow is currently active
    var isPurchasing: Bool {
        return purchaseState.isLoading
    }
    
    /// Check if ready to start new purchase
    var canStartPurchase: Bool {
        return purchaseState.canPurchase
    }
    
    // MARK: - Helper Methods
    
    /// Verify transaction authenticity
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw PurchaseError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
}

// MARK: - Purchase Manager Extensions

@available(iOS 15.0, *)
extension PurchaseManager {
    
    /// Purchase a subscription tier with specific duration
    func purchase(tier: SubscriptionTier, duration: SubscriptionDuration) async -> PurchaseResult {
        guard let product = SubscriptionProductCatalog.product(for: tier, duration: duration) else {
            return .failed(.invalidProduct)
        }
        
        return await purchase(productID: product.id)
    }
    
    /// Get formatted price for a subscription tier and duration
    func getPrice(for tier: SubscriptionTier, duration: SubscriptionDuration) -> String? {
        guard let catalogProduct = SubscriptionProductCatalog.product(for: tier, duration: duration),
              let storeProduct = storeKitService.product(for: catalogProduct.id) else {
            return nil
        }
        
        return storeProduct.displayPrice
    }
}