/**
 * AdvancedSubscriptionModels.swift
 * Growth App Advanced Subscription Management
 *
 * Comprehensive models for advanced subscription features including
 * pause/resume, tier changes, billing modifications, and payment recovery.
 */

import Foundation
import StoreKit

// MARK: - Subscription Management Models

/// Advanced subscription management operations
public enum SubscriptionOperation {
    case pause(duration: PauseDuration)
    case resume
    case changeTier(from: SubscriptionTier, to: SubscriptionTier)
    case changeBillingCycle(from: BillingCycle, to: BillingCycle)
    case updatePaymentMethod(method: PaymentMethod)
    case changeBillingDate(preferredDate: Int)
    case cancelWithRetention(reason: CancellationReason)
}

/// Subscription pause duration options
public enum PauseDuration: String, CaseIterable, Codable {
    case oneMonth = "1_month"
    case twoMonths = "2_months"
    case threeMonths = "3_months"
    case sixMonths = "6_months"
    
    public var duration: TimeInterval {
        switch self {
        case .oneMonth: return 30 * 24 * 60 * 60
        case .twoMonths: return 60 * 24 * 60 * 60
        case .threeMonths: return 90 * 24 * 60 * 60
        case .sixMonths: return 180 * 24 * 60 * 60
        }
    }
    
    public var displayName: String {
        switch self {
        case .oneMonth: return "1 Month"
        case .twoMonths: return "2 Months"
        case .threeMonths: return "3 Months"
        case .sixMonths: return "6 Months"
        }
    }
    
    public var maxAllowedPerYear: Int {
        switch self {
        case .oneMonth: return 6
        case .twoMonths: return 3
        case .threeMonths: return 2
        case .sixMonths: return 1
        }
    }
}

/// Billing cycle options
public enum BillingCycle: String, CaseIterable, Codable {
    case weekly = "weekly"
    case monthly = "monthly"
    case quarterly = "quarterly"
    case yearly = "yearly"
    
    public var duration: TimeInterval {
        switch self {
        case .weekly: return 7 * 24 * 60 * 60
        case .monthly: return 30 * 24 * 60 * 60
        case .quarterly: return 90 * 24 * 60 * 60
        case .yearly: return 365 * 24 * 60 * 60
        }
    }
    
    public var displayName: String {
        switch self {
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .yearly: return "Yearly"
        }
    }
}

/// Subscription change types
public enum SubscriptionChangeType: Codable {
    case upgrade(from: SubscriptionTier, to: SubscriptionTier)
    case downgrade(from: SubscriptionTier, to: SubscriptionTier)
    case cycleChange(from: BillingCycle, to: BillingCycle)
    case pause(duration: PauseDuration)
    case resume
    
    public var requiresProration: Bool {
        switch self {
        case .upgrade: return true
        case .downgrade: return false // Apply at next cycle
        case .cycleChange: return true
        case .pause, .resume: return false
        }
    }
    
    public var effectiveDate: SubscriptionChangeEffectiveDate {
        switch self {
        case .upgrade, .cycleChange: return .immediate
        case .downgrade: return .nextBillingCycle
        case .pause, .resume: return .immediate
        }
    }
}

/// When subscription changes take effect
public enum SubscriptionChangeEffectiveDate: Equatable {
    case immediate
    case nextBillingCycle
    case specificDate(Date)
}

// MARK: - Pause/Resume Models

/// Subscription pause configuration
public struct PauseConfiguration: Codable {
    public let allowedDurations: [PauseDuration]
    public let maxPausesPerYear: Int
    public let gracePeriodBeforePause: TimeInterval
    public let resumeNotificationSchedule: [TimeInterval]
    public let requiresReason: Bool
    
    public init(
        allowedDurations: [PauseDuration] = PauseDuration.allCases,
        maxPausesPerYear: Int = 2,
        gracePeriodBeforePause: TimeInterval = 24 * 60 * 60, // 24 hours
        resumeNotificationSchedule: [TimeInterval] = [7 * 24 * 60 * 60, 24 * 60 * 60], // 7 days, 1 day
        requiresReason: Bool = true
    ) {
        self.allowedDurations = allowedDurations
        self.maxPausesPerYear = maxPausesPerYear
        self.gracePeriodBeforePause = gracePeriodBeforePause
        self.resumeNotificationSchedule = resumeNotificationSchedule
        self.requiresReason = requiresReason
    }
    
