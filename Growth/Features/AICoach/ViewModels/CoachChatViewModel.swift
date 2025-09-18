//
//  CoachChatViewModel.swift
//  Growth
//
//  Created by Developer on 7/15/25.
//

import Foundation
import SwiftUI
import Combine
import Network

/// ViewModel for managing the AI Coach chat
@MainActor
class CoachChatViewModel: ObservableObject {
    private let entitlementManager: SimplifiedEntitlementManager
    /// Messages in the conversation
    @Published var messages: [ChatMessage] = []
    
    /// Current input text
    @Published var currentInput: String = ""
    
    /// Is AI currently processing a response
    @Published var isProcessing: Bool = false
    
    /// Error message to display
    @Published var errorMessage: String? = nil
    
    /// Network status indicator
    @Published var isNetworkAvailable: Bool = true
    
    /// Maximum conversation history to keep
    private let maxHistoryLength = 20
    
    /// Maximum retry attempts
    private let maxRetryAttempts = 3
    
    /// Current retry count
    private var retryCount = 0
    
    /// Network monitor to track connection status
    private let networkMonitor = NWPathMonitor()
    
    /// Service for AI Coach interaction
    private let aiCoachService: AICoachService
    
    /// Handler for AI responses
    private let responseHandler: AIResponseHandler
    
    /// Tracks cancellable subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// Indicates if the disclaimer should be shown (modal)
    @Published var showingDisclaimerSheet: Bool = false

    /// Indicates if the user has accepted the disclaimer for this session
    @Published var hasAcceptedDisclaimerForSession: Bool = false
    
    /// Flag to prevent multiple disclaimer presentations
    private var isDisclaimerPending: Bool = false
    
    /// Initialize the view model
    /// - Parameters:
    ///   - aiCoachService: Service for AI Coach interaction
    ///   - responseHandler: Handler for AI responses
    init(
        aiCoachService: AICoachService? = nil,
        responseHandler: AIResponseHandler? = nil,
        entitlementManager: SimplifiedEntitlementManager? = nil
    ) {
        self.aiCoachService = aiCoachService ?? .shared
        self.responseHandler = responseHandler ?? .shared
        self.entitlementManager = entitlementManager ?? SimplifiedEntitlementManager()
        
        // Add welcome message
        let welcomeMessage = ChatMessage.aiMessage(
            "Hello! I'm your Growth Coach. I can help answer questions about Growth Methods, techniques, and using the app. How can I assist you today?"
        )
        self.messages.append(welcomeMessage)
        
        // Start monitoring network status
        setupNetworkMonitoring()

        // Always mark that we need to show disclaimer for each new session
        isDisclaimerPending = true
    }
    
