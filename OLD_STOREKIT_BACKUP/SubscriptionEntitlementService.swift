/**
 * SubscriptionEntitlementService.swift
 * Growth App Subscription Entitlement Management
 *
 * Manages subscription validation, feature access checking, and entitlement caching
 * for the Growth app subscription system.
 */

import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth
import StoreKit

/// Service responsible for managing subscription entitlements and feature access
class SubscriptionEntitlementService: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current user's subscription tier
    @Published var currentTier: SubscriptionTier = .none
    
    /// Whether subscription is currently active (not expired)
    @Published var isSubscriptionActive: Bool = false
    
    /// Current subscription expiration date
    @Published var expirationDate: Date?
    
    /// Whether subscription data is currently being refreshed
    @Published var isRefreshing: Bool = false
    
    /// Last error encountered during subscription operations
    @Published var lastError: Error?
    
    // MARK: - Private Properties
    
    private let userService: UserService
    private let firestore = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    /// Cache for subscription status to avoid frequent API calls
    private var subscriptionCache: SubscriptionCache?
    
    /// Cache expiration time (15 minutes)
    private let cacheExpirationInterval: TimeInterval = 15 * 60
    
    /// Current user data cache
    private var currentUser: User?
    
    /// Firebase Auth state listener handle
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    // MARK: - Initialization
    
    init(userService: UserService = UserService.shared) {
        self.userService = userService
        setupSubscriptions()
        loadCachedSubscriptionData()
    }
    
    deinit {
        // Remove Firebase Auth state listener
        if let handle = authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - Setup
    
    private func setupSubscriptions() {
        // Listen to Firebase Auth state changes to update subscription status
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            if let userId = user?.uid {
                self?.loadUserAndUpdateSubscription(userId: userId)
            } else {
                self?.updateSubscriptionFromUser(nil)
            }
        }
    }
    
    // MARK: - Subscription Status Management
    
    /// Load user data and update subscription status
    private func loadUserAndUpdateSubscription(userId: String) {
        userService.fetchUser(userId: userId) { [weak self] result in
            // Ensure we safely capture the result before dispatching
            let capturedResult = result
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                switch capturedResult {
                case .success(let user):
                    self.currentUser = user
                    self.updateSubscriptionFromUser(user)
                case .failure(let error):
                    Logger.info("SubscriptionEntitlementService: Failed to load user: \(error)")
                    self.currentUser = nil
                    self.updateSubscriptionFromUser(nil)
                }
            }
        }
    }
    
    /// Updates subscription status from user model
    private func updateSubscriptionFromUser(_ user: User?) {
        guard let user = user else {
            currentTier = SubscriptionTier.none
            isSubscriptionActive = false
            expirationDate = nil
            return
        }
        
        currentTier = user.currentSubscriptionTier ?? SubscriptionTier.none
        expirationDate = user.subscriptionExpirationDate
        
        // Check if subscription is still active
        if let expiration = user.subscriptionExpirationDate {
            isSubscriptionActive = expiration > Date()
        } else {
            isSubscriptionActive = false
        }
        
        // If subscription is expired, update tier to none
        if !isSubscriptionActive && currentTier != SubscriptionTier.none {
            currentTier = SubscriptionTier.none
            Task {
                await updateUserSubscriptionTier(SubscriptionTier.none)
            }
        }
    }
    
    /// Refreshes subscription status from server
    func refreshSubscriptionStatus() async {
        guard !isRefreshing else { return }
        
        await MainActor.run {
            isRefreshing = true
            lastError = nil
        }
        
        do {
            // Check cache first
            if let cached = getCachedSubscription(), !cached.isExpired {
                await MainActor.run {
                    self.updateFromCache(cached)
                    self.isRefreshing = false
                }
                return
            }
            
            // Validate with server (requires Story 23.4 credentials)
            let validatedSubscription = try await validateSubscriptionWithServer()
            
            // Update cache
            cacheSubscriptionData(validatedSubscription)
            
            // Update user model
            await updateUserSubscriptionTier(validatedSubscription.tier)
            
            await MainActor.run {
                self.currentTier = validatedSubscription.tier
                self.expirationDate = validatedSubscription.expirationDate
                self.isSubscriptionActive = validatedSubscription.isActive
                self.isRefreshing = false
            }
            
        } catch {
            await MainActor.run {
                self.lastError = error
                self.isRefreshing = false
            }
        }
    }
    
    // MARK: - Feature Access Validation
    
    /// Check if user has access to a specific feature
    func hasFeature(_ feature: FeatureType) -> Bool {
        return currentTier.entitlements.hasFeature(feature)
    }
    
    /// Check if user has access to all growth methods
    func hasAllMethodsAccess() -> Bool {
        return hasFeature(.customRoutines)
    }
    
    /// Check if user has AI coach access
    func hasAICoachAccess() -> Bool {
        return hasFeature(.aiCoach)
    }
    
    /// Check if user has personal coaching access
    func hasPersonalCoachingAccess() -> Bool {
        return hasFeature(.prioritySupport)
    }
    
    /// Check if user has priority support
    func hasPrioritySupportAccess() -> Bool {
        return hasFeature(.prioritySupport)
    }
    
    /// Check if user has advanced analytics
    func hasAdvancedAnalyticsAccess() -> Bool {
        return hasFeature(.advancedAnalytics)
    }
    
    /// Check if user has exclusive content access
    func hasExclusiveContentAccess() -> Bool {
        return hasFeature(.premiumContent)
    }
    
    /// Get maximum number of methods user can access
    func getMaxMethodsAccess() -> Int? {
        switch currentTier {
        case .none:
            return 3 // Limited access for free users
        case .premium:
            return nil // Unlimited access for premium users
        }
    }
    
    /// Check if user has export data access
    func hasExportDataAccess() -> Bool {
        return hasFeature(.advancedAnalytics)
    }
    
    /// Check if user has analytics detail access
    func hasAnalyticsDetailAccess() -> Bool {
        return hasFeature(.advancedAnalytics)
    }
    
    /// Check if user has community access
    func hasCommunityAccess() -> Bool {
        return hasFeature(.premiumContent)
    }
    
    // MARK: - Subscription Tier Management
    
    /// Check if user can upgrade to a target tier
    func canUpgradeTo(_ targetTier: SubscriptionTier) -> Bool {
        return currentTier.canUpgradeTo(targetTier)
    }
    
    /// Check if user can downgrade to a target tier
    func canDowngradeTo(_ targetTier: SubscriptionTier) -> Bool {
        return currentTier.canDowngradeTo(targetTier)
    }
    
    /// Get available upgrade options
    func getUpgradeOptions() -> [SubscriptionTier] {
        return SubscriptionTier.allCases.filter { canUpgradeTo($0) }
    }
    
    /// Get available downgrade options
    func getDowngradeOptions() -> [SubscriptionTier] {
        return SubscriptionTier.allCases.filter { canDowngradeTo($0) }
    }
    
    // MARK: - Trial Management
    
    /// Check if user is currently in trial period
    func isInTrialPeriod() -> Bool {
        guard let user = currentUser,
              let startDate = user.subscriptionStartDate,
              let expirationDate = expirationDate else {
            return false
        }
        
        // Check if subscription started within trial period (5 days)
        let trialEndDate = startDate.addingTimeInterval(5 * 24 * 60 * 60)
        let now = Date()
        
        return now <= trialEndDate && now <= expirationDate && isSubscriptionActive
    }
    
    /// Check if user has used their free trial
    func hasUsedFreeTrial() -> Bool {
        return currentUser?.hasUsedFreeTrial ?? false
    }
    
    /// Get remaining trial days
    func getRemainingTrialDays() -> Int {
        guard isInTrialPeriod(),
              let startDate = currentUser?.subscriptionStartDate else {
            return 0
        }
        
        let trialEndDate = startDate.addingTimeInterval(5 * 24 * 60 * 60)
        let remainingTime = trialEndDate.timeIntervalSinceNow
        return max(0, Int(ceil(remainingTime / (24 * 60 * 60))))
    }
    
    // MARK: - Private Helpers
    
    /// Load cached subscription data from UserDefaults
    private func loadCachedSubscriptionData() {
        if let data = UserDefaults.standard.data(forKey: "subscription_cache"),
           let cached = try? JSONDecoder().decode(SubscriptionCache.self, from: data) {
            subscriptionCache = cached
            
            if !cached.isExpired {
                updateFromCache(cached)
            }
        }
    }
    
    /// Get cached subscription data
    private func getCachedSubscription() -> SubscriptionCache? {
        return subscriptionCache
    }
    
    /// Cache subscription data
    private func cacheSubscriptionData(_ subscription: ValidatedSubscription) {
        let cache = SubscriptionCache(
            tier: subscription.tier,
            isActive: subscription.isActive,
            expirationDate: subscription.expirationDate,
            cachedAt: Date()
        )
        
        subscriptionCache = cache
        
        if let data = try? JSONEncoder().encode(cache) {
            UserDefaults.standard.set(data, forKey: "subscription_cache")
        }
    }
    
    /// Update subscription status from cache
    private func updateFromCache(_ cache: SubscriptionCache) {
        currentTier = cache.tier
        isSubscriptionActive = cache.isActive
        expirationDate = cache.expirationDate
    }
    
    /// Validate subscription with server (requires Firebase Functions from Story 23.0)
    private func validateSubscriptionWithServer() async throws -> ValidatedSubscription {
        // Check StoreKit for active subscriptions first
        if let activeSubscription = await checkActiveStoreKitSubscription() {
            // Update user data with the active subscription
            await updateUserSubscriptionData(activeSubscription)
            return activeSubscription
        }
        
        // Fall back to user data if no active StoreKit subscription
        guard let user = currentUser else {
            throw SubscriptionEntitlementError.userNotFound
        }
        
        let tier = user.currentSubscriptionTier ?? SubscriptionTier.none
        let expirationDate = user.subscriptionExpirationDate
        let isActive = expirationDate?.timeIntervalSinceNow ?? 0 > 0
        
        return ValidatedSubscription(
            tier: isActive ? tier : SubscriptionTier.none,
            isActive: isActive,
            expirationDate: expirationDate
        )
    }
    
    /// Check for active StoreKit subscriptions
    private func checkActiveStoreKitSubscription() async -> ValidatedSubscription? {
        // Import StoreKit
        guard #available(iOS 15.0, *) else { return nil }
        
        // Check for current entitlements
        for await verification in Transaction.currentEntitlements {
            if case .verified(let transaction) = verification {
                // Check if this is a subscription
                if transaction.productType == .autoRenewable {
                    // Determine the tier based on product ID
                    let tier = determineTierFromProductId(transaction.productID)
                    
                    // Get expiration date
                    let expirationDate = transaction.expirationDate
                    let isActive = expirationDate?.timeIntervalSinceNow ?? 0 > 0
                    
                    if isActive {
                        return ValidatedSubscription(
                            tier: tier,
                            isActive: true,
                            expirationDate: expirationDate
                        )
                    }
                }
            }
        }
        
        return nil
    }
    
    /// Determine subscription tier from product ID
    private func determineTierFromProductId(_ productId: String) -> SubscriptionTier {
        // Map product IDs to subscription tiers
        if productId.contains("premium") || productId.contains("pro") {
            return .premium
        }
        return .none
    }
    
    /// Update user subscription data in Firestore
    private func updateUserSubscriptionData(_ subscription: ValidatedSubscription) async {
        guard let userId = currentUser?.id else { return }
        
        do {
            try await firestore.collection("users").document(userId).updateData([
                "currentSubscriptionTier": subscription.tier.rawValue,
                "subscriptionExpirationDate": subscription.expirationDate as Any,
                "lastSubscriptionValidated": FieldValue.serverTimestamp()
            ])
            
            // Update local user object
            currentUser?.currentSubscriptionTier = subscription.tier
            currentUser?.subscriptionExpirationDate = subscription.expirationDate
        } catch {
            Logger.error("Failed to update user subscription data: \(error)")
        }
    }
    
    /// Update user's subscription tier in Firestore
    private func updateUserSubscriptionTier(_ tier: SubscriptionTier) async {
        guard let userId = currentUser?.id else { return }
        
        do {
            try await firestore.collection("users").document(userId).updateData([
                "currentSubscriptionTier": tier.rawValue,
                "lastSubscriptionValidated": FieldValue.serverTimestamp()
            ])
        } catch {
            Logger.info("Failed to update user subscription tier: \(error)")
        }
    }
}

// MARK: - Supporting Models

/// Cached subscription data
private struct SubscriptionCache: Codable {
    let tier: SubscriptionTier
    let isActive: Bool
    let expirationDate: Date?
    let cachedAt: Date
    
    var isExpired: Bool {
        Date().timeIntervalSince(cachedAt) > 15 * 60 // 15 minutes
    }
}

/// Validated subscription result
private struct ValidatedSubscription {
    let tier: SubscriptionTier
    let isActive: Bool
    let expirationDate: Date?
}

/// Subscription-related errors
private enum SubscriptionEntitlementError: LocalizedError {
    case userNotFound
    case validationFailed
    case networkError
    case invalidReceipt
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found"
        case .validationFailed:
            return "Subscription validation failed"
        case .networkError:
            return "Network error occurred"
        case .invalidReceipt:
            return "Invalid receipt"
        }
    }
}

// MARK: - Singleton Access

extension SubscriptionEntitlementService {
    /// Shared instance for app-wide access
    static let shared = SubscriptionEntitlementService()
}