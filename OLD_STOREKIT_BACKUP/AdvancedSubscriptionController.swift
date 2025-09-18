/**
 * AdvancedSubscriptionController.swift
 * Growth App Advanced Subscription Management
 *
 * Comprehensive subscription management controller providing pause/resume,
 * tier changes, billing modifications, and payment recovery capabilities.
 */

import Foundation
import Combine
import StoreKit

/// Advanced subscription management controller
@MainActor
public class AdvancedSubscriptionController: ObservableObject {
    
    // MARK: - Singleton
    
    public static let shared = AdvancedSubscriptionController()
    
    // MARK: - Published Properties
    
    @Published public private(set) var isOperationInProgress: Bool = false
    @Published public private(set) var currentOperation: SubscriptionOperation?
    @Published public private(set) var pauseHistory: [PauseRecord] = []
    @Published public private(set) var billingPreferences: BillingPreferences = BillingPreferences()
    @Published public private(set) var paymentRetryHistory: [PaymentRetryRecord] = []
    
    // MARK: - Private Properties
    
    private let subscriptionManager = SubscriptionStateManager.shared
    private let purchaseManager = PurchaseManager.shared
    private let analyticsService = PaywallAnalyticsService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Configuration
    private let pauseConfiguration = PauseConfiguration.default
    private let maxRetryAttempts = 3
    private let retrySchedule: [TimeInterval] = [24 * 60 * 60, 72 * 60 * 60, 168 * 60 * 60] // 1 day, 3 days, 1 week
    
    // Operation queue for serializing subscription changes
    private var operationQueue: [SubscriptionOperation] = []
    
    private init() {
        loadPauseHistory()
        loadBillingPreferences()
        loadPaymentRetryHistory()
        setupSubscriptionMonitoring()
    }
    
    // MARK: - Subscription Flexibility
    
    /// Pause subscription for specified duration
    public func pauseSubscription(duration: PauseDuration, reason: String? = nil) async -> Result<PauseConfirmation, SubscriptionError> {
        guard !isOperationInProgress else {
            return .failure(.operationInProgress)
        }
        
        // Validate pause eligibility
        let eligibilityResult = validatePauseEligibility(duration: duration)
        if case .failure(let error) = eligibilityResult {
            return .failure(error)
        }
        
        isOperationInProgress = true
        currentOperation = .pause(duration: duration)
        
        defer {
            isOperationInProgress = false
            currentOperation = nil
        }
        
        // Calculate pause dates
        let startDate = Date().addingTimeInterval(pauseConfiguration.gracePeriodBeforePause)
        let endDate = startDate.addingTimeInterval(duration.duration)
        
        // Create pause record
        let pauseRecord = PauseRecord(
            id: UUID().uuidString,
            startDate: startDate,
            endDate: endDate,
            duration: duration,
            reason: reason,
            status: .scheduled
        )
        
        // Schedule pause with StoreKit
        let storeKitResult = await schedulePauseWithStoreKit(pauseRecord)
        if case .failure(let error) = storeKitResult {
            return .failure(.storeKitError(error.localizedDescription))
        }
        
        // Calculate notification dates
        let notificationDates = calculateResumeNotificationDates(endDate: endDate)
        
        // Create confirmation
        let confirmation = PauseConfirmation(
            startDate: startDate,
            endDate: endDate,
            duration: duration,
            reason: reason,
            resumeNotificationDates: notificationDates,
            pauseCount: getPauseCountThisYear() + 1
        )
        
        // Update local state
        pauseHistory.append(pauseRecord)
        savePauseHistory()
        
        // Schedule notifications
        await scheduleResumeNotifications(dates: notificationDates, pauseId: confirmation.pauseId)
        
        // Track analytics
        analyticsService.trackConversionEvent(
            .subscriptionCancelled,
            context: PaywallContext.settings,
            metadata: [
                "pause_duration": duration.rawValue,
                "pause_reason": reason ?? "not_specified",
                "pause_count_this_year": confirmation.pauseCount
            ]
        )
            
        Logger.info("AdvancedSubscription: Subscription paused successfully for \(duration.displayName)")
        
        return .success(confirmation)
    }
    
