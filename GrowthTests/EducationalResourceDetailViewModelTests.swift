//
//  EducationalResourceDetailViewModelTests.swift
//  GrowthTests
//
//  Created by Developer on 5/20/25.
//

import XCTest
@testable import Growth
import FirebaseFirestore

class MockFirestoreService: FirestoreService {
    var shouldSucceed = true
    var mockResource: EducationalResource?
    var mockError: Error?
    
    override func getEducationalResource(resourceId: String, completion: @escaping (EducationalResource?, Error?) -> Void) {
        if shouldSucceed {
            completion(mockResource, nil)
        } else {
            let error = mockError ?? NSError(domain: "MockFirestoreError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Resource not found"])
            completion(nil, error)
        }
    }
}

final class EducationalResourceDetailViewModelTests: XCTestCase {
    
    var mockService: MockFirestoreService!
    var viewModel: EducationalResourceDetailViewModel!
    
    override func setUp() {
        super.setUp()
        mockService = MockFirestoreService()
    }
    
    override func tearDown() {
        mockService = nil
        viewModel = nil
        super.tearDown()
    }
    
    func testSuccessfulResourceFetch() {
        // Arrange
        let expectedResource = EducationalResource(
            id: "test-id",
            title: "Test Article",
            contentText: "This is the test content.",
            category: .basics,
            visualPlaceholderUrl: "https://example.com/image.jpg",
            localImageName: nil
        )
        mockService.mockResource = expectedResource
        mockService.shouldSucceed = true
        
        // Act
        viewModel = EducationalResourceDetailViewModel(resourceId: "test-id", firestoreService: mockService)
        
        // Use expectation to wait for the async operation
        let expectation = XCTestExpectation(description: "Resource fetch completes")
        
        // Wait a short time for the async operation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Assert
            XCTAssertFalse(self.viewModel.isLoading)
            XCTAssertNil(self.viewModel.errorMessage)
            XCTAssertNotNil(self.viewModel.resource)
            XCTAssertEqual(self.viewModel.resource?.id, expectedResource.id)
            XCTAssertEqual(self.viewModel.resource?.title, expectedResource.title)
            XCTAssertEqual(self.viewModel.resource?.contentText, expectedResource.contentText)
            XCTAssertEqual(self.viewModel.resource?.category, expectedResource.category)
            XCTAssertEqual(self.viewModel.resource?.visualPlaceholderUrl, expectedResource.visualPlaceholderUrl)
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFailedResourceFetch() {
        // Arrange
        let expectedError = NSError(domain: "TestError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Test error message"])
        mockService.mockError = expectedError
        mockService.shouldSucceed = false
        
        // Act
        viewModel = EducationalResourceDetailViewModel(resourceId: "test-id", firestoreService: mockService)
        
        // Use expectation to wait for the async operation
        let expectation = XCTestExpectation(description: "Resource fetch fails")
        
        // Wait a short time for the async operation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Assert
            XCTAssertFalse(self.viewModel.isLoading)
            XCTAssertNotNil(self.viewModel.errorMessage)
            XCTAssertEqual(self.viewModel.errorMessage, expectedError.localizedDescription)
            XCTAssertNil(self.viewModel.resource)
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testResourceNotFound() {
        // Arrange
        mockService.mockResource = nil
        mockService.shouldSucceed = true
        
        // Act
        viewModel = EducationalResourceDetailViewModel(resourceId: "test-id", firestoreService: mockService)
        
        // Use expectation to wait for the async operation
        let expectation = XCTestExpectation(description: "Resource not found")
        
        // Wait a short time for the async operation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Assert
            XCTAssertFalse(self.viewModel.isLoading)
            XCTAssertNotNil(self.viewModel.errorMessage)
            XCTAssertEqual(self.viewModel.errorMessage, "Resource not found")
            XCTAssertNil(self.viewModel.resource)
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testRefetchResource() {
        // Arrange
        let expectedResource = EducationalResource(
            id: "test-id",
            title: "Test Article",
            contentText: "This is the test content.",
            category: .basics,
            visualPlaceholderUrl: "https://example.com/image.jpg",
            localImageName: nil
        )
        mockService.mockResource = expectedResource
        mockService.shouldSucceed = true
        
        viewModel = EducationalResourceDetailViewModel(resourceId: "test-id", firestoreService: mockService)
        
        // First fetch (happens in init)
        let firstFetchExpectation = XCTestExpectation(description: "First fetch completes")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Verify first fetch succeeded
            XCTAssertNotNil(self.viewModel.resource)
            
            // Change mock data for second fetch
            let updatedResource = EducationalResource(
                id: "test-id",
                title: "Updated Title",
                contentText: "Updated content.",
                category: .basics,
                visualPlaceholderUrl: "https://example.com/updated.jpg",
                localImageName: "beginners-guide-angion"
            )
            self.mockService.mockResource = updatedResource
            
            // Act - trigger a refetch
            self.viewModel.fetchResource()
            
            firstFetchExpectation.fulfill()
        }
        
        wait(for: [firstFetchExpectation], timeout: 1.0)
        
        // Second fetch expectation
        let secondFetchExpectation = XCTestExpectation(description: "Second fetch completes")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Assert second fetch results
            XCTAssertFalse(self.viewModel.isLoading)
            XCTAssertNil(self.viewModel.errorMessage)
            XCTAssertNotNil(self.viewModel.resource)
            XCTAssertEqual(self.viewModel.resource?.title, "Updated Title")
            XCTAssertEqual(self.viewModel.resource?.contentText, "Updated content.")
            
            secondFetchExpectation.fulfill()
        }
        
        wait(for: [secondFetchExpectation], timeout: 1.0)
    }
} 