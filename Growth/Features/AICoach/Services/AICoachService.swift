//
//  AICoachService.swift
//  Growth
//
//  Created by Developer on 7/15/25.
//

import Foundation
import Firebase
import FirebaseFunctions
import FirebaseAppCheck
import FirebaseFirestore
import FirebaseAuth
import OSLog

// Note: The following types are defined in other files in the project:
// - PromptTemplateService: Growth/Features/AICoach/Services/PromptTemplateService.swift
// - ChatMessage: Growth/Features/AICoach/Models/ChatMessage.swift
// - KnowledgeSource: Growth/Features/AICoach/Models/ChatMessage.swift
// - FeatureAccess: Growth/Core/Models/FeatureAccess.swift
// - FeatureType: Growth/Core/Models/SubscriptionTier.swift
// If you get "Cannot find type" errors, ensure these files are included in the build target

/// Error types for AI Coach service
enum AICoachError: Error, LocalizedError {
    case invalidResponse
    case networkError(String)
    case serviceUnavailable
    case rateLimitExceeded
    case functionNotFound
    case authenticationRequired
    
    // Feature gating errors
    case premiumRequired
    case trialExpired
    case usageLimitExceeded(remaining: Int, resetDate: Date?)
    case featureUnavailable
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The AI Coach provided an invalid response. Please try again."
        case .networkError(let message):
            return "Network error: \(message)"
        case .serviceUnavailable:
            return "The AI Coach service is currently unavailable. Please try again later."
        case .rateLimitExceeded:
            return "You've reached the limit for AI Coach questions. Please try again later."
        case .functionNotFound:
            return "AI Coach service is not properly configured. Please contact support."
        case .authenticationRequired:
            return "Please sign in to use the AI Coach feature."
        case .premiumRequired:
            return "AI Coach is a premium feature. Upgrade to access unlimited coaching."
        case .trialExpired:
            return "Your trial has expired. Upgrade to continue using AI Coach."
        case .usageLimitExceeded(let remaining, let resetDate):
            if let resetDate = resetDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                formatter.timeStyle = .short
                return "You've reached your AI Coach limit. \(remaining) questions remaining. Resets \(formatter.string(from: resetDate))."
            } else {
                return "You've reached your AI Coach limit for today."
            }
        case .featureUnavailable:
            return "This feature is currently unavailable."
        }
    }
}

// Logger for debugging - using print for simplicity
// private let logger = Logger()

/// Service responsible for interacting with AI Coach backend
class AICoachService {
    /// Shared instance for singleton access
    static let shared = AICoachService()
    
    /// Firebase Functions instance
    private var functions: Functions
    private let promptTemplateService: PromptTemplateService
    
    /// Flag indicating if the service is in test mode
    private let isTestMode: Bool
    
    /// URL session for network requests
    private let urlSession: URLSession
    
    /// Initialize the service
    /// - Parameters:
    ///   - functions: Firebase Functions instance (defaults to standard instance)
    ///   - promptTemplateService: Service for managing prompt templates (defaults to new instance)
    ///   - isTestMode: Whether to use test mode (default: false)
    ///   - urlSession: URL session for network requests (defaults to shared session)
    init(
        functions: Functions = Functions.functions(region: "us-central1"),
        promptTemplateService: PromptTemplateService = PromptTemplateService(),
        isTestMode: Bool = false,
        urlSession: URLSession = .shared
    ) {
        self.functions = functions
        self.promptTemplateService = promptTemplateService
        self.isTestMode = isTestMode
        self.urlSession = urlSession
        
        // Note: Emulator disabled - using deployed Firebase Functions
        // Uncomment the lines below to use local emulator for testing:
        // #if DEBUG
        // functions.useEmulator(withHost: "localhost", port: 5002)
        // #endif
        
        // Note: Firebase Functions doesn't have a global timeoutInterval property
        // Timeouts are set on individual function calls
    }
    
    /// Enables Firestore network connectivity
    /// - Returns: A boolean indicating success and an optional error message
    func enableNetwork() async -> (Bool, String?) {
        return await withCheckedContinuation { continuation in
            Firestore.firestore().enableNetwork { error in
                if let error = error {
                    Logger.error("Failed to enable Firestore network: \(error.localizedDescription)", logger: AppLoggers.network)
                    continuation.resume(returning: (false, error.localizedDescription))
                } else {
                    Logger.info("Firestore network enabled", logger: AppLoggers.network)
                    continuation.resume(returning: (true, nil))
                }
            }
        }
    }
    