    /// Resume paused subscription
    public func resumeSubscription() async -> Result<ResumeConfirmation, SubscriptionError> {
        guard !isOperationInProgress else {
            return .failure(.operationInProgress)
        }
        
        guard let activePause = getActivePause() else {
            return .failure(.resumeNotAllowed)
        }
        
        isOperationInProgress = true
        currentOperation = .resume
        
        defer {
            isOperationInProgress = false
            currentOperation = nil
        }
        
        let resumeDate = Date()
        let pauseDuration = resumeDate.timeIntervalSince(activePause.startDate)
        
        // Resume with StoreKit
        let storeKitResult = await resumeWithStoreKit(pauseRecord: activePause)
        if case .failure(let error) = storeKitResult {
            return .failure(.storeKitError(error.localizedDescription))
        }
        
        // Calculate next billing date
        let nextBillingDate = calculateNextBillingDate()
        
        // Update pause record
        if let index = pauseHistory.firstIndex(where: { $0.id == activePause.id }) {
            pauseHistory[index].status = .completed
            pauseHistory[index].actualEndDate = resumeDate
        }
        savePauseHistory()
        
        // Create confirmation
        let confirmation = ResumeConfirmation(
            resumeDate: resumeDate,
            nextBillingDate: nextBillingDate,
            wasAutomatic: false,
            pauseDuration: pauseDuration
        )
        
        // Cancel scheduled notifications
        await cancelResumeNotifications(pauseId: activePause.id)
        
        // Track analytics
        analyticsService.trackConversionEvent(
            .subscriptionRestored,
            context: PaywallContext.settings,
            metadata: [
                "pause_duration_actual": pauseDuration,
                "was_automatic": false
            ]
        )
            
        Logger.info("AdvancedSubscription: Subscription resumed successfully")
        
        return .success(confirmation)
    }
    
    /// Change subscription tier (upgrade/downgrade)
    public func changeSubscriptionTier(from currentTier: SubscriptionTier, to newTier: SubscriptionTier) async -> Result<ChangeConfirmation, SubscriptionError> {
        guard !isOperationInProgress else {
            return .failure(.operationInProgress)
        }
        
        guard currentTier != newTier else {
            return .failure(.invalidTierChange)
        }
        
        isOperationInProgress = true
        let changeType: SubscriptionChangeType = newTier.priority > currentTier.priority ? 
            .upgrade(from: currentTier, to: newTier) : 
            .downgrade(from: currentTier, to: newTier)
        currentOperation = .changeTier(from: currentTier, to: newTier)
        
        defer {
            isOperationInProgress = false
            currentOperation = nil
        }
        
        // Calculate proration if needed
        var prorationDetails: ProrationCalculation?
        if changeType.requiresProration {
            prorationDetails = calculateProration(from: currentTier, to: newTier)
        }
        
        // Execute tier change with StoreKit
        let storeKitResult = await changeTierWithStoreKit(from: currentTier, to: newTier)
        if case .failure(let error) = storeKitResult {
            return .failure(.storeKitError(error.localizedDescription))
        }
        
        // Calculate effective date and billing
        let effectiveDate = changeType.effectiveDate == .immediate ? Date() : getNextBillingDate()
        let newBillingAmount = getAmountForTier(newTier)
        let nextBillingDate = changeType.effectiveDate == .immediate ? 
            calculateNextBillingDate() : getNextBillingDate()
        
        // Create confirmation
        let confirmation = ChangeConfirmation(
            changeType: changeType,
            effectiveDate: effectiveDate,
            prorationDetails: prorationDetails,
            newBillingAmount: newBillingAmount,
            nextBillingDate: nextBillingDate
        )
        
        // Track analytics
        let eventType: ConversionEvent = newTier.priority > currentTier.priority ? 
            .subscriptionUpgraded : .subscriptionDowngraded
        
        analyticsService.trackConversionEvent(
            eventType,
            context: PaywallContext.settings,
            revenueAmount: changeType.requiresProration ? prorationDetails?.netAmount : nil,
            subscriptionTier: newTier,
            metadata: [
                "from_tier": currentTier.rawValue,
                "to_tier": newTier.rawValue,
                "proration_amount": prorationDetails?.netAmount ?? 0,
                "effective_immediately": changeType.effectiveDate == .immediate
            ]
        )
        
        Logger.info("AdvancedSubscription: Tier changed from \(currentTier.rawValue) to \(newTier.rawValue)")
        
        return .success(confirmation)
    }
    
