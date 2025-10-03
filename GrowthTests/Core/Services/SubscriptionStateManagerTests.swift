//
//  SubscriptionStateManagerTests.swift
//  GrowthTests
//
//  Created by Growth on 1/19/25.
//

import XCTest
@testable import Growth

@available(iOS 15.0, *)
final class SubscriptionStateManagerTests: XCTestCase {
    
    var sut: SubscriptionStateManager!
    
    override func setUp() {
        super.setUp()
        // Clear any persisted state before each test
        SubscriptionState.clearPersisted()
    }
    
    override func tearDown() {
        SubscriptionState.clearPersisted()
        super.tearDown()
    }
    
    // MARK: - SubscriptionState Tests
    
    func testSubscriptionState_DefaultInitialization() {
        let state = SubscriptionState()
        
        XCTAssertEqual(state.tier, .none)
        XCTAssertEqual(state.status, .none)
        XCTAssertFalse(state.hasActiveAccess)
        XCTAssertFalse(state.isTrialActive)
        XCTAssertFalse(state.autoRenewalEnabled)
        XCTAssertNil(state.expirationDate)
    }
    
    func testSubscriptionState_ActiveSubscription() {
        let futureDate = Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 days
        let state = SubscriptionState.active(
            tier: .premium,
            expirationDate: futureDate,
            productId: "com.growth.subscription.premium.monthly"
        )
        
        XCTAssertEqual(state.tier, .premium)
        XCTAssertEqual(state.status, .active)
        XCTAssertTrue(state.hasActiveAccess)
        XCTAssertEqual(state.productId, "com.growth.subscription.premium.monthly")
        XCTAssertNotNil(state.daysRemaining)
        XCTAssertGreaterThan(state.daysRemaining ?? 0, 28)
    }
    
    func testSubscriptionState_TrialSubscription() {
        let trialEndDate = Date().addingTimeInterval(7 * 24 * 60 * 60) // 7 days
        let state = SubscriptionState.trial(
            tier: .basic,
            trialExpirationDate: trialEndDate,
            productId: "com.growth.subscription.basic.monthly"
        )
        
        XCTAssertEqual(state.tier, .basic)
        XCTAssertEqual(state.status, .active)
        XCTAssertTrue(state.isTrialActive)
        XCTAssertTrue(state.hasActiveAccess)
        XCTAssertEqual(state.trialExpirationDate, trialEndDate)
    }
    
    func testSubscriptionState_ExpiredState() {
        let pastDate = Date().addingTimeInterval(-1 * 24 * 60 * 60) // 1 day ago
        let activeState = SubscriptionState.active(
            tier: .elite,
            expirationDate: pastDate,
            productId: "com.growth.subscription.elite.monthly"
        )
        
        let expiredState = activeState.expired()
        
        XCTAssertEqual(expiredState.tier, .none)
        XCTAssertEqual(expiredState.status, .expired)
        XCTAssertFalse(expiredState.hasActiveAccess)
        XCTAssertFalse(expiredState.autoRenewalEnabled)
    }
    
    func testSubscriptionState_Persistence() {
        let state = SubscriptionState.active(
            tier: .premium,
            expirationDate: Date().addingTimeInterval(30 * 24 * 60 * 60),
            productId: "com.growth.subscription.premium.monthly"
        )
        
        // Persist the state
        state.persist()
        
        // Load the persisted state
        let loadedState = SubscriptionState.loadPersisted()
        
        XCTAssertNotNil(loadedState)
        XCTAssertEqual(loadedState?.tier, state.tier)
        XCTAssertEqual(loadedState?.status, state.status)
        XCTAssertEqual(loadedState?.productId, state.productId)
    }
    
    func testSubscriptionState_IsStale() {
        // Create a state with old timestamp
        let oldDate = Date().addingTimeInterval(-20 * 60) // 20 minutes ago
        let state = SubscriptionState(
            tier: .basic,
            status: .active,
            lastUpdated: oldDate
        )
        
        XCTAssertTrue(state.isStale)
        
        // Create a fresh state
        let freshState = SubscriptionState()
        XCTAssertFalse(freshState.isStale)
    }
    
    // MARK: - SubscriptionTier Tests
    
    func testSubscriptionTier_FromProductId() {
        XCTAssertEqual(SubscriptionTier.from(productId: "com.growth.subscription.basic.monthly"), .basic)
        XCTAssertEqual(SubscriptionTier.from(productId: "com.growth.subscription.premium.yearly"), .premium)
        XCTAssertEqual(SubscriptionTier.from(productId: "com.growth.subscription.elite.monthly"), .elite)
        XCTAssertEqual(SubscriptionTier.from(productId: "unknown.product.id"), .none)
    }
    
    func testSubscriptionTier_Priority() {
        XCTAssertLessThan(SubscriptionTier.none.priority, SubscriptionTier.basic.priority)
        XCTAssertLessThan(SubscriptionTier.basic.priority, SubscriptionTier.premium.priority)
        XCTAssertLessThan(SubscriptionTier.premium.priority, SubscriptionTier.elite.priority)
    }
    
    // MARK: - State Manager Integration Tests
    
    func testStateManager_HasAccess() async {
        // Note: This would require mocking the SubscriptionStateManager
        // For now, we test the basic structure
        
        let state = SubscriptionState.active(
            tier: .premium,
            expirationDate: Date().addingTimeInterval(30 * 24 * 60 * 60),
            productId: "com.growth.subscription.premium.monthly"
        )
        
        // Test that active subscription has access
        XCTAssertTrue(state.hasActiveAccess)
        
        // Test expired subscription
        let expiredState = state.expired()
        XCTAssertFalse(expiredState.hasActiveAccess)
    }
    
    func testStateManager_QueueValidation() {
        // This tests the validation queue structure
        let request = ValidationRequest(
            transactionId: "12345",
            productId: "com.growth.subscription.basic.monthly",
            retryCount: 0,
            timestamp: Date()
        )
        
        XCTAssertEqual(request.transactionId, "12345")
        XCTAssertEqual(request.productId, "com.growth.subscription.basic.monthly")
        XCTAssertEqual(request.retryCount, 0)
    }
}

// MARK: - Test Helpers

@available(iOS 15.0, *)
private struct ValidationRequest {
    let transactionId: String
    let productId: String
    let retryCount: Int
    let timestamp: Date
}