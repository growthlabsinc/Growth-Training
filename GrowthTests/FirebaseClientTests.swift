//
//  FirebaseClientTests.swift
//  GrowthTests
//
//  Created by Developer on 5/8/25.
//

import XCTest
@testable import Growth
import FirebaseFirestore

final class FirebaseClientTests: XCTestCase {
    
    func testFirebaseEnvironmentConfigFileNames() {
        // Test development environment
        let devEnvironment = FirebaseEnvironment.development
        XCTAssertEqual(devEnvironment.configFileName, "dev.GoogleService-Info")
        
        // Test staging environment
        let stagingEnvironment = FirebaseEnvironment.staging
        XCTAssertEqual(stagingEnvironment.configFileName, "staging.GoogleService-Info")
        
        // Test production environment
        let prodEnvironment = FirebaseEnvironment.production
        XCTAssertEqual(prodEnvironment.configFileName, "GoogleService-Info")
    }
    
    func testFirebaseEnvironmentRawValues() {
        // Test development environment
        let devEnvironment = FirebaseEnvironment.development
        XCTAssertEqual(devEnvironment.rawValue, "dev")
        
        // Test staging environment
        let stagingEnvironment = FirebaseEnvironment.staging
        XCTAssertEqual(stagingEnvironment.rawValue, "staging")
        
        // Test production environment
        let prodEnvironment = FirebaseEnvironment.production
        XCTAssertEqual(prodEnvironment.rawValue, "prod")
    }
    
    func testFirebaseEnvironmentConvenienceProperties() {
        // Test development environment
        let devEnvironment = FirebaseEnvironment.development
        XCTAssertTrue(devEnvironment.isDevelopment)
        XCTAssertFalse(devEnvironment.isStaging)
        XCTAssertFalse(devEnvironment.isProduction)
        
        // Test staging environment
        let stagingEnvironment = FirebaseEnvironment.staging
        XCTAssertFalse(stagingEnvironment.isDevelopment)
        XCTAssertTrue(stagingEnvironment.isStaging)
        XCTAssertFalse(stagingEnvironment.isProduction)
        
        // Test production environment
        let prodEnvironment = FirebaseEnvironment.production
        XCTAssertFalse(prodEnvironment.isDevelopment)
        XCTAssertFalse(prodEnvironment.isStaging)
        XCTAssertTrue(prodEnvironment.isProduction)
    }
    
    // MARK: - Firestore Tests
    
    func testFirestoreCollectionAccess() {
        // Test getting a collection reference
        let collectionRef = FirebaseClient.shared.collection("users")
        XCTAssertEqual(collectionRef.collectionID, "users")
    }
    
    func testFirestoreDocumentAccess() {
        // Test getting a document reference
        let docRef = FirebaseClient.shared.document(inCollection: "users", withID: "test-user-id")
        XCTAssertEqual(docRef.documentID, "test-user-id")
        XCTAssertEqual(docRef.parent.collectionID, "users")
    }
    
    func testFirestoreAutoIDDocument() {
        // Test creating a document with auto-generated ID
        let docRef = FirebaseClient.shared.createDocument(inCollection: "users")
        XCTAssertFalse(docRef.documentID.isEmpty, "Auto-generated document ID should not be empty")
        XCTAssertEqual(docRef.parent.collectionID, "users")
    }
    
    func testFirestoreBatchCreation() {
        // Test creating a write batch
        let batch = FirebaseClient.shared.batch()
        XCTAssertNotNil(batch)
    }
    
    func testFirestoreCollectionGroupAccess() {
        // Test getting a collection group reference
        let query = FirebaseClient.shared.collectionGroup("sessionLogs")
        XCTAssertNotNil(query)
    }
    
    func testSnapshotsInSyncListener() {
        // Test adding a snapshots in sync listener
        let registration = FirebaseClient.shared.addSnapshotsInSyncListener {
            // This would be called when all snapshots are in sync
        }
        
        XCTAssertNotNil(registration)
        
        // Clean up
        registration.remove()
    }
    
    func testFirestorePersistenceSettings() {
        // Test that FirestoreSettings and PersistentCacheSettings are configured correctly
        let client = FirebaseClient.shared
        
        // Get the settings from the Firestore instance
        let settings = client.firestore.settings
        
        // Verify the client was initialized correctly
        XCTAssertNotNil(client.firestore)
        XCTAssertEqual(client.currentEnvironment, .development)
        
        // Verify that the cache settings are of type PersistentCacheSettings
        if let cacheSettings = settings.cacheSettings as? PersistentCacheSettings {
            // Converting to Int64 for comparison because NSNumber value isn't directly comparable
            let expectedCacheSize: Int64 = 100 * 1024 * 1024 // 100MB
            XCTAssertEqual(cacheSettings.sizeBytes.int64Value, expectedCacheSize)
        } else {
            XCTFail("Cache settings should be of type PersistentCacheSettings")
        }
    }
    
    // NOTE: The following tests require actual Firebase configuration
    // which would not be available in CI environments without special setup.
    // They're commented out but can be used during local development with proper configurations.
    /*
    func testFirebaseConnection() {
        let expectation = self.expectation(description: "Firebase connection test")
        
        FirebaseClient.shared.configure(for: .development)
        FirebaseClient.shared.testConnection { success, error in
            XCTAssertTrue(success, "Firebase connection should succeed")
            XCTAssertNil(error, "There should be no error")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testFirestoreTransaction() {
        let expectation = self.expectation(description: "Firestore transaction test")
        
        FirebaseClient.shared.runTransaction({ transaction -> String in
            return "Transaction successful"
        }) { result in
            switch result {
            case .success(let message):
                XCTAssertEqual(message, "Transaction successful")
            case .failure(let error):
                XCTFail("Transaction should not fail: \(error.localizedDescription)")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testFirestoreNetworkToggle() {
        let disableExpectation = self.expectation(description: "Disable network test")
        let enableExpectation = self.expectation(description: "Enable network test")
        
        FirebaseClient.shared.disableNetwork { error in
            XCTAssertNil(error, "Disabling network should not produce error")
            disableExpectation.fulfill()
            
            FirebaseClient.shared.enableNetwork { error in
                XCTAssertNil(error, "Enabling network should not produce error")
                enableExpectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testFirestorePersistenceManagement() {
        let expectation = self.expectation(description: "Clear persistence test")
        
        FirebaseClient.shared.clearPersistence { error in
            XCTAssertNil(error, "Clearing persistence should not produce error")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    */
} 