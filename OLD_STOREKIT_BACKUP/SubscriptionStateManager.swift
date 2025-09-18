//
//  SubscriptionStateManager.swift
//  Growth
//
//  Created by Growth on 1/19/25.
//

import Foundation
import Combine
import StoreKit
import UIKit
import FirebaseAuth

/// Central coordinator for subscription state management
/// This service acts as the single source of truth for subscription state across the app
@available(iOS 15.0, *)
@MainActor
public final class SubscriptionStateManager: ObservableObject {
    
    // MARK: - Singleton
    
    public static let shared = SubscriptionStateManager()
    
    // MARK: - Published Properties
    
    /// Current subscription state
    @Published public private(set) var subscriptionState: SubscriptionState = .nonSubscribed
    
    /// Loading state for UI updates
    @Published public private(set) var isLoading: Bool = false
    
    /// Last error encountered
    @Published public private(set) var lastError: Error?
    
    /// Whether state is being synchronized
    @Published public private(set) var isSynchronizing: Bool = false
    
    /// Whether server validation is enabled
    @Published public private(set) var isServerValidationEnabled: Bool = true
    
    /// Last validation result
    @Published public private(set) var lastValidationResult: ValidationResult?
    
    // MARK: - Private Properties
    
    private let storeKitService = StoreKitService.shared
    private let entitlementService = SubscriptionEntitlementService.shared
    private let purchaseManager = PurchaseManager.shared
    private let serverValidator = SubscriptionServerValidator.shared
    private let firebaseClient = FirebaseClient.shared
    private let syncService = SubscriptionSyncService.shared
    
    private var cancellables = Set<AnyCancellable>()
    private var transactionUpdateTask: Task<Void, Never>?
    private var stateRefreshTimer: Timer?
    private let stateRefreshInterval: TimeInterval = 15 * 60 // 15 minutes
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    private let validationQueue = DispatchQueue(label: "com.growth.subscription.validation", qos: .userInitiated)
    private var pendingValidations: [ValidationRequest] = []
    
    // MARK: - Validation Request
    
    private struct ValidationRequest {
        let transactionId: String
        let productId: String
        let retryCount: Int
        let timestamp: Date
    }
    
    // MARK: - Initialization
    