    /// Change billing cycle
    public func changeBillingCycle(from currentCycle: BillingCycle, to newCycle: BillingCycle) async -> Result<CycleChangeConfirmation, SubscriptionError> {
        guard !isOperationInProgress else {
            return .failure(.operationInProgress)
        }
        
        guard currentCycle != newCycle else {
            return .failure(.invalidTierChange)
        }
        
        isOperationInProgress = true
        currentOperation = .changeBillingCycle(from: currentCycle, to: newCycle)
        
        defer {
            isOperationInProgress = false
            currentOperation = nil
        }
        
        // Calculate proration for cycle change
        let prorationDetails = calculateCycleChangeProration(from: currentCycle, to: newCycle)
        
        // Execute cycle change with StoreKit
        let storeKitResult = await changeBillingCycleWithStoreKit(from: currentCycle, to: newCycle)
        if case .failure(let error) = storeKitResult {
            return .failure(.storeKitError(error.localizedDescription))
        }
        
        let effectiveDate = Date()
        let newAmount = getAmountForCycle(newCycle)
        let nextBillingDate = effectiveDate.addingTimeInterval(newCycle.duration)
        
        // Create confirmation
        let confirmation = CycleChangeConfirmation(
            fromCycle: currentCycle,
            toCycle: newCycle,
            effectiveDate: effectiveDate,
            prorationDetails: prorationDetails,
            newAmount: newAmount,
            nextBillingDate: nextBillingDate
        )
        
        // Track analytics
        analyticsService.trackConversionEvent(
            .subscriptionUpgraded,
            context: PaywallContext.settings,
            revenueAmount: prorationDetails.netAmount,
            metadata: [
                "from_cycle": currentCycle.rawValue,
                "to_cycle": newCycle.rawValue,
                "proration_amount": prorationDetails.netAmount
            ]
        )
        
        Logger.info("AdvancedSubscription: Billing cycle changed from \(currentCycle.rawValue) to \(newCycle.rawValue)")
        
        return .success(confirmation)
    }
    
    // MARK: - Payment Management
    
    /// Retry failed payment
    public func retryFailedPayment() async -> Result<PaymentRetryResult, PaymentError> {
        guard !isOperationInProgress else {
            return .failure(.unknownError("Operation in progress"))
        }
        
        let currentRetries = getPaymentRetryCount()
        guard currentRetries < maxRetryAttempts else {
            return .failure(.retryLimitExceeded)
        }
        
        isOperationInProgress = true
        
        defer {
            isOperationInProgress = false
        }
        
        // Attempt payment retry with StoreKit
        let retryResult = await retryPaymentWithStoreKit()
        
        let nextRetryDate = retryResult.success ? nil : 
            Date().addingTimeInterval(retrySchedule[min(currentRetries, retrySchedule.count - 1)])
        
        let result = PaymentRetryResult(
            success: retryResult.success,
            retryAttempt: currentRetries + 1,
            nextRetryDate: nextRetryDate,
            failureReason: retryResult.failureReason,
            recommendedAction: retryResult.failureReason?.recoveryStrategy.toRecoveryAction()
        )
        
        // Record retry attempt
        let retryRecord = PaymentRetryRecord(
            id: UUID().uuidString,
            retryDate: Date(),
            success: result.success,
            failureReason: result.failureReason,
            retryAttempt: result.retryAttempt
        )
        
        paymentRetryHistory.append(retryRecord)
        savePaymentRetryHistory()
        
        // Track analytics
        analyticsService.trackConversionEvent(
            result.success ? .subscriptionRestored : .subscriptionCancelled,
            context: PaywallContext.settings,
            metadata: [
                "retry_attempt": result.retryAttempt,
                "failure_reason": result.failureReason?.rawValue ?? "none"
            ]
        )
        
        Logger.info("AdvancedSubscription: Payment retry \(result.success ? "succeeded" : "failed") on attempt \(result.retryAttempt)")
        
        return .success(result)
    }
    
