//
//  FirebaseClient.swift
//  Growth
//
//  Created by Developer on 5/8/25.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseAnalytics
import FirebaseCrashlytics
import FirebaseFunctions
import FirebaseRemoteConfig
import FirebaseInAppMessaging
import FirebaseAppCheck
import Reachability

/// Environment configuration for Firebase
enum FirebaseEnvironment: String {
    case development = "dev"
    case staging = "staging"
    case production = "prod"
    
    var configFileName: String {
        switch self {
        case .development:
            return "dev.GoogleService-Info"
        case .staging:
            return "staging.GoogleService-Info"
        case .production:
            return "GoogleService-Info"
        }
    }
    
    /// Convenience properties for checking environment
    var isDevelopment: Bool {
        return self == .development
    }
    
    var isStaging: Bool {
        return self == .staging
    }
    
    var isProduction: Bool {
        return self == .production
    }
}

/// Firebase client handling initialization and management
class FirebaseClient {
    static let shared = FirebaseClient()
    
    private var environment: FirebaseEnvironment = .development
    private var reachability: Reachability?
    private var isInitialized: Bool = false
    private var retryCount: Int = 0
    private let maxRetries: Int = 3
    
    private init() {
        setupReachability()
    }
    
    /// Set up network reachability monitoring
    private func setupReachability() {
        do {
            reachability = try Reachability()
            try reachability?.startNotifier()
        } catch {
            Logger.error("Error setting up reachability: \(error)")
        }
    }
    
    /// Configure Firebase for the specified environment
    /// - Parameter environment: The environment to use
    /// - Returns: True if configuration was successful
    @discardableResult
    func configure(for environment: FirebaseEnvironment) -> Bool {
        // Prevent duplicate configuration that causes 'Default app has already been configured.'
        // If a default FirebaseApp already exists, simply mark the client as initialized and return.
        if isInitialized || FirebaseApp.app() != nil {
            Logger.debug("Firebase is already initialized – skipping duplicate configuration call.")
            isInitialized = true
            // Still configure App Check if not already done
            configureAppCheck()
            return true
        }
        
        self.environment = environment
        
        let filename = environment.configFileName
        
        guard let filePath = Bundle.main.path(forResource: filename, ofType: "plist") else {
            Logger.error("Failed to find \(filename).plist")
            return false
        }
        
        do {
            // Load options from the plist file
            guard let options = FirebaseOptions(contentsOfFile: filePath) else {
                Logger.error("Failed to initialize FirebaseOptions from \(filePath)")
                throw NSError(domain: "FirebaseClientErrorDomain", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Failed to initialize FirebaseOptions"])
            }
            
            // Log configuration for debugging
            // Commented out verbose Firebase configuration logging
            // Logger.debug("Configuring Firebase with options from: \(filename)")
            // Logger.debug("Bundle ID: \(options.bundleID)")
            
            // Configure App Check BEFORE Firebase.configure()
            // This is critical - the provider factory must be set before Firebase initialization
            configureAppCheck()
            
            // Initialize Firebase with the appropriate options
            FirebaseApp.configure(options: options)
            // Logger.debug("Firebase configured for environment: \(environment.rawValue)")
            
            // Additional Firebase service initializations
            Analytics.setAnalyticsCollectionEnabled(true)
            Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
            
            // Initialize Firebase In-App Messaging
            // Note: isAutomaticDataCollectionEnabled is not available, enable data collection differently
            InAppMessaging.inAppMessaging().automaticDataCollectionEnabled = true
            // Logger.debug("Firebase In-App Messaging configured")
            
            // Configure Firestore logging settings (after Firebase is initialized)
            let firestoreSettings = FirestoreSettings()
            firestoreSettings.isSSLEnabled = true
            Firestore.firestore().settings = firestoreSettings
            
            isInitialized = true
            return true
        } catch {
            Logger.error("Error configuring Firebase: \(error)")
            return false
        }
    }
    
    /// Configure Firebase App Check
    private func configureAppCheck() {
        // IMPORTANT: This must be called BEFORE FirebaseApp.configure()
        
        #if targetEnvironment(simulator)
        // Use enhanced debug provider in simulator for better error handling
        let providerFactory = EnhancedDebugAppCheckProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        // Logger.debug("🔐 Firebase App Check configured with ENHANCED DEBUG provider (Simulator)")
        
        // Check if we have -FIRDebugEnabled flag
        let hasDebugFlag = ProcessInfo.processInfo.arguments.contains("-FIRDebugEnabled")
        if !hasDebugFlag {
            Logger.warning("\n⚠️  WARNING: -FIRDebugEnabled flag not set!")
            Logger.debug("To enable App Check debug logging:")
            Logger.debug("1. In Xcode: Product → Scheme → Edit Scheme")
            Logger.debug("2. Select Run → Arguments")
            Logger.debug("3. Add -FIRDebugEnabled to Arguments Passed On Launch")
            Logger.debug("4. Run the app again to see your debug token\n")
        }
        
        // Print the debug token immediately for simulator
        if let debugToken = getStoredDebugToken() {
            Logger.debug("\n========================================")
            Logger.debug("🔑 App Check Debug Token (from storage):")
            Logger.debug(debugToken)
            Logger.debug("========================================")
            Logger.debug("⚠️  Add this token to Firebase Console:")
            Logger.debug("1. Go to: https://console.firebase.google.com/project/growth-70a85/appcheck/apps")
            Logger.debug("2. Click on your iOS app")
            Logger.debug("3. Click 'Manage debug tokens'")
            Logger.debug("4. Add this token with a descriptive name")
            Logger.debug("========================================\n")
        } else if !hasDebugFlag {
            Logger.debug("❌ No debug token found. Add -FIRDebugEnabled flag to see it.")
        }
        #elseif DEBUG
        // Use enhanced debug provider for development builds on real devices
        let providerFactory = EnhancedDebugAppCheckProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        // Logger.debug("🔐 Firebase App Check configured with ENHANCED DEBUG provider (Debug build)")
        #else
        // Use App Attest provider for production (iOS 14+) with Device Check fallback
        let providerFactory = AppAttestAppCheckFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        Logger.debug("🔐 Firebase App Check configured with APP ATTEST provider (Production)")
        #endif
        
        // Schedule token retrieval and validation after Firebase is initialized
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.retrieveAppCheckToken()
            
            // Also validate configuration
            AppCheck.validateConfiguration { success, error in
                if !success {
                    Logger.error("⚠️ App Check validation failed: \(error ?? "Unknown error")")
                }
            }
        }
    }
    
