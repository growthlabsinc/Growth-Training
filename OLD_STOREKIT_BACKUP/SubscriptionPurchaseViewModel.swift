/**
 * SubscriptionPurchaseViewModel.swift
 * Growth App Subscription Purchase View Model
 *
 * Manages purchase flow state and coordinates between UI and purchase services
 * for subscription purchase flows.
 */

import Foundation
import Combine
import StoreKit

/// View model for managing subscription purchase flows
@available(iOS 15.0, *)
@MainActor
class SubscriptionPurchaseViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Available subscription products
    @Published var availableProducts: [Product] = []
    
    /// Current purchase state
    @Published var purchaseState: PurchaseState = .idle
    
    /// Purchase progress message
    @Published var progressMessage: String = ""
    
    /// Selected product for purchase
    @Published var selectedProduct: Product?
    
    /// Last purchase result
    @Published var lastPurchaseResult: PurchaseResult?
    
    /// Loading state for product loading
    @Published var isLoadingProducts: Bool = false
    
    /// Error message for display
    @Published var errorMessage: String?
    
    /// Show success confirmation
    @Published var showSuccessConfirmation: Bool = false
    
    /// Show error alert
    @Published var showErrorAlert: Bool = false
    
    // MARK: - Private Properties
    
    private let storeKitService: StoreKitService
    private let purchaseManager: PurchaseManager
    private let entitlementManager = EntitlementManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        storeKitService: StoreKitService,
        purchaseManager: PurchaseManager
    ) {
        self.storeKitService = storeKitService
        self.purchaseManager = purchaseManager
        
        setupSubscriptions()
        loadProductsIfNeeded()
    }
    
    convenience init() {
        self.init(
            storeKitService: StoreKitService.shared,
            purchaseManager: PurchaseManager.shared
        )
    }
    
    // MARK: - Setup
    
    private func setupSubscriptions() {
        // Listen to StoreKit service product updates
        storeKitService.$availableProducts
            .receive(on: DispatchQueue.main)
            .assign(to: \.availableProducts, on: self)
            .store(in: &cancellables)
        
        storeKitService.$isLoadingProducts
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLoadingProducts, on: self)
            .store(in: &cancellables)
        
        // Listen to purchase manager state updates
        purchaseManager.$purchaseState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.purchaseState = state
                self?.handlePurchaseStateChange(state)
            }
            .store(in: &cancellables)
        
        purchaseManager.$progressMessage
            .receive(on: DispatchQueue.main)
            .assign(to: \.progressMessage, on: self)
            .store(in: &cancellables)
        
        purchaseManager.$lastPurchaseResult
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.lastPurchaseResult = result
                self?.handlePurchaseResult(result)
            }
            .store(in: &cancellables)
        
        // Listen to entitlement changes
        entitlementManager.$hasActiveSubscription
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hasSubscription in
                if hasSubscription {
                    // Clear purchase state if subscription becomes active
                    self?.resetPurchaseFlow()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Product Loading
    
    /// Load products if not already loaded
    func loadProductsIfNeeded() {
        if availableProducts.isEmpty && !isLoadingProducts {
            Task {
                Logger.info("SubscriptionPurchaseViewModel: Starting product load")
                await storeKitService.loadProducts()
                
                // Log the result
                if self.availableProducts.isEmpty {
                    Logger.error("SubscriptionPurchaseViewModel: No products loaded from App Store Connect")
                    Logger.error("Expected product IDs: \(SubscriptionProductIDs.allProductIDs)")
                    self.errorMessage = "Subscription options are not available. Please try again later."
                } else {
                    Logger.info("SubscriptionPurchaseViewModel: Successfully loaded \(self.availableProducts.count) products")
                }
            }
        }
    }
    
    /// Force reload products
    func reloadProducts() {
        Task {
            Logger.info("SubscriptionPurchaseViewModel: Force reloading products")
            await storeKitService.loadProducts()
            
            // Log the result
            if self.availableProducts.isEmpty {
                Logger.error("SubscriptionPurchaseViewModel: No products loaded after reload")
                self.errorMessage = "Subscription options are not available. Please try again later."
            } else {
                Logger.info("SubscriptionPurchaseViewModel: Reload successful - \(self.availableProducts.count) products")
                self.errorMessage = nil
            }
        }
    }
    
    // MARK: - Purchase Flow
    
    /// Start purchase flow for selected product
    func purchaseSelectedProduct() {
        guard let product = selectedProduct else {
            showError("No product selected")
            return
        }
        
        Task {
            await purchase(product: product)
        }
    }
    
    /// Purchase a specific product
    func purchase(product: Product) async {
        selectedProduct = product
        
        let result = await purchaseManager.purchase(productID: product.id)
        
        // Result handling is managed through Combine subscriptions
        Logger.info("SubscriptionPurchaseViewModel: Purchase completed with result: \(result)")
    }
    
    /// Purchase by tier and duration
    func purchase(tier: SubscriptionTier, duration: SubscriptionDuration) async {
        guard let product = availableProducts.first(where: { product in
            SubscriptionProductIDs.tier(for: product.id) == tier &&
            SubscriptionProductIDs.duration(for: product.id) == duration
        }) else {
            showError("Product not available")
            return
        }
        
        await purchase(product: product)
    }
    
    // MARK: - Restore Purchases
    
    /// Restore previous purchases
    func restorePurchases() {
        Task {
            let result = await purchaseManager.restorePurchases()
            
            switch result {
            case .success(let transactions):
                self.showSuccessMessage("Restored \(transactions.count) subscription(s)")
            case .failed(let error):
                self.showError(error.localizedDescription)
            case .noEntitlementsFound:
                self.showError("No previous purchases found")
            }
        }
    }
    
    // MARK: - State Management
    
    /// Handle purchase state changes
    private func handlePurchaseStateChange(_ state: PurchaseState) {
        switch state {
        case .idle, .readyToPurchase:
            errorMessage = nil
            showErrorAlert = false
            
        case .loadingProducts, .purchasing, .processing:
            errorMessage = nil
            showErrorAlert = false
            
        case .completed(let result):
            handlePurchaseResult(result)
            
        case .failed(let error):
            showError(error.localizedDescription)
        }
    }
    
    /// Handle purchase results
    private func handlePurchaseResult(_ result: PurchaseResult?) {
        guard let result = result else { return }
        
        switch result {
        case .success:
            showSuccessConfirmation = true
            selectedProduct = nil
            
        case .cancelled:
            // User cancelled, no action needed
            selectedProduct = nil
            
        case .failed(let error):
            showError(error.localizedDescription)
            
        case .pending:
            showSuccessMessage("Purchase is pending approval")
        }
    }
    
    /// Show error message
    private func showError(_ message: String) {
        errorMessage = message
        showErrorAlert = true
    }
    
    /// Show success message temporarily
    private func showSuccessMessage(_ message: String) {
        progressMessage = message
        
        // Clear message after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if self.progressMessage == message {
                self.progressMessage = ""
            }
        }
    }
    
    /// Reset purchase flow
    func resetPurchaseFlow() {
        purchaseManager.resetPurchaseState()
        selectedProduct = nil
        errorMessage = nil
        showErrorAlert = false
        showSuccessConfirmation = false
    }
    
    // MARK: - Product Information
    
    /// Get products for a specific tier
    func products(for tier: SubscriptionTier) -> [Product] {
        return availableProducts.filter { product in
            SubscriptionProductIDs.tier(for: product.id) == tier
        }
    }
    
    /// Get products for a specific duration
    func products(for duration: SubscriptionDuration) -> [Product] {
        return availableProducts.filter { product in
            SubscriptionProductIDs.duration(for: product.id) == duration
        }
    }
    
    /// Get formatted price for product
    func formattedPrice(for product: Product) -> String {
        return product.displayPrice
    }
    
    /// Get subscription tier for product
    func tier(for product: Product) -> SubscriptionTier {
        return SubscriptionProductIDs.tier(for: product.id)
    }
    
    /// Get subscription duration for product
    func duration(for product: Product) -> SubscriptionDuration {
        return SubscriptionProductIDs.duration(for: product.id) ?? .quarterly
    }
    
    /// Check if purchase is currently in progress
    var isPurchasing: Bool {
        return purchaseState.isLoading
    }
    
    /// Check if products are ready for purchase
    var canPurchase: Bool {
        return !availableProducts.isEmpty && !isPurchasing
    }
    
    /// Get value proposition for a product
    func valueProposition(for product: Product) -> String {
        guard let catalogProduct = SubscriptionProductCatalog.product(for: product.id) else {
            return product.description
        }
        
        return catalogProduct.description
    }
}

// MARK: - Convenience Extensions

@available(iOS 15.0, *)
extension SubscriptionPurchaseViewModel {
    
    /// Get all available tiers sorted by hierarchy
    var availableTiers: [SubscriptionTier] {
        let tiers = Set(availableProducts.map { SubscriptionProductIDs.tier(for: $0.id) })
        return tiers.sorted { $0.hierarchyLevel < $1.hierarchyLevel }
    }
    
    /// Get weekly and yearly options for each tier
    var tierOptions: [(tier: SubscriptionTier, weekly: Product?, yearly: Product?)] {
        return availableTiers.map { tier in
            let weeklyProduct = availableProducts.first { product in
                SubscriptionProductIDs.tier(for: product.id) == tier &&
                SubscriptionProductIDs.duration(for: product.id) == .weekly
            }
            
            let yearlyProduct = availableProducts.first { product in
                SubscriptionProductIDs.tier(for: product.id) == tier &&
                SubscriptionProductIDs.duration(for: product.id) == .yearly
            }
            
            return (tier: tier, weekly: weeklyProduct, yearly: yearlyProduct)
        }
    }
}