    /// Update payment method
    public func updatePaymentMethod(_ method: PaymentMethod) async -> Result<UpdateConfirmation, PaymentError> {
        guard !isOperationInProgress else {
            return .failure(.unknownError("Operation in progress"))
        }
        
        isOperationInProgress = true
        currentOperation = .updatePaymentMethod(method: method)
        
        defer {
            isOperationInProgress = false
            currentOperation = nil
        }
        
        // Update payment method with StoreKit
        let updateResult = await updatePaymentMethodWithStoreKit(method)
        if case .failure(let error) = updateResult {
            return .failure(.unknownError(error.localizedDescription))
        }
        
        let nextBillingDate = calculateNextBillingDate()
        
        let confirmation = UpdateConfirmation(
            newPaymentMethod: method,
            nextBillingDate: nextBillingDate,
            retryScheduledPayments: true
        )
        
        // Track analytics
        analyticsService.trackConversionEvent(
            .subscriptionRestored,
            context: PaywallContext.settings,
            metadata: [
                "payment_method_type": method.displayName
            ]
        )
        
        Logger.info("AdvancedSubscription: Payment method updated successfully")
        
        return .success(confirmation)
    }
    
    /// Request billing date change
    public func requestBillingDateChange(_ preferredDate: Int) async -> Result<DateChangeConfirmation, BillingError> {
        guard preferredDate >= 1 && preferredDate <= 28 else {
            return .failure(.invalidBillingDate)
        }
        
        guard !isOperationInProgress else {
            return .failure(.unknownError("Operation in progress"))
        }
        
        isOperationInProgress = true
        currentOperation = .changeBillingDate(preferredDate: preferredDate)
        
        defer {
            isOperationInProgress = false
            currentOperation = nil
        }
        
        // Calculate proration for billing date change
        let prorationAdjustment = calculateBillingDateProration(newDate: preferredDate)
        
        // Request billing date change with StoreKit
        let changeResult = await changeBillingDateWithStoreKit(preferredDate)
        if case .failure(let error) = changeResult {
            return .failure(.unknownError(error.localizedDescription))
        }
        
        let effectiveDate = Date()
        let nextBillingDate = calculateNextBillingDateWithDay(preferredDate)
        
        // Update billing preferences
        billingPreferences = BillingPreferences(
            preferredBillingDate: preferredDate,
            notificationPreferences: billingPreferences.notificationPreferences,
            currencyPreference: billingPreferences.currencyPreference,
            invoiceDeliveryMethod: billingPreferences.invoiceDeliveryMethod,
            gracePeriodDays: billingPreferences.gracePeriodDays
        )
        saveBillingPreferences()
        
        let confirmation = DateChangeConfirmation(
            newBillingDate: preferredDate,
            effectiveDate: effectiveDate,
            prorationAdjustment: prorationAdjustment,
            nextBillingDate: nextBillingDate
        )
        
        // Track analytics
        analyticsService.trackConversionEvent(
            .subscriptionUpgraded,
            context: PaywallContext.settings,
            metadata: [
                "new_billing_date": preferredDate,
                "proration_adjustment": prorationAdjustment ?? 0
            ]
        )
        
        Logger.info("AdvancedSubscription: Billing date changed to \(preferredDate)")
        
        return .success(confirmation)
    }
    
    // MARK: - Helper Methods
    
    private func setupSubscriptionMonitoring() {
        // Monitor subscription state changes
        subscriptionManager.$subscriptionState
            .sink { [weak self] _ in
                self?.handleSubscriptionStateChange()
            }
            .store(in: &cancellables)
    }
    