    private init() {
        setupBindings()
        setupNotifications()
        loadPersistedState()
        
        // Set the state manager reference after initialization
        syncService.setStateManager(self)
        
        Task {
            await refreshState()
        }
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Start transaction update monitoring task
        transactionUpdateTask = Task { [weak self] in
            await self?.monitorTransactionUpdates()
        }
        
        // Monitor purchase manager for purchase completions
        purchaseManager.$lastPurchaseResult
            .compactMap { $0 }
            .sink { [weak self] result in
                Task { @MainActor in
                    await self?.handlePurchaseResult(result)
                }
            }
            .store(in: &cancellables)
        
        // Monitor entitlement service for tier changes
        entitlementService.$currentTier
            .removeDuplicates()
            .sink { [weak self] tier in
                Task { @MainActor in
                    await self?.handleTierChange(tier)
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupNotifications() {
        // App lifecycle notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        // Start periodic refresh timer
        startStateRefreshTimer()
    }
    
    // MARK: - Transaction Monitoring
    
    private func monitorTransactionUpdates() async {
        for await _ in Transaction.updates {
            await refreshState()
        }
    }
    
    // MARK: - State Management
    
    /// Refreshes subscription state from all sources
    public func refreshState() async {
        guard !isSynchronizing else { return }
        
        isSynchronizing = true
        defer { isSynchronizing = false }
        
        // First, check StoreKit for latest transactions
        let entitlements = await storeKitService.getCurrentEntitlements()
        
        // Build state from entitlements
        let newState = await buildStateFromEntitlements(entitlements)
        
        // Attempt server validation if connected
        if let validatedState = await attemptServerValidation(for: newState) {
            updateState(validatedState)
        } else {
            // Use local state if server validation fails
            updateState(newState.validated(from: SubscriptionState.ValidationSource.local))
        }
        
        // Process any pending validations
        await processPendingValidations()
    }
    
    /// Forces a complete state refresh
    public func forceRefresh() async {
        isLoading = true
        defer { isLoading = false }
        
        // Clear cached data
        SubscriptionState.clearPersisted()
        
        // Refresh from sources
        await refreshState()
    }
    
    // MARK: - State Building
    
    private func buildStateFromEntitlements(_ transactions: [Transaction]) async -> SubscriptionState {
        // Find the highest tier subscription
        var highestTier: SubscriptionTier = .none
        var latestTransaction: Transaction?
        var productId: String?
        
        for transaction in transactions {
            let tier = SubscriptionTier.from(productId: transaction.productID)
            if tier.priority > highestTier.priority {
                highestTier = tier
                latestTransaction = transaction
                productId = transaction.productID
            }
        }
        
        // Build state based on transaction
        if let transaction = latestTransaction {
            let expirationDate = transaction.expirationDate
            let isExpired = expirationDate.map { $0 < Date() } ?? false
            
            return SubscriptionState(
                tier: isExpired ? .none : highestTier,
                status: isExpired ? .expired : .active,
                expirationDate: expirationDate,
                purchaseDate: transaction.purchaseDate,
                isTrialActive: {
                    if #available(iOS 17.2, *) {
                        return transaction.offer?.type == .introductory
                    } else {
                        return false
                    }
                }(),
                trialExpirationDate: {
                    if #available(iOS 17.2, *) {
                        return transaction.offer?.type == .introductory ? expirationDate : nil
                    } else {
                        return nil
                    }
                }(),
                autoRenewalEnabled: !transaction.isUpgraded,
                lastUpdated: Date(),
                validationSource: .local,
                productId: productId,
                transactionId: "\(transaction.id)"
            )
        }
        
        return .nonSubscribed
    }
    
    // MARK: - Server Validation
    
    private func attemptServerValidation(for state: SubscriptionState) async -> SubscriptionState? {
        guard isServerValidationEnabled else { return nil }
        
        // For iOS 18+, we should use AppTransaction, but for compatibility we'll use the current transaction ID
        // In a production app, you would send the transaction ID to your server for validation
        guard let transactionId = state.transactionId else {
            Logger.info("⚠️ No transaction ID for server validation")
            return nil
        }
        
        // Create a pseudo-receipt for validation (in production, use AppTransaction.shared)
        let receiptString = transactionId
        
        do {
            // Attempt server validation
            let validationResult = try await serverValidator.validateReceipt(
                receiptString,
                forceRefresh: state.isStale
            )
            
            // Store validation result
            lastValidationResult = validationResult
            
            // Cache successful validation
            if validationResult.isValid {
                validationResult.cache()
            }
            
            return validationResult.state
            
        } catch {
            Logger.info("❌ Server validation failed: \(error)")
            lastError = error
            
            // Queue for retry if network issue
            if let validationError = error as? SubscriptionServerValidator.ValidationError {
                switch validationError {
                case .noNetwork, .serverUnavailable:
                    if let transactionId = state.transactionId,
                       let productId = state.productId {
                        queueValidation(transactionId: transactionId, productId: productId)
                    }
                default:
                    break
                }
            }
            
            return nil
        }
    }
    
    private func processPendingValidations() async {
        // Process any queued validation requests
        let requests = pendingValidations
        pendingValidations.removeAll()
        
        for request in requests {
            // TODO: Retry validation when server is available
            Logger.info("📋 Pending validation for transaction: \(request.transactionId)")
        }
    }
    
    // MARK: - State Updates
    
    private func updateState(_ newState: SubscriptionState) {
        subscriptionState = newState
        newState.persist()
        
        // Sync to Firestore for cross-device access
        Task {
            await syncService.syncSubscriptionState()
        }
    }
    
    private func loadPersistedState() {
        if let persistedState = SubscriptionState.loadPersisted() {
            // Use persisted state if not stale
            if !persistedState.isStale {
                subscriptionState = persistedState
            }
        }
    }
    
    // MARK: - Event Handlers
    
    private func handleEntitlementUpdate(_ transactions: [Transaction]) async {
        let newState = await buildStateFromEntitlements(transactions)
        
        // Only update if state actually changed
        if newState.tier != subscriptionState.tier ||
           newState.status != subscriptionState.status {
            updateState(newState)
        }
    }
    
    private func handlePurchaseResult(_ result: PurchaseResult) async {
        switch result {
        case .success(_):
            // Refresh state after successful purchase
            await refreshState()
            
        case .cancelled, .pending:
            break
            
        case .failed(let error):
            lastError = error
        }
    }
    
    private func handleTierChange(_ tier: SubscriptionTier) async {
        // Only update if tier actually changed
        if tier != subscriptionState.tier {
            var updatedState = subscriptionState
            updatedState = SubscriptionState(
                tier: tier,
                status: tier == .none ? .none : subscriptionState.status,
                expirationDate: subscriptionState.expirationDate,
                purchaseDate: subscriptionState.purchaseDate,
                isTrialActive: subscriptionState.isTrialActive,
                trialExpirationDate: subscriptionState.trialExpirationDate,
                autoRenewalEnabled: subscriptionState.autoRenewalEnabled,
                lastUpdated: Date(),
                validationSource: subscriptionState.validationSource,
                productId: subscriptionState.productId,
                transactionId: subscriptionState.transactionId
            )
            updateState(updatedState)
        }
    }
    
    // MARK: - App Lifecycle
    
    @objc private func handleAppDidBecomeActive() {
        Task {
            await refreshState()
        }
        startStateRefreshTimer()
    }
    
    @objc private func handleAppWillResignActive() {
        stopStateRefreshTimer()
        subscriptionState.persist()
    }
    
    // MARK: - Timer Management
    
    private func startStateRefreshTimer() {
        stopStateRefreshTimer()
        
        stateRefreshTimer = Timer.scheduledTimer(withTimeInterval: stateRefreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshState()
            }
        }
    }
    