    /// Disables Firestore network connectivity
    /// - Returns: A boolean indicating success and an optional error message
    func disableNetwork() async -> (Bool, String?) {
        return await withCheckedContinuation { continuation in
            Firestore.firestore().disableNetwork { error in
                if let error = error {
                    Logger.error("Failed to disable Firestore network: \(error.localizedDescription)", logger: AppLoggers.network)
                    continuation.resume(returning: (false, error.localizedDescription))
                } else {
                    Logger.info("Firestore network disabled", logger: AppLoggers.network)
                    continuation.resume(returning: (true, nil))
                }
            }
        }
    }
    
    
    /// Send a message to the AI Coach and receive a response
    /// - Parameters:
    ///   - message: User message to send
    ///   - conversationHistory: Previous messages in the conversation
    /// - Returns: AI response message
    func sendMessage(
        _ message: String, 
        conversationHistory: [ChatMessage] = [],
        entitlementProvider: EntitlementProvider
    ) async throws -> ChatMessage {
        // Feature gating check - AI Coach requires premium or limited free usage
        let access = FeatureAccess.from(feature: "aiCoach", using: entitlementProvider)
        
        switch access {
        case .granted:
            // Full access - proceed normally
            break
            
        case .limited(let usage):
            // Limited access - check if user can consume usage
            // Usage consumption tracking removed - implement if needed
            let canConsume = false // Usage limits not implemented in simplified version
            if !canConsume {
                throw AICoachError.usageLimitExceeded(remaining: usage.remaining, resetDate: usage.resetDate)
            }
            
        case .denied(let reason):
            // Access denied - throw appropriate error
            switch reason {
            case .noSubscription:
                throw AICoachError.premiumRequired
            case .trialExpired:
                throw AICoachError.trialExpired
            case .usageLimitReached:
                throw AICoachError.usageLimitExceeded(remaining: 0, resetDate: nil)
            default:
                throw AICoachError.featureUnavailable
            }
        }
        
        if isTestMode {
            // In test mode, return a mock response after a delay
            try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            return mockAIResponse(for: message)
        }
        
        // Check if user is authenticated
        guard let currentUser = Auth.auth().currentUser else {
            Logger.info("No authenticated user found - authentication required for AI Coach", logger: AppLoggers.auth)
            throw AICoachError.authenticationRequired
        }
        
        // User is authenticated, proceed
        if currentUser.isAnonymous {
            Logger.info("Anonymous user detected - this is not allowed for AI Coach", logger: AppLoggers.auth)
            throw AICoachError.authenticationRequired
        } else {
            Logger.info("User already authenticated with uid: \(currentUser.uid)", logger: AppLoggers.auth)
            Logger.debug("Is user anonymous: \(currentUser.isAnonymous)", logger: AppLoggers.auth)
            
            // Get fresh ID token to ensure authentication is valid
            do {
                _ = try await currentUser.getIDToken()
                Logger.info("Successfully retrieved fresh ID token", logger: AppLoggers.auth)
                
                // Get App Check token if available (but don't let it block the request)
                Task {
                    do {
                        let appCheckToken = try await AppCheck.appCheck().token(forcingRefresh: false)
                        Logger.debug("App Check token retrieved: \(appCheckToken.token.prefix(10))...", logger: AppLoggers.auth)
                    } catch {
                        Logger.error("Failed to get App Check token: \(error.localizedDescription)", logger: AppLoggers.auth)
                        // This is expected in development - App Check is optional
                    }
                }
            } catch {
                Logger.error("Failed to get ID token: \(error.localizedDescription)", logger: AppLoggers.auth)
                // Try to refresh the user
                do {
                    try await currentUser.reload()
                    Logger.debug("User reloaded successfully", logger: AppLoggers.auth)
                } catch {
                    Logger.error("Failed to reload user: \(error.localizedDescription)", logger: AppLoggers.auth)
                }
            }
        }
        
        // Attempt to enable network if it might be disabled
        let (networkEnabled, networkError) = await enableNetwork()
        if !networkEnabled {
            Logger.warning("Could not enable network: \(networkError ?? "Unknown error")", logger: AppLoggers.network)
            // Continue anyway - the call might still work
        }
        
        // Categorize the query
        let queryCategory = promptTemplateService.categorizeQuery(message)
        
        // Build the full prompt using the template service
        _ = promptTemplateService.getSystemPrompt(for: queryCategory)
        
        // The request data for the Firebase function
        var requestData: [String: Any] = [
            "query": message
        ]
        
        // Add conversation history if provided
        if !conversationHistory.isEmpty {
            // Convert chat messages to a format the function expects
            let historyData = conversationHistory.map { msg in
                return [
                    "text": msg.text,
                    "sender": msg.sender.rawValue,
                    "timestamp": ISO8601DateFormatter().string(from: msg.timestamp)
                ]
            }
            requestData["conversationHistory"] = historyData
        }
        
        // Maximum number of retries for transient errors
        let maxRetries = 2
        var currentRetry = 0
        
        while true {
            do {
                // For debugging - log the function we're calling
                Logger.info("Calling Firebase function \"generateAIResponse\" (attempt \(currentRetry + 1)/\(maxRetries + 1))", logger: AppLoggers.aiCoach)
                
                // Print request data for debugging - detailed format
                Logger.debug("Request data structure:", logger: AppLoggers.aiCoach)
                if let jsonData = try? JSONSerialization.data(withJSONObject: requestData, options: .prettyPrinted),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    Logger.debug("\(jsonString)", logger: AppLoggers.aiCoach)
                } else {
                    Logger.warning("Cannot serialize request data: \(requestData)", logger: AppLoggers.aiCoach)
                }
                
                // Call Firebase Function with timeout
                let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HTTPSCallableResult, Error>) in
                    let callable = functions.httpsCallable("generateAIResponse")
                    
                    // Set a timeout for the function call
                    callable.timeoutInterval = 30.0 // Increase timeout to 30 seconds
                    
                    Logger.debug("Calling function with \(callable.timeoutInterval) second timeout", logger: AppLoggers.aiCoach)
                    Logger.debug("Current auth user: \(Auth.auth().currentUser?.uid ?? "nil")", logger: AppLoggers.auth)
                    Logger.debug("Is user anonymous: \(Auth.auth().currentUser?.isAnonymous ?? false)", logger: AppLoggers.auth)
                    
                    // Note: Using deployed Firebase Functions (emulator disabled)
                    #if DEBUG
                    Logger.debug("Note: Using deployed Firebase Functions", logger: AppLoggers.aiCoach)
                    #endif
                    
                    callable.call(requestData) { result, error in
                        if let error = error {
                            Logger.error("Firebase function error: \(error.localizedDescription)", logger: AppLoggers.aiCoach)
                            
                            // Additional error details if available
                            let nsError = error as NSError
                            Logger.error("Error domain: \(nsError.domain), code: \(nsError.code)", logger: AppLoggers.aiCoach)
                            Logger.error("Error userInfo: \(nsError.userInfo)", logger: AppLoggers.aiCoach)
                            
                            // Check if it's an authentication error
                            if nsError.domain == "com.firebase.functions" && nsError.code == 16 {
                                Logger.error("UNAUTHENTICATED error detected - user needs to be properly authenticated", logger: AppLoggers.auth)
                            }
                            
                            continuation.resume(throwing: error)
                        } else if let result = result {
                            Logger.info("Firebase function call successful, received result", logger: AppLoggers.aiCoach)
                            continuation.resume(returning: result)
                        } else {
                            Logger.error("Firebase function returned no result and no error", logger: AppLoggers.aiCoach)
                            continuation.resume(throwing: AICoachError.invalidResponse)
                        }
                    }
                }
                