    private func handleSubscriptionStateChange() {
        // Handle automatic subscription state changes
        Task {
            await checkForAutomaticResume()
            await updatePaymentRetrySchedule()
        }
    }
    
    private func validatePauseEligibility(duration: PauseDuration) -> Result<Void, SubscriptionError> {
        // Check if duration is allowed
        guard pauseConfiguration.allowedDurations.contains(duration) else {
            return .failure(.invalidPauseDuration)
        }
        
        // Check pause count limits
        let pauseCountThisYear = getPauseCountThisYear()
        let durationLimit = duration.maxAllowedPerYear
        let durationPausesThisYear = pauseHistory.filter { pause in
            pause.duration == duration && Calendar.current.isDate(pause.startDate, equalTo: Date(), toGranularity: .year)
        }.count
        
        guard pauseCountThisYear < pauseConfiguration.maxPausesPerYear else {
            return .failure(.pauseLimitExceeded)
        }
        
        guard durationPausesThisYear < durationLimit else {
            return .failure(.pauseLimitExceeded)
        }
        
        // Check if currently paused
        guard getActivePause() == nil else {
            return .failure(.pauseNotAllowed)
        }
        
        return .success(())
    }
    
    private func getPauseCountThisYear() -> Int {
        let currentYear = Calendar.current.component(.year, from: Date())
        return pauseHistory.filter { pause in
            Calendar.current.component(.year, from: pause.startDate) == currentYear
        }.count
    }
    
    private func getActivePause() -> PauseRecord? {
        return pauseHistory.first { pause in
            pause.status == .active || pause.status == .scheduled
        }
    }
    
    private func calculateResumeNotificationDates(endDate: Date) -> [Date] {
        return pauseConfiguration.resumeNotificationSchedule.map { interval in
            endDate.addingTimeInterval(interval)
        }
    }
    
    private func calculateProration(from currentTier: SubscriptionTier, to newTier: SubscriptionTier) -> ProrationCalculation {
        let currentDate = Date()
        let nextBillingDate = getNextBillingDate()
        let remainingTime = nextBillingDate.timeIntervalSince(currentDate)
        let totalPeriod = getBillingPeriodDuration()
        
        let currentPeriodValue = getAmountForTier(currentTier)
        let newPeriodValue = getAmountForTier(newTier)
        
        let remainingValueRatio = remainingTime / totalPeriod
        let creditAmount = currentPeriodValue * remainingValueRatio
        let chargeAmount = newPeriodValue * remainingValueRatio
        let netAmount = chargeAmount - creditAmount
        
        return ProrationCalculation(
            currentPeriodRemaining: remainingTime,
            currentPeriodValue: currentPeriodValue,
            newPeriodValue: newPeriodValue,
            creditAmount: creditAmount,
            chargeAmount: chargeAmount,
            netAmount: netAmount
        )
    }
    
    private func calculateCycleChangeProration(from currentCycle: BillingCycle, to newCycle: BillingCycle) -> ProrationCalculation {
        let currentDate = Date()
        let nextBillingDate = getNextBillingDate()
        let remainingTime = nextBillingDate.timeIntervalSince(currentDate)
        
        let currentAmount = getAmountForCycle(currentCycle)
        let newAmount = getAmountForCycle(newCycle)
        
        // Calculate daily rates
        let currentDailyRate = currentAmount / (currentCycle.duration / (24 * 60 * 60))
        let newDailyRate = newAmount / (newCycle.duration / (24 * 60 * 60))
        
        let remainingDays = remainingTime / (24 * 60 * 60)
        let creditAmount = currentDailyRate * remainingDays
        let chargeAmount = newDailyRate * remainingDays
        let netAmount = chargeAmount - creditAmount
        
        return ProrationCalculation(
            currentPeriodRemaining: remainingTime,
            currentPeriodValue: currentAmount,
            newPeriodValue: newAmount,
            creditAmount: creditAmount,
            chargeAmount: chargeAmount,
            netAmount: netAmount
        )
    }
    