    public static let `default` = PauseConfiguration()
}

/// Pause confirmation details
public struct PauseConfirmation: Codable {
    public let pauseId: String
    public let startDate: Date
    public let endDate: Date
    public let duration: PauseDuration
    public let reason: String?
    public let resumeNotificationDates: [Date]
    public let pauseCount: Int // Total pauses this year
    
    public init(
        pauseId: String = UUID().uuidString,
        startDate: Date,
        endDate: Date,
        duration: PauseDuration,
        reason: String? = nil,
        resumeNotificationDates: [Date],
        pauseCount: Int
    ) {
        self.pauseId = pauseId
        self.startDate = startDate
        self.endDate = endDate
        self.duration = duration
        self.reason = reason
        self.resumeNotificationDates = resumeNotificationDates
        self.pauseCount = pauseCount
    }
}

/// Resume confirmation details
public struct ResumeConfirmation: Codable {
    public let resumeId: String
    public let resumeDate: Date
    public let nextBillingDate: Date
    public let wasAutomatic: Bool
    public let pauseDuration: TimeInterval
    
    public init(
        resumeId: String = UUID().uuidString,
        resumeDate: Date,
        nextBillingDate: Date,
        wasAutomatic: Bool,
        pauseDuration: TimeInterval
    ) {
        self.resumeId = resumeId
        self.resumeDate = resumeDate
        self.nextBillingDate = nextBillingDate
        self.wasAutomatic = wasAutomatic
        self.pauseDuration = pauseDuration
    }
}

// MARK: - Subscription Change Models

/// Subscription tier change confirmation
public struct ChangeConfirmation: Codable {
    public let changeId: String
    public let changeType: SubscriptionChangeType
    public let effectiveDate: Date
    public let prorationDetails: ProrationCalculation?
    public let newBillingAmount: Double
    public let nextBillingDate: Date
    
    public init(
        changeId: String = UUID().uuidString,
        changeType: SubscriptionChangeType,
        effectiveDate: Date,
        prorationDetails: ProrationCalculation? = nil,
        newBillingAmount: Double,
        nextBillingDate: Date
    ) {
        self.changeId = changeId
        self.changeType = changeType
        self.effectiveDate = effectiveDate
        self.prorationDetails = prorationDetails
        self.newBillingAmount = newBillingAmount
        self.nextBillingDate = nextBillingDate
    }
}

/// Billing cycle change confirmation
public struct CycleChangeConfirmation: Codable {
    public let changeId: String
    public let fromCycle: BillingCycle
    public let toCycle: BillingCycle
    public let effectiveDate: Date
    public let prorationDetails: ProrationCalculation
    public let newAmount: Double
    public let nextBillingDate: Date
    
    public init(
        changeId: String = UUID().uuidString,
        fromCycle: BillingCycle,
        toCycle: BillingCycle,
        effectiveDate: Date,
        prorationDetails: ProrationCalculation,
        newAmount: Double,
        nextBillingDate: Date
    ) {
        self.changeId = changeId
        self.fromCycle = fromCycle
        self.toCycle = toCycle
        self.effectiveDate = effectiveDate
        self.prorationDetails = prorationDetails
        self.newAmount = newAmount
        self.nextBillingDate = nextBillingDate
    }
}

/// Proration calculation details
public struct ProrationCalculation: Codable {
    public let currentPeriodRemaining: TimeInterval
    public let currentPeriodValue: Double
    public let newPeriodValue: Double
    public let creditAmount: Double
    public let chargeAmount: Double
    public let netAmount: Double
    public let calculationDate: Date
    
    public init(
        currentPeriodRemaining: TimeInterval,
        currentPeriodValue: Double,
        newPeriodValue: Double,
        creditAmount: Double,
        chargeAmount: Double,
        netAmount: Double,
        calculationDate: Date = Date()
    ) {
        self.currentPeriodRemaining = currentPeriodRemaining
        self.currentPeriodValue = currentPeriodValue
        self.newPeriodValue = newPeriodValue
        self.creditAmount = creditAmount
        self.chargeAmount = chargeAmount
        self.netAmount = netAmount
        self.calculationDate = calculationDate
    }
}

// MARK: - Payment Management Models

/// Payment method types
public enum PaymentMethod: Codable {
    case appleID
    case creditCard(last4: String, brand: String, expiryMonth: Int, expiryYear: Int)
    case paypal(email: String)
    case bankAccount(last4: String, bankName: String)
    
