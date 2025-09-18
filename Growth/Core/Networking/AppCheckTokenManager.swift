//
//  AppCheckTokenManager.swift
//  Growth
//
//  Helper to manage AppCheck debug tokens and clear cache
//

import Foundation
import FirebaseAppCheck

class AppCheckTokenManager {
    static let shared = AppCheckTokenManager()
    
    private let tokenKeys = [
        "FIRAAppCheckDebugToken",
        "FIRAppCheckDebugToken", 
        "AppCheckDebugToken"
    ]
    
    private init() {}
    
    /// Clear all cached AppCheck tokens and force regeneration
    func clearTokenCache() {
        Logger.debug("🧹 Clearing AppCheck token cache...")
        
        // Clear all possible token keys from UserDefaults
        for key in tokenKeys {
            if UserDefaults.standard.string(forKey: key) != nil {
                Logger.debug("   Removing token from UserDefaults[\(key)]")
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
        
        // Synchronize to ensure changes are saved
        UserDefaults.standard.synchronize()
        
        Logger.debug("✅ AppCheck token cache cleared")
    }
    
    /// Force regenerate AppCheck debug token
    func regenerateToken(completion: @escaping (String?) -> Void) {
        Logger.debug("🔄 Regenerating AppCheck debug token...")
        
        // Clear cache first
        clearTokenCache()
        
        // Force refresh token
        AppCheck.appCheck().token(forcingRefresh: true) { token, error in
            if let error = error {
                Logger.error("❌ Failed to regenerate token: \(error.localizedDescription)")
                
                // Check for specific errors
                if error.localizedDescription.contains("403") {
                    Logger.debug("\n🔧 403 Error Solutions:")
                    Logger.debug("1. Token not registered in Firebase Console")
                    Logger.debug("2. Token registered for wrong bundle ID")
                    Logger.debug("3. Token expired or invalid")
                    Logger.debug("4. AppCheck not properly configured")
                }
                
                completion(nil)
                return
            }
            
            if let token = token {
                Logger.debug("✅ New token generated: \(token.token)")
                Logger.debug("📋 Register this token in Firebase Console:")
                Logger.debug("   Project: growth-70a85")
                Logger.debug("   Bundle ID: com.growthlabs.growthmethod")
                Logger.debug("   Token: \(token.token)")
                
                completion(token.token)
            } else {
                Logger.error("❌ No token returned")
                completion(nil)
            }
        }
    }
    
    /// Get current token status and info
    func getTokenStatus() {
        Logger.debug("🔍 AppCheck Token Status:")
        Logger.debug("========================")
        
        // Check UserDefaults
        for key in tokenKeys {
            if let value = UserDefaults.standard.string(forKey: key) {
                Logger.debug("✅ UserDefaults[\(key)]: \(value)")
            } else {
                Logger.debug("❌ UserDefaults[\(key)]: nil")
            }
        }
        
        // Check environment
        let env = ProcessInfo.processInfo.environment
        for key in tokenKeys {
            if let value = env[key] {
                Logger.debug("✅ Environment[\(key)]: \(value)")
            }
        }
        
        // Get current token
        AppCheck.appCheck().token(forcingRefresh: false) { token, error in
            if let error = error {
                Logger.debug("❌ Current token error: \(error.localizedDescription)")
            } else if let token = token {
                Logger.debug("✅ Current token: \(token.token)")
                Logger.debug("⏰ Expires: \(token.expirationDate)")
            }
        }
    }
}