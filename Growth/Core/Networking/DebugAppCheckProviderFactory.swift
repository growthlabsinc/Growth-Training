import Foundation
import FirebaseAppCheck
import FirebaseCore

/// Custom Debug App Check Provider Factory that ensures token generation
class CustomDebugAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        let provider = AppCheckDebugProvider(app: app)
        
        // Force generation of debug token if it doesn't exist
        if UserDefaults.standard.string(forKey: "FIRAAppCheckDebugToken") == nil {
            let debugToken = UUID().uuidString
            UserDefaults.standard.set(debugToken, forKey: "FIRAAppCheckDebugToken")
            UserDefaults.standard.synchronize()
            
            Logger.debug("\n========================================")
            Logger.debug("🆕 Generated NEW App Check Debug Token:")
            Logger.debug(debugToken)
            Logger.debug("========================================")
            Logger.debug("⚠️  IMPORTANT: Add this token to Firebase Console NOW:")
            Logger.debug("1. Go to: https://console.firebase.google.com/project/growth-70a85/appcheck/apps")
            Logger.debug("2. Click on your iOS app") 
            Logger.debug("3. Click 'Manage debug tokens'")
            Logger.debug("4. Add token: \(debugToken)")
            Logger.debug("5. Give it a name like 'Dev Device - \(Date())'")
            Logger.debug("========================================\n")
        }
        
        return provider
    }
}