    public var displayName: String {
        switch self {
        case .appleID:
            return "Apple ID"
        case .creditCard(let last4, let brand, _, _):
            return "\(brand) •••• \(last4)"
        case .paypal(let email):
            return "PayPal (\(email))"
        case .bankAccount(let last4, let bankName):
            return "\(bankName) •••• \(last4)"
        }
    }
    
    public var requiresUpdate: Bool {
        switch self {
        case .appleID:
            return false
        case .creditCard(_, _, let month, let year):
            let currentDate = Date()
            let calendar = Calendar.current
            let currentYear = calendar.component(.year, from: currentDate)
            let currentMonth = calendar.component(.month, from: currentDate)
            return year < currentYear || (year == currentYear && month < currentMonth)
        case .paypal, .bankAccount:
            return false // PayPal and bank accounts don't expire
        }
    }
}

/// Payment retry result
public struct PaymentRetryResult: Codable {
    public let retryId: String
    public let success: Bool
    public let retryAttempt: Int
    public let nextRetryDate: Date?
    public let failureReason: PaymentFailureReason?
    public let recommendedAction: PaymentRecoveryAction?
    
    public init(
        retryId: String = UUID().uuidString,
        success: Bool,
        retryAttempt: Int,
        nextRetryDate: Date? = nil,
        failureReason: PaymentFailureReason? = nil,
        recommendedAction: PaymentRecoveryAction? = nil
    ) {
        self.retryId = retryId
        self.success = success
        self.retryAttempt = retryAttempt
        self.nextRetryDate = nextRetryDate
        self.failureReason = failureReason
        self.recommendedAction = recommendedAction
    }
}

/// Payment failure reasons
public enum PaymentFailureReason: String, CaseIterable, Codable {
    case insufficientFunds = "insufficient_funds"
    case expiredCard = "expired_card"
    case blockedCard = "blocked_card"
    case networkError = "network_error"
    case providerDeclined = "provider_declined"
    case unknownError = "unknown_error"
    
    public var displayMessage: String {
        switch self {
        case .insufficientFunds:
            return "Insufficient funds in account"
        case .expiredCard:
            return "Payment method has expired"
        case .blockedCard:
            return "Payment method is blocked"
        case .networkError:
            return "Network connection error"
        case .providerDeclined:
            return "Payment declined by provider"
        case .unknownError:
            return "Unknown payment error"
        }
    }
    
    public var recoveryStrategy: PaymentRecoveryStrategy {
        switch self {
        case .insufficientFunds: return .gracePeriodWithNotifications
        case .expiredCard: return .immediateUpdateRequest
        case .blockedCard: return .alternatePaymentMethod
        case .networkError: return .automaticRetry
        case .providerDeclined: return .contactSupport
        case .unknownError: return .manualReview
        }
    }
}

/// Payment recovery strategies
public enum PaymentRecoveryStrategy: String, CaseIterable, Codable {
    case gracePeriodWithNotifications = "grace_period_notifications"
    case immediateUpdateRequest = "immediate_update_request"
    case alternatePaymentMethod = "alternate_payment_method"
    case automaticRetry = "automatic_retry"
    case contactSupport = "contact_support"
    case manualReview = "manual_review"
}

/// Payment recovery actions
public enum PaymentRecoveryAction: String, CaseIterable, Codable {
    case updatePaymentMethod = "update_payment_method"
    case addFunds = "add_funds"
    case contactBank = "contact_bank"
    case tryAgainLater = "try_again_later"
    case contactSupport = "contact_support"
    case useAlternateMethod = "use_alternate_method"
    
    public var displayMessage: String {
        switch self {
        case .updatePaymentMethod:
            return "Please update your payment method"
        case .addFunds:
            return "Please add funds to your account"
        case .contactBank:
            return "Please contact your bank"
        case .tryAgainLater:
            return "Please try again later"
        case .contactSupport:
            return "Please contact our support team"
        case .useAlternateMethod:
            return "Please try an alternate payment method"
        }
    }
}

/// Payment method update confirmation
public struct UpdateConfirmation: Codable {
    public let updateId: String
    public let newPaymentMethod: PaymentMethod
    public let updateDate: Date
    public let nextBillingDate: Date
    public let retryScheduledPayments: Bool
    
