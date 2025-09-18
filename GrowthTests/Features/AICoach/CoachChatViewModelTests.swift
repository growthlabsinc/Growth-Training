//
//  CoachChatViewModelTests.swift
//  GrowthTests
//
//  Created by Developer on 7/15/25.
//

import XCTest
import Combine
import Firebase
import FirebaseFunctions
@testable import Growth

class CoachChatViewModelTests: XCTestCase {
    var viewModel: CoachChatViewModel!
    var mockService: AICoachService!
    var cancellables = Set<AnyCancellable>()
    
    override func setUp() {
        super.setUp()
        // Create a test instance of the service with test mode enabled
        mockService = AICoachService(isTestMode: true)
        viewModel = CoachChatViewModel(aiCoachService: mockService)
    }
    
    override func tearDown() {
        cancellables.removeAll()
        viewModel = nil
        mockService = nil
        super.tearDown()
    }
    
    func testInitialState() {
        // Verify initial state of the view model
        XCTAssertEqual(viewModel.currentInput, "")
        XCTAssertFalse(viewModel.isProcessing)
        XCTAssertNil(viewModel.errorMessage)
        
        // Should have a welcome message
        XCTAssertEqual(viewModel.messages.count, 1)
        XCTAssertEqual(viewModel.messages.first?.sender, .ai)
    }
    
    func testSendMessage() async {
        // Set up the input text
        viewModel.currentInput = "Hello"
        
        // Verify initial count
        let initialCount = viewModel.messages.count
        
        // Send the message
        await viewModel.sendMessage()
        
        // Verify message count increased by 2 (user message + AI response)
        XCTAssertEqual(viewModel.messages.count, initialCount + 2)
        
        // Verify user message was added
        XCTAssertEqual(viewModel.messages[initialCount].text, "Hello")
        XCTAssertEqual(viewModel.messages[initialCount].sender, .user)
        
        // Verify AI response was added
        XCTAssertEqual(viewModel.messages[initialCount + 1].sender, .ai)
        XCTAssertFalse(viewModel.messages[initialCount + 1].text.isEmpty)
        
        // Verify input was cleared and processing flag was reset
        XCTAssertEqual(viewModel.currentInput, "")
        XCTAssertFalse(viewModel.isProcessing)
    }
    
    func testSendEmptyMessage() async {
        // Set up empty input text
        viewModel.currentInput = "   "
        
        // Get initial count
        let initialCount = viewModel.messages.count
        
        // Send the message
        await viewModel.sendMessage()
        
        // Verify no messages were added
        XCTAssertEqual(viewModel.messages.count, initialCount)
    }
    
    func testSendMessageWhileProcessing() async {
        // Set the processing flag
        await MainActor.run {
            viewModel.isProcessing = true
            viewModel.currentInput = "Test"
        }
        
        // Get initial count
        let initialCount = viewModel.messages.count
        
        // Send the message
        await viewModel.sendMessage()
        
        // Verify no messages were added
        XCTAssertEqual(viewModel.messages.count, initialCount)
    }
    
    func testClearChat() {
        // Add some messages
        viewModel.messages.append(ChatMessage.userMessage("Test message"))
        viewModel.messages.append(ChatMessage.aiMessage("Test response"))
        
        // Clear the chat
        viewModel.clearChat()
        
        // Verify only welcome message remains
        XCTAssertEqual(viewModel.messages.count, 1)
        XCTAssertEqual(viewModel.messages.first?.sender, .ai)
    }
    
    func testPublishedPropertiesUpdate() {
        // Create expectations for the @Published properties
        let expectationMessages = expectation(description: "messages published")
        let expectationInput = expectation(description: "input published")
        let expectationProcessing = expectation(description: "processing published")
        
        // Subscribe to messages changes
        viewModel.$messages
            .dropFirst() // Skip the initial value
            .sink { _ in
                expectationMessages.fulfill()
            }
            .store(in: &cancellables)
        
        // Subscribe to input changes
        viewModel.$currentInput
            .dropFirst() // Skip the initial value
            .sink { _ in
                expectationInput.fulfill()
            }
            .store(in: &cancellables)
        
        // Subscribe to processing changes
        viewModel.$isProcessing
            .dropFirst() // Skip the initial value
            .sink { _ in
                expectationProcessing.fulfill()
            }
            .store(in: &cancellables)
        
        // Make changes to trigger the publishers
        viewModel.messages.append(ChatMessage.userMessage("Test"))
        viewModel.currentInput = "Hello"
        viewModel.isProcessing = true
        
        // Wait for the expectations
        wait(for: [expectationMessages, expectationInput, expectationProcessing], timeout: 1.0)
    }
} 