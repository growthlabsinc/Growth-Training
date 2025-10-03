//
//  AppCheckDiagnostics.swift
//  Growth
//
//  Diagnostic tools for troubleshooting App Check issues
//

import Foundation
import FirebaseAppCheck
import FirebaseCore

/// Comprehensive App Check diagnostics and troubleshooting
class AppCheckDiagnostics {
    static let shared = AppCheckDiagnostics()
    
    private let tokenKey = "FIRAAppCheckDebugToken"
    
    private init() {}
    
    /// Run comprehensive diagnostics
    func runDiagnostics(completion: @escaping (DiagnosticReport) -> Void) {
        var report = DiagnosticReport()
        
        // Check 1: Debug token existence
        report.debugTokenExists = UserDefaults.standard.string(forKey: tokenKey) != nil
        report.debugToken = UserDefaults.standard.string(forKey: tokenKey)
        
        // Check 2: Debug flag
        report.hasDebugFlag = ProcessInfo.processInfo.arguments.contains("-FIRDebugEnabled")
        
        // Check 3: Firebase configuration
        report.firebaseConfigured = FirebaseApp.app() != nil
        
        // Check 4: App Check instance
        report.appCheckAvailable = true // Will be validated in token check
        
        // Check 5: Token retrieval
        AppCheck.appCheck().token(forcingRefresh: false) { token, error in
            if let error = error {
                report.tokenRetrievalError = error.localizedDescription
                report.tokenRetrievalSuccess = false
                
                // Analyze error type
                if error.localizedDescription.contains("403") {
                    report.errorType = .tokenNotRegistered
                } else if error.localizedDescription.contains("404") {
                    report.errorType = .appNotConfigured
                } else {
                    report.errorType = .unknown
                }
            } else if let token = token {
                report.tokenRetrievalSuccess = true
                report.tokenPrefix = String(token.token.prefix(20))
                report.tokenExpiration = token.expirationDate
            }
            
            // Generate recommendations
            report.recommendations = self.generateRecommendations(from: report)
            
            completion(report)
        }
    }
    
    /// Generate recommendations based on diagnostic results
    private func generateRecommendations(from report: DiagnosticReport) -> [String] {
        var recommendations: [String] = []
        
        if !report.debugTokenExists {
            recommendations.append("No debug token found. The app should generate one on first run.")
        }
        
        if !report.hasDebugFlag {
            recommendations.append("Add -FIRDebugEnabled to your Xcode scheme arguments for better debugging.")
        }
        
        if !report.firebaseConfigured {
            recommendations.append("Firebase is not configured. Ensure FirebaseApp.configure() is called.")
        }
        
        if !report.tokenRetrievalSuccess {
            switch report.errorType {
            case .tokenNotRegistered:
                recommendations.append("Register debug token '\(report.debugToken ?? "N/A")' in Firebase Console.")
                recommendations.append("Go to: https://console.firebase.google.com/project/growth-training-app/appcheck/apps")
            case .appNotConfigured:
                recommendations.append("App Check may not be properly configured in Firebase Console.")
            case .unknown:
                recommendations.append("Unknown error. Check Firebase Console and verify configuration.")
            }
        }
        
        return recommendations
    }
    
    /// Print diagnostic report
    func printReport(_ report: DiagnosticReport) {
        Logger.debug("\n========================================")
        Logger.debug("📊 APP CHECK DIAGNOSTIC REPORT")
        Logger.debug("========================================")
        Logger.debug("✅ Debug Token Exists: \(report.debugTokenExists)")
        if let token = report.debugToken {
            Logger.debug("🔑 Debug Token: \(token)")
        }
        Logger.debug("✅ -FIRDebugEnabled Flag: \(report.hasDebugFlag)")
        Logger.debug("✅ Firebase Configured: \(report.firebaseConfigured)")
        Logger.info("✅ Token Retrieval Success: \(report.tokenRetrievalSuccess)")
        
        if let error = report.tokenRetrievalError {
            Logger.error("❌ Error: \(error)")
            Logger.error("🔍 Error Type: \(report.errorType)")
        }
        
        if let prefix = report.tokenPrefix {
            Logger.debug("🎫 Token Prefix: \(prefix)...")
        }
        
        if let expiration = report.tokenExpiration {
            Logger.debug("⏰ Token Expires: \(expiration)")
        }
        
        if !report.recommendations.isEmpty {
            Logger.debug("\n📋 RECOMMENDATIONS:")
            for (index, recommendation) in report.recommendations.enumerated() {
                Logger.debug("\(index + 1). \(recommendation)")
            }
        }
        Logger.debug("========================================\n")
    }
    
    /// Force generate a new debug token
    func forceGenerateNewToken() -> String {
        let newToken = UUID().uuidString
        UserDefaults.standard.set(newToken, forKey: tokenKey)
        UserDefaults.standard.synchronize()
        
        Logger.debug("\n🆕 Generated new debug token: \(newToken)")
        Logger.debug("⚠️  Restart the app and register this token in Firebase Console\n")
        
        return newToken
    }
    
    /// Clear existing debug token
    func clearDebugToken() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.synchronize()
        Logger.debug("🗑️ Debug token cleared. Restart app to generate a new one.")
    }
}

/// Diagnostic report structure
struct DiagnosticReport {
    var debugTokenExists: Bool = false
    var debugToken: String?
    var hasDebugFlag: Bool = false
    var firebaseConfigured: Bool = false
    var appCheckAvailable: Bool = false
    var tokenRetrievalSuccess: Bool = false
    var tokenRetrievalError: String?
    var errorType: AppCheckErrorType = .unknown
    var tokenPrefix: String?
    var tokenExpiration: Date?
    var recommendations: [String] = []
}

/// App Check error types
enum AppCheckErrorType: String {
    case tokenNotRegistered = "Token Not Registered"
    case appNotConfigured = "App Not Configured"
    case unknown = "Unknown Error"
}

/// Quick diagnostic helper
extension AppCheck {
    /// Run quick diagnostics and print results
    static func runQuickDiagnostics() {
        AppCheckDiagnostics.shared.runDiagnostics { report in
            AppCheckDiagnostics.shared.printReport(report)
        }
    }
}