    public init(
        updateId: String = UUID().uuidString,
        newPaymentMethod: PaymentMethod,
        updateDate: Date = Date(),
        nextBillingDate: Date,
        retryScheduledPayments: Bool = true
    ) {
        self.updateId = updateId
        self.newPaymentMethod = newPaymentMethod
        self.updateDate = updateDate
        self.nextBillingDate = nextBillingDate
        self.retryScheduledPayments = retryScheduledPayments
    }
}

// MARK: - Billing Management Models

/// Billing date change confirmation
public struct DateChangeConfirmation: Codable {
    public let changeId: String
    public let newBillingDate: Int // 1-28
    public let effectiveDate: Date
    public let prorationAdjustment: Double?
    public let nextBillingDate: Date
    
    public init(
        changeId: String = UUID().uuidString,
        newBillingDate: Int,
        effectiveDate: Date,
        prorationAdjustment: Double? = nil,
        nextBillingDate: Date
    ) {
        self.changeId = changeId
        self.newBillingDate = newBillingDate
        self.effectiveDate = effectiveDate
        self.prorationAdjustment = prorationAdjustment
        self.nextBillingDate = nextBillingDate
    }
}

/// Billing preferences
public struct BillingPreferences: Codable {
    public let preferredBillingDate: Int? // 1-28
    public let notificationPreferences: BillingNotificationPreferences
    public let currencyPreference: String
    public let invoiceDeliveryMethod: InvoiceDeliveryMethod
    public let gracePeriodDays: Int
    
    public init(
        preferredBillingDate: Int? = nil,
        notificationPreferences: BillingNotificationPreferences = BillingNotificationPreferences(),
        currencyPreference: String = "USD",
        invoiceDeliveryMethod: InvoiceDeliveryMethod = .email,
        gracePeriodDays: Int = 7
    ) {
        self.preferredBillingDate = preferredBillingDate
        self.notificationPreferences = notificationPreferences
        self.currencyPreference = currencyPreference
        self.invoiceDeliveryMethod = invoiceDeliveryMethod
        self.gracePeriodDays = gracePeriodDays
    }
}

/// Billing notification preferences
public struct BillingNotificationPreferences: Codable {
    public let enableUpcomingBilling: Bool
    public let enablePaymentFailure: Bool
    public let enablePaymentSuccess: Bool
    public let enableBillingChanges: Bool
    public let notificationTimings: [NotificationTiming]
    
    public init(
        enableUpcomingBilling: Bool = true,
        enablePaymentFailure: Bool = true,
        enablePaymentSuccess: Bool = false,
        enableBillingChanges: Bool = true,
        notificationTimings: [NotificationTiming] = [.threeDaysBefore, .oneDayBefore]
    ) {
        self.enableUpcomingBilling = enableUpcomingBilling
        self.enablePaymentFailure = enablePaymentFailure
        self.enablePaymentSuccess = enablePaymentSuccess
        self.enableBillingChanges = enableBillingChanges
        self.notificationTimings = notificationTimings
    }
}

/// Notification timing options
public enum NotificationTiming: String, CaseIterable, Codable {
    case sevenDaysBefore = "7_days_before"
    case threeDaysBefore = "3_days_before"
    case oneDayBefore = "1_day_before"
    case onBillingDate = "on_billing_date"
    case immediately = "immediately"
    
    public var timeInterval: TimeInterval {
        switch self {
        case .sevenDaysBefore: return -7 * 24 * 60 * 60
        case .threeDaysBefore: return -3 * 24 * 60 * 60
        case .oneDayBefore: return -1 * 24 * 60 * 60
        case .onBillingDate: return 0
        case .immediately: return 0
        }
    }
    
    public var displayName: String {
        switch self {
        case .sevenDaysBefore: return "7 days before"
        case .threeDaysBefore: return "3 days before"
        case .oneDayBefore: return "1 day before"
        case .onBillingDate: return "On billing date"
        case .immediately: return "Immediately"
        }
    }
}

/// Invoice delivery methods
public enum InvoiceDeliveryMethod: String, CaseIterable, Codable {
    case email = "email"
    case inApp = "in_app"
    case both = "both"
    case none = "none"
    
    public var displayName: String {
        switch self {
        case .email: return "Email"
        case .inApp: return "In App"
        case .both: return "Email & In App"
        case .none: return "No Invoices"
        }
    }
}

// MARK: - Cancellation Models

