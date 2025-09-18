//
//  SubscriptionSyncService.swift
//  Growth
//
//  Created by Growth on 1/19/25.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

/// Service for cross-device subscription state synchronization
@available(iOS 15.0, *)
@MainActor
public final class SubscriptionSyncService: ObservableObject {
    
    // MARK: - Singleton
    
    public static let shared = SubscriptionSyncService()
    
    // MARK: - Properties
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var webhookListener: ListenerRegistration?
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private weak var stateManager: SubscriptionStateManager?
    
    @Published public private(set) var isSyncing: Bool = false
    @Published public private(set) var lastSyncError: Error?
    @Published public private(set) var lastSyncTimestamp: Date?
    
    // MARK: - Initialization
    
    private init() {
        setupAuthStateListener()
    }
    
    /// Sets the state manager reference (called after both singletons are created)
    func setStateManager(_ manager: SubscriptionStateManager) {
        self.stateManager = manager
    }
    
    // MARK: - Setup
    
    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if user != nil {
                    await self?.startSync()
                } else {
                    self?.stopSync()
                }
            }
        }
    }
    
    // MARK: - Sync Management
    
    /// Starts real-time synchronization of subscription state
    public func startSync() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            Logger.info("⚠️ No authenticated user for subscription sync")
            return
        }
        
        isSyncing = true
        
        // Set up subscription state listener
        setupSubscriptionListener(userId: userId)
        
        // Set up webhook updates listener
        setupWebhookListener(userId: userId)
        
        // Perform initial sync
        await syncSubscriptionState()
    }
    
    /// Stops synchronization
    public func stopSync() {
        listener?.remove()
        listener = nil
        webhookListener?.remove()
        webhookListener = nil
        isSyncing = false
    }
    
    // MARK: - Firestore Listeners
    
    private func setupSubscriptionListener(userId: String) {
        let docRef = db.collection("users").document(userId)
        
        listener = docRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                self.lastSyncError = error
                Logger.info("❌ Subscription sync error: \(error)")
                return
            }
            
            guard let data = snapshot?.data() else { return }
            
            Task { @MainActor in
                await self.handleSubscriptionUpdate(data: data)
            }
        }
    }
    
    private func setupWebhookListener(userId: String) {
        let webhookRef = db.collection("users")
            .document(userId)
            .collection("webhookUpdates")
            .order(by: "receivedAt", descending: true)
            .limit(to: 1)
        
        webhookListener = webhookRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                Logger.info("❌ Webhook listener error: \(error)")
                return
            }
            
            guard let document = snapshot?.documents.first else { return }
            
            let data = document.data()
            if let webhookUpdate = WebhookUpdate.from(firestoreData: data) {
                Task { @MainActor in
                    await self.stateManager?.handleWebhookUpdate(webhookUpdate)
                }
            }
        }
    }
    
    // MARK: - State Synchronization
    
    /// Syncs current subscription state to Firestore
    public func syncSubscriptionState() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        guard let stateManager = stateManager else { return }
        
        let state = stateManager.subscriptionState
        let validationResult = stateManager.lastValidationResult
        
        do {
            // Prepare subscription data
            var subscriptionData: [String: Any] = [
                "currentSubscriptionTier": state.tier.rawValue,
                "subscriptionStatus": state.status.rawValue,
                "hasActiveAccess": state.hasActiveAccess,
                "lastUpdated": FieldValue.serverTimestamp(),
                "validationSource": state.validationSource.rawValue,
                "deviceId": UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
            ]
            
            // Add optional fields
            if let expirationDate = state.expirationDate {
                subscriptionData["subscriptionExpirationDate"] = Timestamp(date: expirationDate)
            }
            
            if let purchaseDate = state.purchaseDate {
                subscriptionData["subscriptionPurchaseDate"] = Timestamp(date: purchaseDate)
            }
            
            if let productId = state.productId {
                subscriptionData["subscriptionProductId"] = productId
            }
            
            if let transactionId = state.transactionId {
                subscriptionData["subscriptionTransactionId"] = transactionId
            }
            
            subscriptionData["isTrialActive"] = state.isTrialActive
            subscriptionData["autoRenewalEnabled"] = state.autoRenewalEnabled
            
            // Add validation result if available
            if let result = validationResult {
                subscriptionData["lastValidationTimestamp"] = Timestamp(date: result.timestamp)
                subscriptionData["lastValidationSource"] = result.source.rawValue
                subscriptionData["lastValidationSuccess"] = result.isValid
            }
            
            // Update Firestore
            try await db.collection("users").document(userId).updateData(subscriptionData)
            
            lastSyncTimestamp = Date()
            Logger.info("✅ Subscription state synced to Firestore")
            
        } catch {
            lastSyncError = error
            Logger.info("❌ Failed to sync subscription state: \(error)")
        }
    }
    
    // MARK: - Conflict Resolution
    
    private func handleSubscriptionUpdate(data: [String: Any]) async {
        // Extract subscription data
        guard let tierString = data["currentSubscriptionTier"] as? String,
              let tier = SubscriptionTier(rawValue: tierString),
              let statusString = data["subscriptionStatus"] as? String,
              let status = SubscriptionState.Status(rawValue: statusString) else {
            return
        }
        
        // Check if this is from another device
        let deviceId = data["deviceId"] as? String
        let currentDeviceId = UIDevice.current.identifierForVendor?.uuidString
        
        if deviceId == currentDeviceId {
            // This is our own update, ignore
            return
        }
        
        // Parse timestamps
        var expirationDate: Date?
        if let timestamp = data["subscriptionExpirationDate"] as? Timestamp {
            expirationDate = timestamp.dateValue()
        }
        
        var purchaseDate: Date?
        if let timestamp = data["subscriptionPurchaseDate"] as? Timestamp {
            purchaseDate = timestamp.dateValue()
        }
        
        var lastUpdated = Date()
        if let timestamp = data["lastUpdated"] as? Timestamp {
            lastUpdated = timestamp.dateValue()
        }
        
        // Create state from Firestore data
        let remoteState = SubscriptionState(
            tier: tier,
            status: status,
            expirationDate: expirationDate,
            purchaseDate: purchaseDate,
            isTrialActive: data["isTrialActive"] as? Bool ?? false,
            trialExpirationDate: nil,
            autoRenewalEnabled: data["autoRenewalEnabled"] as? Bool ?? false,
            lastUpdated: lastUpdated,
            validationSource: .server,
            productId: data["subscriptionProductId"] as? String,
            transactionId: data["subscriptionTransactionId"] as? String
        )
        
        // Resolve conflicts
        guard let stateManager = stateManager else { return }
        let currentState = stateManager.subscriptionState
        if shouldUpdateToRemoteState(local: currentState, remote: remoteState) {
            // Update to remote state
            await stateManager.forceRefresh()
            Logger.info("📱 Updated subscription state from another device")
        }
    }
    
    /// Determines if remote state should override local state
    private func shouldUpdateToRemoteState(local: SubscriptionState, remote: SubscriptionState) -> Bool {
        // Server-validated state takes precedence
        if remote.validationSource == .server && local.validationSource == .local {
            return true
        }
        
        // More recent state takes precedence
        if remote.lastUpdated > local.lastUpdated {
            // But only if the difference is significant (> 1 minute)
            let timeDifference = remote.lastUpdated.timeIntervalSince(local.lastUpdated)
            return timeDifference > 60
        }
        
        // Higher tier takes precedence (in case of race conditions)
        if remote.tier.priority > local.tier.priority {
            return true
        }
        
        return false
    }
    
    // MARK: - Public Methods
    
    /// Forces a sync of subscription state
    public func forceSync() async {
        await syncSubscriptionState()
    }
    
    /// Clears all sync data
    public func clearSyncData() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let batch = db.batch()
            
            // Clear subscription data
            let userRef = db.collection("users").document(userId)
            batch.updateData([
                "currentSubscriptionTier": FieldValue.delete(),
                "subscriptionStatus": FieldValue.delete(),
                "subscriptionExpirationDate": FieldValue.delete(),
                "subscriptionProductId": FieldValue.delete(),
                "subscriptionTransactionId": FieldValue.delete()
            ], forDocument: userRef)
            
            try await batch.commit()
            Logger.info("✅ Cleared sync data")
            
        } catch {
            Logger.info("❌ Failed to clear sync data: \(error)")
        }
    }
}

// MARK: - Error Types

extension SubscriptionSyncService {
    enum SyncError: LocalizedError {
        case notAuthenticated
        case syncFailed(String)
        case conflictResolutionFailed
        
        var errorDescription: String? {
            switch self {
            case .notAuthenticated:
                return "User must be authenticated to sync subscriptions"
            case .syncFailed(let reason):
                return "Subscription sync failed: \(reason)"
            case .conflictResolutionFailed:
                return "Failed to resolve subscription state conflict"
            }
        }
    }
}