                // Parse response data
                guard let responseData = result.data as? [String: Any] else {
                    Logger.warning("Invalid response format: data is not a dictionary", logger: AppLoggers.aiCoach)
                    throw AICoachError.invalidResponse
                }
                
                // Debug - print the response structure
                Logger.debug("Response data keys: \(responseData.keys.joined(separator: ", "))", logger: AppLoggers.aiCoach)
                
                guard let responseText = responseData["text"] as? String else {
                    Logger.warning("Response missing \"text\" field or invalid type", logger: AppLoggers.aiCoach)
                    throw AICoachError.invalidResponse
                }
                
                // Extract sources if available
                var knowledgeSources: [KnowledgeSource]? = nil
                if let sourcesData = responseData["sources"] as? [[String: Any]] {
                    knowledgeSources = sourcesData.compactMap { sourceData in
                        guard let title = sourceData["title"] as? String,
                              let snippet = sourceData["snippet"] as? String,
                              let confidence = sourceData["confidence"] as? Double else {
                            return nil as KnowledgeSource?
                        }
                        
                        return KnowledgeSource(
                            title: title,
                            snippet: snippet,
                            confidence: confidence
                        )
                    }
                }
                
                // Create and return AI message
                return ChatMessage.aiMessage(responseText, sources: knowledgeSources)
                
            } catch {
                Logger.error("AI Coach Error: \(error)", logger: AppLoggers.aiCoach)
                
                // Get detailed error information for debugging
                let nsError = error as NSError
                Logger.error("Error domain: \(nsError.domain), code: \(nsError.code)", logger: AppLoggers.aiCoach)
                Logger.error("Error userInfo: \(nsError.userInfo)", logger: AppLoggers.aiCoach)
                
                // Handle UNAUTHENTICATED errors
                if nsError.domain == "com.firebase.functions" && nsError.code == 16 {
                    Logger.error("UNAUTHENTICATED error - user is not properly authenticated", logger: AppLoggers.auth)
                    
                    // Return authentication required error
                    throw AICoachError.authenticationRequired
                }
                
                // Handle "NOT FOUND" errors which might be related to Firebase Functions configuration
                if nsError.localizedDescription.contains("NOT FOUND") || 
                   (nsError.domain == "com.firebase.functions" && nsError.code == 404) {
                    Logger.warning("Firebase function not found - this may indicate that the Cloud Function is not deployed or the region is incorrect", logger: AppLoggers.aiCoach)
                    
                    // If we haven't reached max retries, try again after reset
                    if currentRetry < maxRetries {
                        currentRetry += 1
                        Logger.info("Attempting to reset Firestore connection and retry (\(currentRetry)/\(maxRetries))", logger: AppLoggers.network)
                        
                        // Reset network connection
                        _ = await disableNetwork()
                        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
                        _ = await enableNetwork()
                        
                        // Also reset the Functions instance which might help with NOT FOUND errors
                        // On first retry try with current region, on subsequent retries try alternative region
                        resetCloudFunctionsInstance(tryAlternativeRegion: currentRetry > 1)
                        
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
                        
                        continue // Try again
                    }
                    
                    throw AICoachError.functionNotFound
                }
                
                // Handle network-specific errors
                if nsError.domain == NSURLErrorDomain {
                    let shouldRetry = [
                        NSURLErrorNotConnectedToInternet,
                        NSURLErrorNetworkConnectionLost,
                        NSURLErrorTimedOut,
                        NSURLErrorCannotConnectToHost,
                        NSURLErrorCannotFindHost,
                        NSURLErrorDNSLookupFailed,
                        NSURLErrorCannotParseResponse // -1017 error
                    ].contains(nsError.code)
                    
                    if shouldRetry && currentRetry < maxRetries {
                        currentRetry += 1
                        Logger.warning("Network error, attempting retry (\(currentRetry)/\(maxRetries))", logger: AppLoggers.network)
                        
                        // Reset network connection
                        _ = await disableNetwork()
                        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
                        _ = await enableNetwork()
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
                        
                        continue // Try again
                    }
                    
                    throw AICoachError.networkError("Connection issue. Please check your internet and try again.")
                }
                
                // Pass through specific AI Coach errors
                if let aiError = error as? AICoachError {
                    throw aiError
                } else {
                    // Wrap other errors
                    throw AICoachError.networkError(error.localizedDescription)
                }
            }
        }
    }
    
    /// Generate a mock AI response for testing
    /// - Parameter message: User message to respond to
    /// - Returns: Mock AI response
    private func mockAIResponse(for message: String) -> ChatMessage {
        let lowerMessage = message.lowercased()
        
        // Generate different responses based on message content for testing
        if lowerMessage.contains("hello") || lowerMessage.contains("hi") {
            return ChatMessage.aiMessage("Hello! I'm your Growth Coach. How can I help you today?")
        } else if lowerMessage.contains("method") || lowerMessage.contains("exercise") {
            return ChatMessage.aiMessage(
                "Growth Methods are specialized exercises designed to improve circulation. They range from beginner to advanced levels. Would you like to learn about a specific method?",
                sources: [
                    KnowledgeSource(
                        title: "Growth Methods Introduction",
                        snippet: "Growth Methods are specialized exercises designed to improve circulation...",
                        confidence: 0.92
                    )
                ]
            )
        } else if lowerMessage.contains("help") {
            return ChatMessage.aiMessage("I can help you with questions about Growth Methods, techniques, and navigating the app. What would you like to know more about?")
        } else {
            return ChatMessage.aiMessage("I understand you're asking about \"\(message)\". Could you provide more details about what you'd like to know?")
        }
    }
    
    /// Reset the Firebase Cloud Functions instance
    /// - Parameter tryAlternativeRegion: Whether to try an alternative region if the current one fails
    func resetCloudFunctionsInstance(tryAlternativeRegion: Bool = false) {
        Logger.info("Attempting to reset Firebase Functions instance", logger: AppLoggers.aiCoach)
        
        if tryAlternativeRegion {
            // Try us-central1 region, which is the default for most Firebase projects
            // Temporarily commented out - FirebaseClient not in scope
            // if firebaseClient.resetCloudFunctions(region: "us-central1") {
            // Update our functions reference with the fresh instance explicitly specifying region
            self.functions = Functions.functions(region: "us-central1")
            Logger.info("Functions instance reset successfully with region us-central1", logger: AppLoggers.aiCoach)
            // } else {
            //     print("[ERROR] Failed to reset Functions instance with alternative region")
            // }
        } else {
            // Reset with default region (no region specified)
            // Temporarily commented out - FirebaseClient not in scope
            // if firebaseClient.resetCloudFunctions() {
            // Update our functions reference with the fresh instance
            self.functions = Functions.functions()
            Logger.info("Functions instance reset successfully with default region", logger: AppLoggers.aiCoach)
            // } else {
            //     print("[ERROR] Failed to reset Functions instance")
            // }
        }
    }
}

