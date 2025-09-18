/**
 * PurchaseResult.swift
 * Growth App Purchase Flow Result Types
 *
 * Defines result types and error handling for StoreKit 2 purchase flows,
 * including success, cancellation, failure, and pending states.
 */

import Foundation
import StoreKit

// MARK: - Purchase Result

/// Result of a purchase attempt
@available(iOS 15.0, *)
enum PurchaseResult: Equatable {
    case success(Transaction)
    case cancelled
    case failed(PurchaseError)
    case pending
    
    /// Whether the purchase was successful
    var isSuccessful: Bool {
        switch self {
        case .success:
            return true
        case .cancelled, .failed, .pending:
            return false
        }
    }
    
    /// Get the transaction if successful
    var transaction: Transaction? {
        switch self {
        case .success(let transaction):
            return transaction
        case .cancelled, .failed, .pending:
            return nil
        }
    }
    
    /// Get the error if failed
    var error: PurchaseError? {
        switch self {
        case .failed(let error):
            return error
        case .success, .cancelled, .pending:
            return nil
        }
    }
}

// MARK: - Purchase Error

/// Comprehensive error types for purchase flow
enum PurchaseError: LocalizedError, Equatable {
    case networkError
    case invalidProduct
    case paymentNotAllowed
    case paymentCancelled
    case storeKitError(Error)
    case verificationFailed
    case serverValidationFailed
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network connection required for purchase"
        case .invalidProduct:
            return "This subscription is not available"
        case .paymentNotAllowed:
            return "Purchases are not allowed on this device"
        case .paymentCancelled:
            return "Purchase was cancelled"
        case .storeKitError(let error):
            return "Purchase failed: \(error.localizedDescription)"
        case .verificationFailed:
            return "Could not verify purchase"
        case .serverValidationFailed:
            return "Server validation failed"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Check your internet connection and try again"
        case .invalidProduct:
            return "Please try selecting a different subscription option"
        case .paymentNotAllowed:
            return "Check your device restrictions in Settings"
        case .paymentCancelled:
            return "Try purchasing again when ready"
        case .storeKitError:
            return "Please try again or contact support if the problem persists"
        case .verificationFailed:
            return "Please try again or contact support"
        case .serverValidationFailed:
            return "Please check your connection and try again"
        case .unknownError:
            return "Please try again or contact support"
        }
    }
    
    /// Whether the user can retry the purchase
    var isRetryable: Bool {
        switch self {
        case .networkError, .storeKitError, .serverValidationFailed, .unknownError:
            return true
        case .invalidProduct, .paymentNotAllowed, .paymentCancelled, .verificationFailed:
            return false
        }
    }
    
    static func == (lhs: PurchaseError, rhs: PurchaseError) -> Bool {
        switch (lhs, rhs) {
        case (.networkError, .networkError),
             (.invalidProduct, .invalidProduct),
             (.paymentNotAllowed, .paymentNotAllowed),
             (.paymentCancelled, .paymentCancelled),
             (.verificationFailed, .verificationFailed),
             (.serverValidationFailed, .serverValidationFailed),
             (.unknownError, .unknownError):
            return true
        case (.storeKitError(let lhsError), .storeKitError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

// MARK: - Purchase State

/// Current state of the purchase flow
enum PurchaseState: Equatable {
    case idle
    case loadingProducts
    case readyToPurchase
    case purchasing
    case processing
    case completed(PurchaseResult)
    case failed(PurchaseError)
    
    var isLoading: Bool {
        switch self {
        case .loadingProducts, .purchasing, .processing:
            return true
        case .idle, .readyToPurchase, .completed, .failed:
            return false
        }
    }
    
    var canPurchase: Bool {
        switch self {
        case .readyToPurchase:
            return true
        case .idle, .loadingProducts, .purchasing, .processing, .completed, .failed:
            return false
        }
    }
}

// MARK: - Restore Result

/// Result of restore purchases operation
enum RestoreResult {
    case success([Transaction])
    case failed(RestoreError)
    case noEntitlementsFound
    
    var isSuccessful: Bool {
        switch self {
        case .success:
            return true
        case .failed, .noEntitlementsFound:
            return false
        }
    }
    
    var transactions: [Transaction] {
        switch self {
        case .success(let transactions):
            return transactions
        case .failed, .noEntitlementsFound:
            return []
        }
    }
}

// MARK: - Restore Error

/// Errors that can occur during restore purchases
enum RestoreError: LocalizedError {
    case networkError
    case storeKitError(Error)
    case noActiveSubscriptions
    case verificationFailed
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network connection required to restore purchases"
        case .storeKitError(let error):
            return "Restore failed: \(error.localizedDescription)"
        case .noActiveSubscriptions:
            return "No active subscriptions found"
        case .verificationFailed:
            return "Could not verify restored purchases"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Check your internet connection and try again"
        case .storeKitError:
            return "Please try again or contact support"
        case .noActiveSubscriptions:
            return "Make sure you're signed in with the same Apple ID used for purchase"
        case .verificationFailed:
            return "Please try again or contact support"
        }
    }
}