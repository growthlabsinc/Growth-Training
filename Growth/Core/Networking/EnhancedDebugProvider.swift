//
//  EnhancedDebugProvider.swift
//  Growth
//
//  Enhanced App Check Debug Provider with better error handling and token management
//

import Foundation
import FirebaseAppCheck
import FirebaseCore

/// Enhanced debug provider that handles token generation and exchange more reliably
class EnhancedDebugAppCheckProvider: NSObject, AppCheckProvider {
    private let app: FirebaseApp
    private let tokenKey = "FIRAAppCheckDebugToken"
    
    init(app: FirebaseApp) {
        self.app = app
        super.init()
    }
    
    func getToken(completion handler: @escaping (AppCheckToken?, Error?) -> Void) {
        // Get or generate debug token
        let debugToken = getOrGenerateDebugToken()
        
        // Log token for debugging
        // Logger.debug("🔐 EnhancedDebugProvider: Using debug token: \(debugToken)")
        
        // Create a mock App Check token for debug purposes
        // In debug mode, we don't actually exchange with Firebase servers
        let token = AppCheckToken(
            token: debugToken,
            expirationDate: Date().addingTimeInterval(3600) // 1 hour expiration
        )
        
        handler(token, nil)
    }
    
    private func getOrGenerateDebugToken() -> String {
        // Check for existing token
        if let existingToken = UserDefaults.standard.string(forKey: tokenKey) {
            // Logger.debug("✅ Using existing debug token from UserDefaults")
            return existingToken
        }
        
        // Generate new token
        let newToken = UUID().uuidString
        UserDefaults.standard.set(newToken, forKey: tokenKey)
        UserDefaults.standard.synchronize()
        
        // Only log critical info for new token generation
        Logger.info("🆕 Generated NEW App Check Debug Token: \(newToken)")
        Logger.info("⚠️ Register at: https://console.firebase.google.com/project/growth-70a85/appcheck/apps")
        
        return newToken
    }
}

/// Enhanced debug provider factory with comprehensive logging
class EnhancedDebugAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        // Logger.debug("🏭 EnhancedDebugProviderFactory: Creating enhanced debug provider for app: \(app.name)")
        
        // First try the standard debug provider
        let standardProvider = AppCheckDebugProvider(app: app)
        
        // Check if we have a token
        if UserDefaults.standard.string(forKey: "FIRAAppCheckDebugToken") != nil {
            // Logger.debug("✅ Debug token found")
            // Logger.debug("📋 Make sure this token is registered in Firebase Console")
            
            // Return standard provider if token exists
            return standardProvider
        } else {
            // Logger.debug("⚠️ No debug token found, using enhanced provider")
            // Return enhanced provider for better token handling
            return EnhancedDebugAppCheckProvider(app: app)
        }
    }
}

/// Helper to validate App Check configuration
extension AppCheck {
    /// Validate that App Check is properly configured
    static func validateConfiguration(completion: @escaping (Bool, String?) -> Void) {
        // Logger.debug("🔍 Validating App Check configuration...")
        
        // Try to get a token
        AppCheck.appCheck().token(forcingRefresh: false) { token, error in
            if let error = error {
                let errorMessage = "❌ App Check validation failed: \(error.localizedDescription)"
                Logger.error(errorMessage)
                
                // Check for specific error types
                if error.localizedDescription.contains("403") {
                    Logger.error("⚠️ 403 Error: Debug token not registered in Firebase Console")
                    // if let debugToken = UserDefaults.standard.string(forKey: "FIRAAppCheckDebugToken") {
                    //     Logger.debug("Token to register: \(debugToken)")
                    // }
                }
                
                completion(false, errorMessage)
                return
            }
            
            if token != nil {
                Logger.info("✅ App Check validation successful")
                // Logger.debug("   Token prefix: \(String(token.token.prefix(20)))...")
                // Logger.debug("   Expires: \(token.expirationDate)")
                completion(true, nil)
            } else {
                completion(false, "No token returned")
            }
        }
    }
}