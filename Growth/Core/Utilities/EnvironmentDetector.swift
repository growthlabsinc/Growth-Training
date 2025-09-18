//
//  EnvironmentDetector.swift
//  Growth
//
//  Created by Claude on 2025-06-25.
//

import Foundation

/// Utility to detect the current app environment based on bundle identifier or build configuration
struct EnvironmentDetector {
    
    /// Determines the Firebase environment based on the app's bundle identifier
    static func detectEnvironment() -> FirebaseEnvironment {
        // Check debug configuration first - this ensures Xcode builds use development
        #if DEBUG
        // Logger.debug("Running in DEBUG configuration, using development environment")
        return .development
        #else
        
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            Logger.warning("Warning: No bundle identifier found, defaulting to production")
            return .production
        }
        
        // Determine environment based on bundle ID for release builds
        switch bundleIdentifier {
        case "com.growthlabs.growthmethod.dev":
            return .development
        case "com.growthlabs.growthmethod.staging":
            return .staging
        case "com.growthlabs.growthmethod":
            return .production
        default:
            Logger.warning("Warning: Unknown bundle identifier '\(bundleIdentifier)', defaulting to production")
            return .production
        }
        #endif
    }
    
    /// Checks if the app is running in development mode
    static var isDevelopment: Bool {
        return detectEnvironment() == .development
    }
    
    /// Checks if the app is running in staging mode
    static var isStaging: Bool {
        return detectEnvironment() == .staging
    }
    
    /// Checks if the app is running in production mode
    static var isProduction: Bool {
        return detectEnvironment() == .production
    }
    
    /// Returns a string description of the current environment
    static var currentEnvironmentDescription: String {
        let env = detectEnvironment()
        let bundleId = Bundle.main.bundleIdentifier ?? "Unknown"
        return "\(env.rawValue) (Bundle ID: \(bundleId))"
    }
}