    /// Get stored debug token from UserDefaults
    private func getStoredDebugToken() -> String? {
        #if DEBUG || targetEnvironment(simulator)
        // The debug token is stored by the AppCheckDebugProvider
        return UserDefaults.standard.string(forKey: "FIRAAppCheckDebugToken")
        #else
        return nil
        #endif
    }
    
    /// Clear AppCheck token cache and regenerate
    func clearAppCheckTokenCache() {
        #if DEBUG || targetEnvironment(simulator)
        Logger.debug("🧹 Clearing AppCheck token cache...")
        
        let tokenKeys = ["FIRAAppCheckDebugToken", "FIRAppCheckDebugToken", "AppCheckDebugToken"]
        for key in tokenKeys {
            if UserDefaults.standard.string(forKey: key) != nil {
                Logger.debug("   Removing token from UserDefaults[\(key)]")
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
        UserDefaults.standard.synchronize()
        
        // Force regenerate token
        AppCheck.appCheck().token(forcingRefresh: true) { token, error in
            if let error = error {
                Logger.error("❌ Failed to regenerate token: \(error.localizedDescription)")
            } else if let token = token {
                Logger.debug("✅ New token generated: \(token.token)")
                Logger.debug("📋 Register this NEW token in Firebase Console:")
                Logger.debug("   https://console.firebase.google.com/project/growth-70a85/appcheck/apps")
            }
        }
        #endif
    }
    
    /// Retrieve and log App Check token (called after Firebase initialization)
    private func retrieveAppCheckToken() {
        #if DEBUG || targetEnvironment(simulator)
        // First check if we have a stored debug token
        if let storedToken = UserDefaults.standard.string(forKey: "FIRAAppCheckDebugToken") {
            Logger.debug("\n✅ Using App Check Debug Token: \(storedToken)")
            Logger.debug("   This token should be registered in Firebase Console")
        }
        
        // Try to get App Check token
        AppCheck.appCheck().token(forcingRefresh: false) { token, error in
            if let error = error {
                Logger.error("❌ App Check token error: \(error.localizedDescription)")
                Logger.error("❌ Failed to retrieve App Check token")
                Logger.debug("   This may cause issues with Firebase Functions")
                
                // If we get a 403, the token might not be registered
                if error.localizedDescription.contains("403") {
                    Logger.debug("\n⚠️  SOLUTION: The debug token needs to be registered in Firebase Console")
                    if let debugToken = UserDefaults.standard.string(forKey: "FIRAAppCheckDebugToken") {
                        Logger.debug("   Token to register: \(debugToken)")
                    }
                    Logger.debug("   1. Go to: https://console.firebase.google.com/project/growth-70a85/appcheck/apps")
                    Logger.debug("   2. Click on your iOS app")
                    Logger.debug("   3. Click 'Manage debug tokens'")
                    Logger.debug("   4. Add the token above\n")
                }
                return
            }
            if let token = token {
                Logger.info("✅ App Check token retrieved successfully")
                Logger.debug("   Token: \(token.token.prefix(20))...")
            }
        }
        
        #else
        // For production, just enable auto-refresh
        AppCheck.appCheck().isTokenAutoRefreshEnabled = true
        Logger.debug("✅ App Check token auto-refresh enabled")
        #endif
    }
    
    /// Force reconfigure Firebase (used when connection issues occur)
    /// - Returns: True if reconfiguration was successful
    func forceReconfigure(for environment: FirebaseEnvironment) -> Bool {
        isInitialized = false
        Logger.debug("Force reconfiguring Firebase for environment: \(environment.rawValue)")
        return configure(for: environment)
    }
    
    /// Get the currently configured environment
    var currentEnvironment: FirebaseEnvironment {
        return environment
    }
    
    /// Reset cloud functions instance - may be needed when getting NOT FOUND errors
    /// - Parameter region: Optional region to use (defaults to "us-central1")
    /// - Returns: True if successfully reset
    func resetCloudFunctions(region: String? = nil) -> Bool {
        if !isInitialized {
            Logger.debug("Firebase not initialized, cannot reset Functions")
            return false
        }
        
        // Check we have a valid app instance
        guard let app = FirebaseApp.app() else {
            Logger.debug("No valid Firebase app found")
            return false
        }
        
        Logger.debug("Resetting Firebase Cloud Functions")
        
        // Use provided region or default to us-central1 (Firebase default region)
        let targetRegion = region ?? "us-central1"
        
        Logger.debug("Setting up Functions with region: \(targetRegion)")
        
        // Create a fresh instance with the specified region
        _ = Functions.functions(app: app, region: targetRegion)
        
        // Note: Timeouts should be set on individual HTTPSCallable objects, not the Functions instance
        Logger.debug("New Functions instance created")
        
        // Enable local debugging if in development mode
        #if DEBUG
        // Uncomment this line to use local emulator for testing
        // newFunctions.useEmulator(withHost: "localhost", port: 5002)
        #endif
        
        return true
    }
    
    /// Test connection to Firebase services
    /// - Parameter completion: Callback with result (success, errorMessage)
    func testConnection(completion: @escaping (Bool, String?) -> Void) {
        guard isInitialized else {
            completion(false, "Firebase not initialized")
            return
        }
        
        // First check if we have network connectivity
        if let reachability = reachability {
            if reachability.connection == .unavailable {
                completion(false, "Internet connection unavailable")
                return
            }
        }
        
        // Test Firestore connection
        let db = Firestore.firestore()
        let testCollection = db.collection("connection_test")
        
        // Create test timestamp with user info if available
        var testData: [String: Any] = [
            "timestamp": FieldValue.serverTimestamp(),
            "test_id": UUID().uuidString
        ]
        
        // Add user ID if authenticated
        if let userId = Auth.auth().currentUser?.uid {
            testData["userId"] = userId
        }
        
        // Try to write to Firestore
        testCollection.addDocument(data: testData) { error in
            if let error = error {
                Logger.error("Firestore connection test failed: \(error.localizedDescription)")
                // Don't fail the connection test for permission errors if no user is authenticated
                if error.localizedDescription.contains("Missing or insufficient permissions") && Auth.auth().currentUser == nil {
                    Logger.error("Ignoring permission error during startup (no authenticated user)")
                    completion(true, nil)
                    return
                }
                completion(false, error.localizedDescription)
                return
            }
            
            Logger.info("Firebase connection successful!")
            completion(true, nil)
        }
    }
    
    /// Diagnose connection issues and return a helpful report
    /// - Returns: A diagnostic report string
    func diagnoseConnectionIssues() -> String {
        var report = "Firebase Diagnostics Report\n"
        report += "-------------------------\n"
        
        // Check if Firebase is initialized
        report += "Firebase initialized: \(isInitialized ? "Yes" : "No")\n"
        
        // Check network connectivity
        if let reachability = reachability {
            report += "Network connection: \(reachability.connection == .unavailable ? "Unavailable" : "Available")\n"
            
            switch reachability.connection {
            case .wifi:
                report += "Connection type: WiFi\n"
            case .cellular:
                report += "Connection type: Cellular\n"
            case .unavailable:
                report += "Connection type: Unavailable\n"
            }
        } else {
            report += "Reachability: Not initialized\n"
        }
        
        // Check Firebase configuration
        if let app = FirebaseApp.app() {
            report += "Firebase app name: \(app.name)\n"
            
            // FirebaseOptions is not optional, so we can directly access its properties
            let options = app.options
            if let apiKey = options.apiKey {
                report += "API Key: \(apiKey.prefix(6))...\n"
            } else {
                report += "API Key: nil\n"
            }
            report += "Bundle ID: \(options.bundleID)\n"
            report += "GCM Sender ID: \(options.gcmSenderID)\n"
            report += "Database URL: \(options.databaseURL ?? "not set")\n"
            report += "Storage Bucket: \(options.storageBucket ?? "not set")\n"
            
            // Check if bundle ID matches Info.plist
            if let bundleID = Bundle.main.bundleIdentifier {
                report += "App bundle ID: \(bundleID)\n"
                report += "Bundle ID match: \(bundleID == options.bundleID ? "Yes" : "No")\n"
                
                if bundleID != options.bundleID {
                    report += "WARNING: Bundle ID mismatch!\n"
                }
            }
        } else {
            report += "Firebase app: Not configured\n"
        }
        
        // Check environment
        report += "Environment: \(environment.rawValue)\n"
        
        // Check FilebaseOptions file exists
        let filename = environment.configFileName
        if let path = Bundle.main.path(forResource: filename, ofType: "plist") {
            report += "Found \(filename).plist at: \(path)\n"
        } else {
            report += "ERROR: \(filename).plist not found!\n"
        }
        
        report += "-------------------------\n"
        return report
    }
} 