    private func stopStateRefreshTimer() {
        stateRefreshTimer?.invalidate()
        stateRefreshTimer = nil
    }
    
    // MARK: - Offline Queue
    
    /// Queues a validation request for later processing
    public func queueValidation(transactionId: String, productId: String) {
        let request = ValidationRequest(
            transactionId: transactionId,
            productId: productId,
            retryCount: 0,
            timestamp: Date()
        )
        
        Task { @MainActor in
            pendingValidations.append(request)
        }
    }
    
    // MARK: - Webhook Processing
    
    /// Processes a webhook update from App Store Server Notifications
    public func handleWebhookUpdate(_ update: WebhookUpdate) async {
        do {
            // Convert webhook update to subscription state
            let newState = try await serverValidator.processWebhookUpdate(update)
            
            // Update state with server-validated data
            updateState(newState)
            
            // Store validation result
            lastValidationResult = ValidationResult(
                state: newState,
                source: .webhook,
                serverReceiptHash: update.transactionId
            )
            
            Logger.info("✅ Processed webhook update: \(update.eventType.rawValue)")
            
        } catch {
            Logger.info("❌ Failed to process webhook update: \(error)")
            lastError = error
        }
    }
    
    // MARK: - Public Methods
    
    /// Checks if user has access to a specific feature
    public func hasAccess(to feature: String) -> Bool {
        guard subscriptionState.hasActiveAccess else { return false }
        
        // Convert string to FeatureType
        guard let featureType = FeatureType(rawValue: feature) else {
            Logger.info("⚠️ Unknown feature type: \(feature)")
            return false
        }
        
        return entitlementService.hasFeature(featureType)
    }
    
    /// Gets the current subscription tier
    public var currentTier: SubscriptionTier {
        subscriptionState.hasActiveAccess ? subscriptionState.tier : .none
    }
    
    /// Initiates a purchase for a subscription product
    public func purchase(productId: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let result = await purchaseManager.purchase(productID: productId)
        
        // Handle purchase result
        switch result {
        case .success:
            // Success handled by purchase result handler
            break
        case .failed(let error):
            throw error
        case .cancelled:
            throw PurchaseError.userCancelled
        case .pending:
            // Pending purchases don't throw
            break
        }
    }
    
    /// Restores previous purchases
    public func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }
        
        let result = await purchaseManager.restorePurchases()
        
        // Handle restore result
        switch result {
        case .success:
            await refreshState()
        case .failed(let error):
            throw error
        case .noEntitlementsFound:
            // No entitlements to restore, but not an error
            await refreshState()
        }
    }
    
    // MARK: - Debug
    
    public func debugPrintState() {
        Logger.info("📊 SubscriptionStateManager Debug:")
        Logger.info("Current State: \(subscriptionState)")
        Logger.info("Pending Validations: \(pendingValidations.count)")
        Logger.info("Is Synchronizing: \(isSynchronizing)")
    }
}

// MARK: - Error Types

extension SubscriptionStateManager {
    enum PurchaseError: LocalizedError {
        case userCancelled
        
        var errorDescription: String? {
            switch self {
            case .userCancelled:
                return "Purchase was cancelled by user"
            }
        }
    }
    
    enum StateError: LocalizedError {
        case invalidState
        case validationFailed
        case syncFailed
        
        var errorDescription: String? {
            switch self {
            case .invalidState:
                return "Invalid subscription state"
            case .validationFailed:
                return "Failed to validate subscription"
            case .syncFailed:
                return "Failed to synchronize subscription state"
            }
        }
    }
}