    // MARK: - StoreKit Integration (Simplified implementations)
    
    private func schedulePauseWithStoreKit(_ pauseRecord: PauseRecord) async -> Result<Void, Error> {
        // This would integrate with StoreKit to pause the subscription
        // For now, return success (actual implementation would use StoreKit APIs)
        return .success(())
    }
    
    private func resumeWithStoreKit(pauseRecord: PauseRecord) async -> Result<Void, Error> {
        // This would integrate with StoreKit to resume the subscription
        return .success(())
    }
    
    private func changeTierWithStoreKit(from: SubscriptionTier, to: SubscriptionTier) async -> Result<Void, Error> {
        // This would integrate with StoreKit to change subscription tier
        return .success(())
    }
    
    private func changeBillingCycleWithStoreKit(from: BillingCycle, to: BillingCycle) async -> Result<Void, Error> {
        // This would integrate with StoreKit to change billing cycle
        return .success(())
    }
    
    private func retryPaymentWithStoreKit() async -> (success: Bool, failureReason: PaymentFailureReason?) {
        // This would integrate with StoreKit to retry payment
        return (success: true, failureReason: nil)
    }
    
    private func updatePaymentMethodWithStoreKit(_ method: PaymentMethod) async -> Result<Void, Error> {
        // This would integrate with StoreKit to update payment method
        return .success(())
    }
    
    private func changeBillingDateWithStoreKit(_ date: Int) async -> Result<Void, Error> {
        // This would integrate with StoreKit to change billing date
        return .success(())
    }
    
    // MARK: - Utility Methods
    
    private func getNextBillingDate() -> Date {
        // Get next billing date from subscription manager
        return Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 days from now
    }
    
    private func calculateNextBillingDate() -> Date {
        return Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 days from now
    }
    
    private func calculateNextBillingDateWithDay(_ day: Int) -> Date {
        let calendar = Calendar.current
        let currentDate = Date()
        var components = calendar.dateComponents([.year, .month], from: currentDate)
        components.day = day
        
        guard let targetDate = calendar.date(from: components) else {
            return calculateNextBillingDate()
        }
        
        // If the target date is in the past, move to next month
        if targetDate < currentDate {
            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: targetDate) else {
                return calculateNextBillingDate()
            }
            return nextMonth
        }
        
