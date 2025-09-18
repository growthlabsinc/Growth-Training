//
//  AICoachServiceTests.swift
//  GrowthTests
//
//  Created by Developer on 7/15/25.
//

import XCTest
import Firebase
import FirebaseFunctions
@testable import Growth

class AICoachServiceTests: XCTestCase {
    var mockService: AICoachService!
    
    override func setUp() {
        super.setUp()
        // Create a test instance of the service with test mode enabled
        mockService = AICoachService(isTestMode: true)
    }
    
    override func tearDown() {
        mockService = nil
        super.tearDown()
    }
    
    func testSendMessageReturnsResponse() async {
        do {
            // Test with a simple message
            let response = try await mockService.sendMessage("Hello")
            
            // Verify response properties
            XCTAssertEqual(response.sender, .ai)
            XCTAssertFalse(response.text.isEmpty)
            XCTAssertNil(response.error)
            
            // Verify timestamp is recent
            let fiveSecondsAgo = Date().timeIntervalSince1970 - 5
            XCTAssertGreaterThan(response.timestamp.timeIntervalSince1970, fiveSecondsAgo)
        } catch {
            XCTFail("Sending message failed with error: \(error)")
        }
    }
    
    func testSendMethodQueryReturnsSources() async {
        do {
            // Test with a method-related query (should return sources)
            let response = try await mockService.sendMessage("Tell me about growth methods")
            
            // Verify sources are included
            XCTAssertNotNil(response.sources)
            XCTAssertFalse(response.sources?.isEmpty ?? true)
            
            // Verify first source has expected properties
            if let firstSource = response.sources?.first {
                XCTAssertFalse(firstSource.title.isEmpty)
                XCTAssertFalse(firstSource.snippet.isEmpty)
                XCTAssertGreaterThan(firstSource.confidence, 0)
            } else {
                XCTFail("Expected sources but none found")
            }
        } catch {
            XCTFail("Sending message failed with error: \(error)")
        }
    }
    
    func testCreateUserMessage() {
        // Test user message creation
        let message = ChatMessage.userMessage("Test message")
        
        XCTAssertEqual(message.text, "Test message")
        XCTAssertEqual(message.sender, .user)
        XCTAssertNil(message.error)
        XCTAssertNil(message.sources)
    }
    
    func testCreateAIMessage() {
        // Test AI message creation
        let source = KnowledgeSource(title: "Test Source", snippet: "Test snippet", confidence: 0.95)
        let message = ChatMessage.aiMessage("Test response", sources: [source])
        
        XCTAssertEqual(message.text, "Test response")
        XCTAssertEqual(message.sender, .ai)
        XCTAssertNil(message.error)
        XCTAssertEqual(message.sources?.count, 1)
        XCTAssertEqual(message.sources?.first?.title, "Test Source")
    }
    
    func testCreateErrorMessage() {
        // Test error message creation
        let message = ChatMessage.aiErrorMessage("Test error")
        
        XCTAssertEqual(message.sender, .ai)
        XCTAssertNotEqual(message.text, "Test error") // Error message should be user-friendly
        XCTAssertEqual(message.error, "Test error") // Original error is stored
    }
} 