/**
 * PaywallViewModel.swift
 * Growth App Paywall State Management
 *
 * Reactive view model for managing paywall UI state, purchase flows,
 * and user interactions across the subscription upgrade experience.
 */

import Foundation
import SwiftUI
import StoreKit
import Combine
import os.log

// MARK: - Type Aliases for Compatibility
// PaywallAnalytics is PaywallAnalyticsService - no alias needed

// Logger is already defined in Core/Utilities/Logger.swift
// PaywallContext is now defined in PaywallContext.swift

// MARK: - Paywall UI State

/// Represents the current state of the paywall UI
public enum PaywallUIState: Equatable {
    case loading
    case ready
    case purchasing(SubscriptionDuration)
    case success
    case error(String)
}

// MARK: - Paywall View Model

/// Reactive view model for paywall UI state management
@MainActor
public class PaywallViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var uiState: PaywallUIState = .loading
    @Published public var selectedDuration: SubscriptionDuration = .quarterly
    @Published public var showSuccessAnimation = false
    @Published public var showErrorAlert = false
    @Published public var errorMessage = ""
    @Published public var isExitIntentDetected = false
    
    // MARK: - Dependencies
    private let purchaseManager: PurchaseManager
    private let coordinator: PaywallCoordinator
    private let analytics: PaywallAnalyticsService
    private let featureGate: FeatureGateService
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    public let context: PaywallContext
    
    // MARK: - Computed Properties
    
    /// Available subscription durations with pricing
    public var subscriptionOptions: [(SubscriptionDuration, String, String)] {
        return SubscriptionDuration.allCases.map { duration in
            let price = duration.price
            let savings = savingsText(for: duration)
            return (duration, price, savings)
        }
    }
    
    /// Primary feature being promoted
    public var primaryFeature: FeatureType? {
        return context.primaryFeature
    }
    
    /// Contextual messaging for this paywall
    public var contextualMessage: String {
        return context.contextualMessage
    }
    
    /// Features to highlight based on context
    public var featuresToHighlight: [FeatureType] {
        switch context {
        case .featureGate(let feature):
            // Show the requested feature plus 2-3 complementary ones
            return getComplementaryFeatures(for: feature)
        case .onboarding:
            // Show top value features for new users
            return [.customRoutines, .aiCoach, .progressTracking]
        case .sessionCompletion:
            // Show features that enhance the post-session experience
            return [.progressTracking, .advancedAnalytics, .goalSetting]
        case .settings, .general:
            // Show comprehensive feature set
            return [.aiCoach, .customRoutines, .progressTracking, .advancedAnalytics]
        }
    }
    
    /// Whether purchase is currently in progress
    public var isPurchasing: Bool {
        if case .purchasing(_) = uiState {
            return true
        }
        return false
    }
    
    // MARK: - Initialization
    
    init(
        context: PaywallContext,
        purchaseManager: PurchaseManager? = nil,
        coordinator: PaywallCoordinator? = nil,
        analytics: PaywallAnalyticsService? = nil,
        featureGate: FeatureGateService? = nil
    ) {
        self.context = context
        self.purchaseManager = purchaseManager ?? PurchaseManager.shared
        self.coordinator = coordinator ?? PaywallCoordinator.shared
        self.analytics = analytics ?? PaywallAnalyticsService.shared
        self.featureGate = featureGate ?? FeatureGateService.shared
        
        setupSubscriptions()
        loadProducts()
    }
    
    // MARK: - Setup
    
    private func setupSubscriptions() {
        // Listen to purchase manager state changes
        purchaseManager.$purchaseState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] purchaseState in
                self?.handlePurchaseStateChange(purchaseState)
            }
            .store(in: &cancellables)
        
        // Listen to purchase state changes
        purchaseManager.$purchaseState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                if case .readyToPurchase = state, self?.uiState == .loading {
                    self?.uiState = .ready
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadProducts() {
        let bundleID = Bundle.main.bundleIdentifier ?? "unknown"
        let environment = StoreKitEnvironmentHandler.shared.currentEnvironment
        
        Logger.info("PaywallViewModel: Starting product loading")
        Logger.info("PaywallViewModel: Bundle ID: \(bundleID)")
        Logger.info("PaywallViewModel: Environment: \(environment.displayName)")
        Logger.info("PaywallViewModel: Requested Product IDs: \(SubscriptionProductIDs.allProductIDs.joined(separator: ", "))")
        
        // Check build configuration
        #if DEBUG
        Logger.info("PaywallViewModel: Debug build - may use local StoreKit config")
        #else
        Logger.info("PaywallViewModel: Release build - MUST use App Store Connect")
        if environment == .xcode {
            Logger.error("PaywallViewModel: ERROR - Xcode environment in Release build!")
        }
        #endif
        
        // Trigger product loading from StoreKit
        Task {
            // Environment is automatically detected via computed property
            
            await StoreKitService.shared.loadProducts()
            
            // Check if products were loaded successfully
            let hasProducts = StoreKitService.shared.hasAvailableProducts
            let currentEnvironment = StoreKitEnvironmentHandler.shared.currentEnvironment
            
            await MainActor.run {
                if hasProducts {
                    Logger.info("PaywallViewModel: Products loaded successfully, setting UI to ready")
                    if uiState == .loading {
                        uiState = .ready
                    }
                } else {
                    Logger.error("PaywallViewModel: No products available after loading")
                    Logger.error("PaywallViewModel: Environment: \(currentEnvironment.displayName)")
                    Logger.error("PaywallViewModel: Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")
                    Logger.error("PaywallViewModel: Expected products: \(SubscriptionProductIDs.allProductIDs.joined(separator: ", "))")
                }
            }
            
            // Check if this is sandbox/app review scenario
            if !hasProducts && (currentEnvironment == .sandbox || currentEnvironment == .xcode) {
                Logger.info("PaywallViewModel: Detected sandbox/unknown environment, checking subscription status...")
                
                // Check if user already has an active subscription
                let hasActiveSubscription = StoreKitService.shared.hasActiveSubscription
                if hasActiveSubscription {
                    Logger.warning("PaywallViewModel: User has active subscription but products not loading - TestFlight issue")
                    
                    // Get subscription details
                    // Note: getActiveSubscriptionDetails() method not available in StoreKitService
                    Logger.info("PaywallViewModel: Active subscription detected")
                }
                
                // Environment is automatically detected via computed property
                await StoreKitService.shared.loadProducts()
                
                let hasProductsAfterRetry = StoreKitService.shared.hasAvailableProducts
                
                await MainActor.run {
                    if hasProductsAfterRetry {
                        Logger.info("PaywallViewModel: Retry successful")
                        if uiState == .loading {
                            uiState = .ready
                        }
                    } else {
                        // Still no products - show appropriate error based on subscription status
                        if hasActiveSubscription {
                            errorMessage = """
                            Your subscription is active but options are temporarily unavailable.
                            
                            This is a known TestFlight issue. Your subscription remains active.
                            Please try again later or contact support if the issue persists.
                            """
                        } else {
                            let isSandbox = currentEnvironment == .sandbox
                            errorMessage = isSandbox ? 
                                "Subscription options are being configured. Please try again in a moment." :
                                "Subscription options are temporarily unavailable. Please try again later."
                        }
                        
                        uiState = .error("Products not available")
                        showErrorAlert = true
                    }
                }
            }
        }
        
        // Add timeout mechanism with retry for TestFlight
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
            guard let self = self else { return }
            // If still loading after 10 seconds, retry once for TestFlight
            if self.uiState == .loading {
                Logger.error("PaywallViewModel: Product loading timed out, attempting retry")
                
                // Retry loading products one more time
                Task {
                    await StoreKitService.shared.loadProducts()
                    
                    // Wait a bit more
                    try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                    
                    // Check if products loaded after retry
                    if !StoreKitService.shared.hasAvailableProducts {
                        Logger.error("PaywallViewModel: Products still not loaded after retry")
                        
                        // Collect diagnostic information
                        let environment = StoreKitEnvironmentHandler.shared.currentEnvironment
                        let bundleID = Bundle.main.bundleIdentifier ?? "unknown"
                        let productIDs = SubscriptionProductIDs.allProductIDs.joined(separator: ", ")
                        
                        await MainActor.run {
                            if environment == .sandbox || environment == .xcode {
                                self.errorMessage = """
                                Subscription options are being configured.
                                
                                Environment: \(environment.displayName)
                                Bundle ID: \(bundleID)
                                
                                This may take a moment on TestFlight.
                                Please tap "Try Again" to retry loading.
                                """
                            } else {
                                self.errorMessage = """
                                Unable to load subscription options.
                                
                                Diagnostic Information:
                                • Environment: \(environment.displayName)
                                • Bundle ID: \(bundleID)
                                • Products requested: \(productIDs)
                                
                                Please tap "Try Again" to retry.
                                If the issue persists, please restart the app or contact support.
                                """
                            }
                            
                            // Log the full diagnostic info
                            Logger.error("PaywallViewModel: Product loading failed - Environment: \(environment.displayName), Bundle: \(bundleID), Products: \(productIDs)")
                            
                            self.uiState = .error("Loading timeout after retry")
                            self.showErrorAlert = true
                        }
                    } else {
                        // Products loaded after retry
                        Logger.info("PaywallViewModel: Products loaded successfully after retry")
                        await MainActor.run {
                            self.uiState = .ready
                        }
                    }
                }
            }
        }
    }
    
    
    // MARK: - Purchase Flow
    
    /// Initiate purchase for selected duration
    public func purchaseSelected() {
        guard case .ready = uiState else { return }
        
        Task {
            await purchase(duration: selectedDuration)
        }
    }
    
    /// Purchase specific duration
    @MainActor
    public func purchase(duration: SubscriptionDuration) async {
        Logger.info("PaywallViewModel: Starting purchase for duration: \(duration)")
        Logger.info("PaywallViewModel: Product ID: \(duration.productId)")
        
        uiState = .purchasing(duration)
        
        // Track purchase attempt
        analytics.trackFunnelStep(
            .purchaseInitiated,
            context: context,
            metadata: ["duration": duration.rawValue]
        )
        
        let result = await purchaseManager.purchase(productID: duration.productId)
        Logger.info("PaywallViewModel: Purchase result: \(result)")
        
        // Handle result
        await handlePurchaseResult(result, for: duration)
    }
    
    /// Handle purchase result
    @MainActor
    private func handlePurchaseResult(_ result: PurchaseResult, for duration: SubscriptionDuration) async {
        switch result {
        case .success(_):
            Logger.info("PaywallViewModel: Purchase succeeded for \(duration)")
            uiState = .success
            showSuccessAnimation = true
            
            // Track successful purchase
            analytics.trackConversionEvent(
                .subscriptionPurchased,
                context: context,
                subscriptionDuration: duration
            )
            
        case .cancelled:
            Logger.info("PaywallViewModel: Purchase cancelled by user for \(duration)")
            uiState = .ready
            
        case .pending:
            Logger.info("PaywallViewModel: Purchase pending for \(duration)")
            uiState = .ready
            errorMessage = "Purchase is pending approval"
            showErrorAlert = true
            
        case .failed(let error):
            Logger.error("PaywallViewModel: Purchase failed for \(duration): \(error)")
            uiState = .error(error.localizedDescription)
            errorMessage = error.localizedDescription
            showErrorAlert = true
            
            // Track failed purchase
            let metadata: [String: Any] = ["error": error.localizedDescription]
            analytics.trackFunnelStep(.purchaseFailed, context: context, metadata: metadata)
        }
    }
    
    /// Restore previous purchases
    public func restorePurchases() {
        Logger.info("PaywallViewModel: Starting restore purchases")
        Task {
            let result = await purchaseManager.restorePurchases()
            Logger.info("PaywallViewModel: Restore purchases result: \(result)")
        }
    }
    
    // MARK: - UI Interactions
    
    /// Handle duration selection
    public func selectDuration(_ duration: SubscriptionDuration) {
        selectedDuration = duration
        
        // Track duration selection
        analytics.trackFunnelStep(
            .pricingOptionSelected,
            context: context,
            metadata: ["selected_duration": duration.rawValue]
        )
    }
    
    /// Handle dismiss gesture/button
    public func handleDismissIntent() {
        // Detect exit intent for retention strategies
        if !isExitIntentDetected {
            isExitIntentDetected = true
            
            // Track exit intent
            analytics.trackFunnelStep(
                .exitIntentDetected,
                context: context,
                metadata: [:]
            )
            
            // Show retention strategy (could be discount, trial extension, etc.)
            // For now, just track and allow dismissal
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.coordinator.dismissPaywall()
            }
        } else {
            // User really wants to leave
            coordinator.dismissPaywall()
        }
    }
    
    /// Dismiss the paywall
    public func dismissPaywall() {
        coordinator.dismissPaywall()
    }
    
    /// Reset error state
    public func clearError() {
        showErrorAlert = false
        errorMessage = ""
        // Don't change uiState here - it should remain in its current state
    }
    
    /// Retry loading products
    public func retryProductLoad() {
        Logger.info("PaywallViewModel: Retrying product load")
        errorMessage = ""
        showErrorAlert = false
        uiState = .loading
        loadProducts()
    }
    
    // MARK: - Private Methods
    
    private func handlePurchaseStateChange(_ state: PurchaseState) {
        switch state {
        case .idle:
            if uiState != .loading {
                uiState = .ready
            }
            
        case .loadingProducts:
            uiState = .loading
            
        case .readyToPurchase:
            uiState = .ready
            
        case .purchasing:
            uiState = .purchasing(selectedDuration)
            
        case .processing:
            uiState = .purchasing(selectedDuration)
            
        case .completed(.success):
            uiState = .success
            showSuccessAnimation = true
            
            // Notify coordinator of successful purchase
            coordinator.handlePurchaseSuccess()
            
        case .completed(.cancelled):
            uiState = .ready
            
        case .completed(.pending):
            uiState = .ready
            
        case .completed(.failed(let error)):
            uiState = .error(error.localizedDescription)
            errorMessage = error.localizedDescription
            showErrorAlert = true
            
            // Notify coordinator of purchase failure
            coordinator.handlePurchaseFailure(error: error)
            
        case .failed(let error):
            uiState = .error(error.localizedDescription)
            errorMessage = error.localizedDescription
            showErrorAlert = true
            
            // Notify coordinator of purchase failure
            coordinator.handlePurchaseFailure(error: error)
        }
    }
    
    private func getComplementaryFeatures(for primaryFeature: FeatureType) -> [FeatureType] {
        switch primaryFeature {
        case .aiCoach:
            return [.aiCoach, .progressTracking, .advancedAnalytics]
        case .customRoutines:
            return [.customRoutines, .advancedTimer, .goalSetting]
        case .progressTracking:
            return [.progressTracking, .advancedAnalytics, .expertInsights]
        case .advancedAnalytics:
            return [.advancedAnalytics, .progressTracking, .goalSetting]
        case .liveActivities:
            return [.liveActivities, .advancedTimer, .customRoutines]
        default:
            return [.aiCoach, .customRoutines, .progressTracking]
        }
    }
    
    private func savingsText(for duration: SubscriptionDuration) -> String {
        switch duration {
        case .weekly:
            return "" // No savings for weekly
        case .quarterly:
            return "Save 20%" // Compared to monthly equivalent
        case .yearly:
            return "Save 45%" // Compared to monthly equivalent
        }
    }
}

// MARK: - Analytics Extensions

extension PaywallAnalyticsService {
    
    /// Track purchase attempt
    func trackPurchaseAttempt(context: PaywallContext, duration: SubscriptionDuration) {
        _ = [
            "context": "\(context)",
            "duration": duration.rawValue,
            "price_cents": duration.priceCents,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // print("PaywallAnalytics: Purchase Attempt - \(parameters)")
    }
    
    /// Track duration selection
    func trackDurationSelection(context: PaywallContext, duration: SubscriptionDuration) {
        _ = [
            "context": "\(context)",
            "duration": duration.rawValue,
            "price_cents": duration.priceCents,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // print("PaywallAnalytics: Duration Selection - \(parameters)")
    }
    
    /// Track exit intent
    func trackExitIntent(context: PaywallContext) {
        _ = [
            "context": "\(context)",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // print("PaywallAnalytics: Exit Intent - \(parameters)")
    }
}