        return targetDate
    }
    
    private func getBillingPeriodDuration() -> TimeInterval {
        return 30 * 24 * 60 * 60 // 30 days
    }
    
    private func getAmountForTier(_ tier: SubscriptionTier) -> Double {
        switch tier {
        case .none: return 0.0
        case .premium: return 9.99
        }
    }
    
    private func getAmountForCycle(_ cycle: BillingCycle) -> Double {
        switch cycle {
        case .weekly: return 2.99
        case .monthly: return 9.99
        case .quarterly: return 24.99
        case .yearly: return 89.99
        }
    }
    
    private func calculateBillingDateProration(newDate: Int) -> Double? {
        // Calculate proration for billing date change
        return nil // No proration for billing date changes
    }
    
    private func getPaymentRetryCount() -> Int {
        let last24Hours = Date().addingTimeInterval(-24 * 60 * 60)
        return paymentRetryHistory.filter { $0.retryDate >= last24Hours }.count
    }
    
    private func checkForAutomaticResume() async {
        // Check if any paused subscriptions should automatically resume
        if let activePause = getActivePause(), Date() >= activePause.endDate {
            let _ = await resumeSubscription()
        }
    }
    
    private func updatePaymentRetrySchedule() async {
        // Update payment retry schedule based on current state
    }
    
    // MARK: - Notification Management
    
    private func scheduleResumeNotifications(dates: [Date], pauseId: String) async {
        // Schedule local notifications for resume reminders
        for date in dates {
            await LocalNotificationService.shared.scheduleNotification(
                id: "resume_reminder_\(pauseId)_\(date.timeIntervalSince1970)",
                title: "Subscription Resuming Soon",
                body: "Your Growth subscription will resume in 24 hours.",
                date: date
            )
        }
    }
    
    private func cancelResumeNotifications(pauseId: String) async {
        // Cancel scheduled resume notifications
        await LocalNotificationService.shared.cancelNotifications(withPrefix: "resume_reminder_\(pauseId)")
    }
    
    // MARK: - Persistence
    
    private func loadPauseHistory() {
        // Load pause history from UserDefaults or Core Data
        if let data = UserDefaults.standard.data(forKey: "pauseHistory"),
           let history = try? JSONDecoder().decode([PauseRecord].self, from: data) {
            pauseHistory = history
        }
    }
    
    private func savePauseHistory() {
        if let data = try? JSONEncoder().encode(pauseHistory) {
            UserDefaults.standard.set(data, forKey: "pauseHistory")
        }
    }
    
    private func loadBillingPreferences() {
        if let data = UserDefaults.standard.data(forKey: "billingPreferences"),
           let preferences = try? JSONDecoder().decode(BillingPreferences.self, from: data) {
            billingPreferences = preferences
        }
    }
    
    private func saveBillingPreferences() {
        if let data = try? JSONEncoder().encode(billingPreferences) {
            UserDefaults.standard.set(data, forKey: "billingPreferences")
        }
    }
    
    private func loadPaymentRetryHistory() {
        if let data = UserDefaults.standard.data(forKey: "paymentRetryHistory"),
           let history = try? JSONDecoder().decode([PaymentRetryRecord].self, from: data) {
            paymentRetryHistory = history
        }
    }
    
    private func savePaymentRetryHistory() {
        if let data = try? JSONEncoder().encode(paymentRetryHistory) {
            UserDefaults.standard.set(data, forKey: "paymentRetryHistory")
        }
    }
}

// MARK: - Supporting Models

/// Pause record for tracking
public struct PauseRecord: Codable {
    public let id: String
    public let startDate: Date
    public let endDate: Date
    public var actualEndDate: Date?
    public let duration: PauseDuration
    public let reason: String?
    public var status: PauseStatus
    
    public init(
        id: String,
        startDate: Date,
        endDate: Date,
        duration: PauseDuration,
        reason: String?,
        status: PauseStatus
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.duration = duration
        self.reason = reason
        self.status = status
    }
}

/// Pause status
public enum PauseStatus: String, Codable {
    case scheduled = "scheduled"
    case active = "active"
    case completed = "completed"
    case cancelled = "cancelled"
}

/// Payment retry record for tracking
public struct PaymentRetryRecord: Codable {
    public let id: String
    public let retryDate: Date
    public let success: Bool
    public let failureReason: PaymentFailureReason?
    public let retryAttempt: Int
    
    public init(
        id: String,
        retryDate: Date,
        success: Bool,
        failureReason: PaymentFailureReason?,
        retryAttempt: Int
    ) {
        self.id = id
        self.retryDate = retryDate
        self.success = success
        self.failureReason = failureReason
        self.retryAttempt = retryAttempt
    }
}

// MARK: - Additional Conversion Events
// Note: Additional ConversionEvent cases would be defined in the main ConversionEvent enum

// MARK: - Extensions

extension PaymentRecoveryStrategy {
    func toRecoveryAction() -> PaymentRecoveryAction {
        switch self {
        case .gracePeriodWithNotifications: return .addFunds
        case .immediateUpdateRequest: return .updatePaymentMethod
        case .alternatePaymentMethod: return .useAlternateMethod
        case .automaticRetry: return .tryAgainLater
        case .contactSupport: return .contactSupport
        case .manualReview: return .contactSupport
        }
    }
}

// Forward declaration for LocalNotificationService (would be implemented separately)
class LocalNotificationService {
    static let shared = LocalNotificationService()
    
    func scheduleNotification(id: String, title: String, body: String, date: Date) async {
        // Implementation for scheduling local notifications
    }
    
    func cancelNotifications(withPrefix prefix: String) async {
        // Implementation for canceling notifications
    }
}