/// Cancellation reasons
public enum CancellationReason: String, CaseIterable, Codable {
    case tooExpensive = "too_expensive"
    case notUsingEnough = "not_using_enough"
    case foundAlternative = "found_alternative"
    case technicalIssues = "technical_issues"
    case temporaryBreak = "temporary_break"
    case missingFeatures = "missing_features"
    case privacyConcerns = "privacy_concerns"
    case other = "other"
    
    public var displayName: String {
        switch self {
        case .tooExpensive: return "Too expensive"
        case .notUsingEnough: return "Not using enough"
        case .foundAlternative: return "Found alternative"
        case .technicalIssues: return "Technical issues"
        case .temporaryBreak: return "Taking a break"
        case .missingFeatures: return "Missing features"
        case .privacyConcerns: return "Privacy concerns"
        case .other: return "Other"
        }
    }
    
    public var retentionStrategy: RetentionStrategy? {
        switch self {
        case .tooExpensive: return .personalizedDiscount
        case .notUsingEnough: return .featureEducation
        case .technicalIssues: return .premiumSupport
        case .temporaryBreak: return .pauseOffer
        case .missingFeatures: return .featureEducation
        case .foundAlternative, .privacyConcerns, .other: return nil
        }
    }
}

// MARK: - Error Models

/// Subscription operation errors
public enum SubscriptionError: Error, LocalizedError {
    case pauseLimitExceeded
    case invalidPauseDuration
    case pauseNotAllowed
    case resumeNotAllowed
    case invalidTierChange
    case prorationCalculationFailed
    case paymentMethodRequired
    case billingDateInvalid
    case operationInProgress
    case storeKitError(String)
    case networkError
    case unknownError(String)
    
    public var errorDescription: String? {
        switch self {
        case .pauseLimitExceeded:
            return "You have reached the maximum number of pauses allowed this year"
        case .invalidPauseDuration:
            return "Invalid pause duration selected"
        case .pauseNotAllowed:
            return "Subscription cannot be paused at this time"
        case .resumeNotAllowed:
            return "Subscription cannot be resumed at this time"
        case .invalidTierChange:
            return "Invalid subscription tier change"
        case .prorationCalculationFailed:
            return "Unable to calculate proration amount"
        case .paymentMethodRequired:
            return "Valid payment method required"
        case .billingDateInvalid:
            return "Invalid billing date selected"
        case .operationInProgress:
            return "Another subscription operation is in progress"
        case .storeKitError(let message):
            return "Store error: \(message)"
        case .networkError:
            return "Network connection error"
        case .unknownError(let message):
            return "Unknown error: \(message)"
        }
    }
}

/// Payment operation errors
public enum PaymentError: Error, LocalizedError {
    case paymentMethodInvalid
    case paymentDeclined
    case paymentExpired
    case paymentBlocked
    case retryLimitExceeded
    case networkError
    case storeKitError(String)
    case unknownError(String)
    
    public var errorDescription: String? {
        switch self {
        case .paymentMethodInvalid:
            return "Invalid payment method"
        case .paymentDeclined:
            return "Payment was declined"
        case .paymentExpired:
            return "Payment method has expired"
        case .paymentBlocked:
            return "Payment method is blocked"
        case .retryLimitExceeded:
            return "Maximum retry attempts exceeded"
        case .networkError:
            return "Network connection error"
        case .storeKitError(let message):
            return "Store error: \(message)"
        case .unknownError(let message):
            return "Unknown error: \(message)"
        }
    }
}

/// Billing operation errors
public enum BillingError: Error, LocalizedError {
    case invalidBillingDate
    case billingDateNotAllowed
    case prorationError
    case billingCycleChangeNotAllowed
    case networkError
    case unknownError(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidBillingDate:
            return "Invalid billing date selected"
        case .billingDateNotAllowed:
            return "Billing date change not allowed"
        case .prorationError:
            return "Error calculating proration"
        case .billingCycleChangeNotAllowed:
            return "Billing cycle change not allowed"
        case .networkError:
            return "Network connection error"
        case .unknownError(let message):
            return "Unknown error: \(message)"
        }
    }
}

// Forward declaration for RetentionStrategy (will be defined in churn prevention phase)
public enum RetentionStrategy: String, CaseIterable, Codable {
    case personalizedDiscount = "personalized_discount"
    case featureEducation = "feature_education"
    case premiumSupport = "premium_support"
    case communityInvitation = "community_invitation"
    case trialExtension = "trial_extension"
    case downgradePrevention = "downgrade_prevention"
    case pauseOffer = "pause_offer"
}