    /// Set up network status monitoring
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isNetworkAvailable = path.status == .satisfied
                Logger.debug("Network status changed: \(path.status == .satisfied ? "Connected" : "Disconnected")")
            }
        }
        
        let queue = DispatchQueue(label: "NetworkMonitor")
        networkMonitor.start(queue: queue)
    }
    
    deinit {
        networkMonitor.cancel()
    }
    
    /// Reset network connections to try resolving issues
    func resetNetworkConnections() async {
        // First try to disable network
        let (_, _) = await aiCoachService.disableNetwork()
        
        // Wait briefly to allow connections to fully close
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Then try to re-enable network
        let (enableSuccess, error) = await aiCoachService.enableNetwork()
        
        await MainActor.run {
            if !enableSuccess {
                errorMessage = "Unable to reset network connection: \(error ?? "Unknown error")"
            } else {
                errorMessage = nil
            }
        }
    }
    
    /// Send a message from the user to the AI Coach
    /// - Parameter text: Message text to send
    func sendMessage() async {
        // Ensure there's text to send and we're not already processing
        guard !currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !isProcessing else {
            return
        }
        
        // Check if disclaimer has been accepted for this session
        if !hasAcceptedDisclaimerForSession {
            await MainActor.run {
                showingDisclaimerSheet = true
            }
            return
        }
        
        // Check network availability
        if !isNetworkAvailable {
            await MainActor.run {
                errorMessage = "No internet connection. Please check your connection and try again."
            }
            return
        }
        
        // Check feature access for non-premium users
        let hasAccess = await MainActor.run {
            entitlementManager.hasPremium
        }
        
        if !hasAccess {
            await MainActor.run {
                errorMessage = "You've used all 3 free AI coaching sessions. Upgrade to Premium for unlimited access."
            }
            return
        }
        
        // Update UI state
        let userMessage = ChatMessage.userMessage(currentInput)
        let loadingMessage = ChatMessage.aiLoadingMessage()
        
        // Update on main thread
        await MainActor.run {
            // Add user message
            messages.append(userMessage)
            
            // Add loading message
            messages.append(loadingMessage)
            
            // Clear input and show processing state
            currentInput = ""
            isProcessing = true
            errorMessage = nil
        }
        
        // Try to get a response, with retry logic
        await sendMessageWithRetry(userMessage: userMessage, loadingMessage: loadingMessage)
    }
    
    /// Send a message with automatic retry logic for network errors
    /// - Parameters:
    ///   - userMessage: The user's message
    ///   - loadingMessage: The loading placeholder message
    private func sendMessageWithRetry(userMessage: ChatMessage, loadingMessage: ChatMessage) async {
        do {
            // Reset retry count for new messages
            retryCount = 0
            
            // Get response from AI Coach service
            let response = try await aiCoachService.sendMessage(
                userMessage.text,
                conversationHistory: Array(messages.dropLast(1)), // Exclude loading message
                entitlementProvider: entitlementManager.asEntitlementProvider
            )
            
            // Process response text
            let processedText = responseHandler.processResponseText(response.text)
            
            // Create final AI message with processed text
            let aiMessage = ChatMessage(
                text: processedText,
                sender: .ai,
                sources: response.sources,
                error: response.error
            )
            
            // Update on main thread
            await MainActor.run {
                // Replace loading message with actual response
                if let loadingIndex = self.messages.firstIndex(where: { $0.id == loadingMessage.id }) {
                    self.messages[loadingIndex] = aiMessage
                } else {
                    // Fallback: remove loading and add new message
                    self.messages = self.messages.filter { $0.id != loadingMessage.id }
                    self.messages.append(aiMessage)
                }
                
                // Limit conversation history
                if self.messages.count > self.maxHistoryLength * 2 {
                    let excessCount = self.messages.count - self.maxHistoryLength * 2
                    self.messages.removeFirst(excessCount)
                }
                
                self.isProcessing = false
            }
        } catch {
            Logger.debug("Error getting AI response: \(error)")
            let nsError = error as NSError
            
            // Special handling for "NOT FOUND" errors which are usually configuration issues
            let isFunctionNotFoundError = nsError.localizedDescription.contains("NOT FOUND") || 
                                         (nsError.domain == "com.firebase.functions" && nsError.code == 404) ||
                                         (error is AICoachError && (error as! AICoachError).errorDescription?.contains("not properly configured") == true)
            
            if isFunctionNotFoundError && retryCount < maxRetryAttempts {
                retryCount += 1
                
                await MainActor.run {
                    // Update loading message text to show specific retry attempt
                    if let loadingIndex = self.messages.firstIndex(where: { $0.id == loadingMessage.id }) {
                        let retryLoadingMessage = ChatMessage.aiLoadingMessage(retryCount > 1 
                            ? "Attempting to fix connection with alternative region... (\(retryCount)/\(maxRetryAttempts))" 
                            : "Connection issue, attempting to recover... (\(retryCount)/\(maxRetryAttempts))")
                        self.messages[loadingIndex] = retryLoadingMessage
                    }
                }
                
                // Try to reset connection and reload the functions instance
                await resetNetworkConnections()
                
                // Special additional recovery for NOT FOUND - reset the functions instance
                // On second retry, try alternative region
                aiCoachService.resetCloudFunctionsInstance(tryAlternativeRegion: retryCount > 1)
                
                // Wait before retrying
                let delay = Double(pow(2.0, Double(retryCount))) + Double.random(in: 0.1...0.5)
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
                // Retry the message send
                await sendMessageWithRetry(userMessage: userMessage, loadingMessage: loadingMessage)
                return
            }
            
            // Handle standard network errors
            let isNetworkError = nsError.domain == NSURLErrorDomain && [
                NSURLErrorNotConnectedToInternet,
                NSURLErrorNetworkConnectionLost,
                NSURLErrorTimedOut,
                NSURLErrorCannotConnectToHost,
                NSURLErrorCannotFindHost,
                NSURLErrorDataNotAllowed,
                NSURLErrorCannotParseResponse
            ].contains(nsError.code)
            
            // Retry logic for network errors
            if isNetworkError && retryCount < maxRetryAttempts {
                retryCount += 1
                
                await MainActor.run {
                    // Update loading message text to show retry attempt
                    if let loadingIndex = self.messages.firstIndex(where: { $0.id == loadingMessage.id }) {
                        let retryLoadingMessage = ChatMessage.aiLoadingMessage("Connection issue, retrying... (\(retryCount)/\(maxRetryAttempts))")
                        self.messages[loadingIndex] = retryLoadingMessage
                    }
                }
                
                // Try to reset network connection
                await resetNetworkConnections()
                
                // Wait with exponential backoff before retrying
                let delay = Double(pow(2.0, Double(retryCount))) + Double.random(in: 0.1...0.5)
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
                // Retry the message send
                await sendMessageWithRetry(userMessage: userMessage, loadingMessage: loadingMessage)
                return
            }
            
            // We've exhausted retries or it's not a recoverable error
            let errorText: String
            
            // Special user-friendly error messages for common issues
            if isFunctionNotFoundError {
                errorText = "AI Coach service is not properly configured or available. This could be due to a temporary server issue or incorrect region configuration. Please try again later."
            } else {
                errorText = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
            
            // Update on main thread
            await MainActor.run {
                // Replace loading message with error message
                if let loadingIndex = self.messages.firstIndex(where: { $0.id == loadingMessage.id }) {
                    self.messages[loadingIndex] = ChatMessage.aiErrorMessage(errorText)
                } else {
                    // Fallback: remove loading and add error message
                    self.messages = self.messages.filter { $0.id != loadingMessage.id }
                    self.messages.append(ChatMessage.aiErrorMessage(errorText))
                }
                
                self.isProcessing = false
                self.errorMessage = errorText
            }
        }
    }
    
    /// Clear the chat history
    func clearChat() {
        messages = []
        
        // Add welcome message
        let welcomeMessage = ChatMessage.aiMessage(
            "Hello! I'm your Growth Coach. I can help answer questions about Growth Methods, techniques, and using the app. How can I assist you today?"
        )
        messages.append(welcomeMessage)
    }

    /// Marks the disclaimer as accepted for this session.
    func markDisclaimerAsAccepted() {
        self.hasAcceptedDisclaimerForSession = true
        self.isDisclaimerPending = false
        self.showingDisclaimerSheet = false // Dismiss the sheet
    }

    /// Shows the disclaimer details, typically triggered by an info button.
    func showDisclaimerDetails() {
        self.showingDisclaimerSheet = true
    }
    
    /// Checks and shows disclaimer if needed (called when view appears)
    func checkAndShowDisclaimerIfNeeded() {
        // Only show if not yet accepted for this session and not already showing
        if !hasAcceptedDisclaimerForSession && isDisclaimerPending && !showingDisclaimerSheet {
            // Use a small delay to ensure view is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self else { return }
                // Double-check we still need to show it and it's not already showing
                if !self.hasAcceptedDisclaimerForSession && self.isDisclaimerPending && !self.showingDisclaimerSheet {
                    self.showingDisclaimerSheet = true
                    self.isDisclaimerPending = false // Mark as no longer pending
                }
            }
        }
    }
} 