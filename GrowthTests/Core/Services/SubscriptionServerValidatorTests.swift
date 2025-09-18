//
//  SubscriptionServerValidatorTests.swift
//  GrowthTests
//
//  Created by Growth on 1/19/25.
//

import XCTest
@testable import Growth
import FirebaseFunctions

@available(iOS 15.0, *)
class SubscriptionServerValidatorTests: XCTestCase {
    
    var sut: SubscriptionServerValidator!
    var mockFunctions: MockFunctions!
    
    override func setUp() async throws {
        try await super.setUp()
        sut = SubscriptionServerValidator.shared
        mockFunctions = MockFunctions()
    }
    
    override func tearDown() async throws {
        sut = nil
        mockFunctions = nil
        try await super.tearDown()
    }
    
    // MARK: - Receipt Validation Tests
    
    func testValidateReceipt_Success() async throws {
        // Given
        let receiptData = "test-receipt-data"
        let expectedState = SubscriptionState.active(
            tier: .premium,
            expirationDate: Date().addingTimeInterval(30 * 24 * 60 * 60),
            productId: "com.growth.subscription.premium.monthly"
        )
        
        mockFunctions.mockValidationResponse = [
            "isValid": true,
            "tier": "premium",
            "expirationDate": ISO8601DateFormatter().string(from: expectedState.expirationDate!),
            "transactionId": "test-transaction-123",
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        // When
        let result = try await sut.validateReceipt(receiptData)
        
        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.state.tier, .premium)
        XCTAssertEqual(result.source, .server)
        XCTAssertNotNil(result.serverReceiptHash)
    }
    
    func testValidateReceipt_InvalidReceipt() async throws {
        // Given
        let receiptData = "invalid-receipt"
        
        mockFunctions.mockValidationResponse = [
            "isValid": false,
            "tier": "none",
            "error": "Invalid receipt format",
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        // When
        let result = try await sut.validateReceipt(receiptData)
        
        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.state.tier, .none)
        XCTAssertNotNil(result.error)
    }
    
    func testValidateReceipt_NetworkError() async {
        // Given
        let receiptData = "test-receipt"
        mockFunctions.shouldThrowError = true
        
        // When/Then
        do {
            _ = try await sut.validateReceipt(receiptData)
            XCTFail("Should throw error")
        } catch {
            XCTAssertTrue(error is SubscriptionServerValidator.ValidationError)
        }
    }
    
    // MARK: - Webhook Processing Tests
    
    func testProcessWebhookUpdate_Renewal() async throws {
        // Given
        let update = WebhookUpdate(
            transactionId: "txn-123",
            subscriptionStatus: .active,
            expirationDate: Date().addingTimeInterval(30 * 24 * 60 * 60),
            eventType: .renewed,
            bundleId: "com.growth",
            productId: "com.growth.subscription.premium.monthly"
        )
        
        // When
        let state = try await sut.processWebhookUpdate(update)
        
        // Then
        XCTAssertEqual(state.status, .active)
        XCTAssertEqual(state.tier, .premium)
        XCTAssertEqual(state.validationSource, .server)
    }
    
    func testProcessWebhookUpdate_Cancellation() async throws {
        // Given
        let update = WebhookUpdate(
            transactionId: "txn-456",
            subscriptionStatus: .expired,
            expirationDate: Date().addingTimeInterval(-1),
            eventType: .cancelled,
            bundleId: "com.growth",
            productId: "com.growth.subscription.basic.monthly"
        )
        
        // When
        let state = try await sut.processWebhookUpdate(update)
        
        // Then
        XCTAssertEqual(state.status, .cancelled)
        XCTAssertEqual(state.tier, .none)
    }
    
    func testProcessWebhookUpdate_GracePeriod() async throws {
        // Given
        let gracePeriodEnd = Date().addingTimeInterval(7 * 24 * 60 * 60)
        let update = WebhookUpdate(
            transactionId: "txn-789",
            subscriptionStatus: .gracePeriod,
            expirationDate: Date().addingTimeInterval(-1),
            eventType: .gracePeriod,
            bundleId: "com.growth",
            productId: "com.growth.subscription.elite.monthly",
            gracePeriodEndDate: gracePeriodEnd
        )
        
        // When
        let state = try await sut.processWebhookUpdate(update)
        
        // Then
        XCTAssertEqual(state.status, .grace)
        XCTAssertEqual(state.tier, .elite)
        XCTAssertTrue(state.hasActiveAccess)
    }
    
    // MARK: - Retry Logic Tests
    
    func testExponentialBackoff() async {
        // Given
        mockFunctions.failureCount = 2 // Fail first 2 attempts
        let receiptData = "test-receipt"
        
        let startTime = Date()
        
        // When
        do {
            _ = try await sut.validateReceipt(receiptData)
        } catch {
            // Expected to succeed after retries
        }
        
        // Then
        let elapsedTime = Date().timeIntervalSince(startTime)
        XCTAssertGreaterThan(elapsedTime, 2.0) // Should have delay from retries
    }
    
    // MARK: - Circuit Breaker Tests
    
    func testCircuitBreaker_OpensAfterFailures() async {
        // Given - simulate multiple failures
        mockFunctions.shouldThrowError = true
        
        // When - make multiple failing requests
        for _ in 0..<5 {
            do {
                _ = try await sut.validateReceipt("test")
            } catch {
                // Expected
            }
        }
        
        // Then - circuit breaker should be open
        do {
            _ = try await sut.validateReceipt("test")
            XCTFail("Should throw circuit breaker error")
        } catch {
            if let error = error as? SubscriptionServerValidator.ValidationError {
                XCTAssertEqual(error, .serverUnavailable)
            }
        }
    }
}

// MARK: - Mock Objects

@available(iOS 15.0, *)
class MockFunctions {
    var mockValidationResponse: [String: Any] = [:]
    var shouldThrowError = false
    var failureCount = 0
    private var currentAttempt = 0
    
    func validateReceipt(_ data: [String: Any]) async throws -> HTTPSCallableResult {
        currentAttempt += 1
        
        if shouldThrowError || currentAttempt <= failureCount {
            throw FunctionsErrorCode(.unavailable)
        }
        
        return HTTPSCallableResult(data: mockValidationResponse)
    }
}

// MARK: - Test Helpers

extension SubscriptionServerValidator.ValidationError: Equatable {
    public static func == (lhs: SubscriptionServerValidator.ValidationError, rhs: SubscriptionServerValidator.ValidationError) -> Bool {
        switch (lhs, rhs) {
        case (.noNetwork, .noNetwork),
             (.serverUnavailable, .serverUnavailable),
             (.unauthenticated, .unauthenticated),
             (.invalidReceipt, .invalidReceipt),
             (.invalidResponse, .invalidResponse):
            return true
        case (.serverError(let lhsMessage), .serverError(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}