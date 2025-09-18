//
//  BiometricAuthService.swift
//  Growth
//
//  Service for handling Face ID and Touch ID authentication
//

import Foundation
import LocalAuthentication
import SwiftUI

/// Service for managing biometric authentication (Face ID/Touch ID)
/// Implements Apple's recommended patterns for biometric authentication
class BiometricAuthService: ObservableObject {
    static let shared = BiometricAuthService()
    
    @Published var biometryType: LABiometryType = .none
    @Published var isUnlocked = false
    @Published var lastError: LAError?
    
    private var context = LAContext()
    
    // UserDefaults keys
    private let requireBiometricOnLaunchKey = "requireBiometricOnLaunch"
    private let biometricLoginEnabledKey = "biometricLoginEnabled"
    
    // Failed attempts tracking
    private let maxFailedAttempts = 3
    @Published private(set) var failedAttempts = 0
    @Published private(set) var isTemporarilyLocked = false
    public let lockoutDuration: TimeInterval = 60 // 1 minute lockout
    private var lockoutTimer: Timer?
    
    private init() {
        // Don't check availability immediately to avoid SwiftUI publishing issues
        // Views should call checkBiometryAvailability() when needed
        setupContext()
    }
    
    /// Setup and configure the authentication context
    private func setupContext() {
        context = LAContext()
        
        // Set custom localized strings as recommended by Apple
        context.localizedCancelTitle = "Use Password"
        
        // Allow reuse of Touch ID authentication for 10 seconds (Apple's recommended pattern)
        context.touchIDAuthenticationAllowableReuseDuration = 10
    }
    
    /// Check if biometric authentication is available
    func checkBiometryAvailability() {
        setupContext()
        var error: NSError?
        
        let type = if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.biometryType
        } else {
            LABiometryType.none
        }
        
        // Update on main actor to avoid SwiftUI publishing issues
        Task { @MainActor in
            self.biometryType = type
        }
    }
    
    /// Check if biometric authentication is available and not locked out
    func canUseBiometrics() -> Bool {
        // Check if temporarily locked due to failed attempts
        if isTemporarilyLocked {
            return false
        }
        
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    /// Check if biometry is available (without lockout check)
    func isBiometryAvailable() -> Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    /// Human-readable name for the biometry type
    var biometryName: String {
        switch biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        case .none:
            return "Biometric Authentication"
        @unknown default:
            return "Biometric Authentication"
        }
    }
    
    /// Icon name for the biometry type
    var biometryIcon: String {
        switch biometryType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        case .none:
            return "lock.shield"
        @unknown default:
            return "lock.shield"
        }
    }
    
    // MARK: - Settings
    
    /// Whether biometric authentication is required on app launch
    var requireBiometricOnLaunch: Bool {
        get { UserDefaults.standard.bool(forKey: requireBiometricOnLaunchKey) }
        set { UserDefaults.standard.set(newValue, forKey: requireBiometricOnLaunchKey) }
    }
    
    /// Whether biometric login is enabled for authentication
    var biometricLoginEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: biometricLoginEnabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: biometricLoginEnabledKey) }
    }
    
    // MARK: - Authentication Methods
    
    /// Authenticate with biometrics using Apple's recommended patterns
    @MainActor
    func authenticate(reason: String, policy: LAPolicy = .deviceOwnerAuthentication) async -> Bool {
        // Check if temporarily locked due to failed attempts
        guard !isTemporarilyLocked else {
            Logger.error("Biometric authentication temporarily locked due to failed attempts")
            return false
        }
        
        // Setup fresh context for each authentication attempt
        setupContext()
        var error: NSError?
        
        // Test policy availability first (Apple's recommended pattern)
        guard context.canEvaluatePolicy(policy, error: &error) else {
            let errorMessage = error?.localizedDescription ?? "Biometric authentication not available"
            Logger.error("Biometric authentication not available: \(errorMessage)")
            lastError = error as? LAError
            return false
        }
        
        do {
            // Attempt biometric authentication
            try await context.evaluatePolicy(policy, localizedReason: reason)
            
            // Success - reset failed attempts and unlock
            resetFailedAttempts()
            isUnlocked = true
            lastError = nil
            
            Logger.info("Biometric authentication successful")
            return true
            
        } catch let error as LAError {
            lastError = error
            
            // Handle specific error cases according to Apple's documentation
            switch error.code {
            case .authenticationFailed:
                // This is a failed biometric attempt - increment counter
                handleFailedAttempt()
                Logger.error("Biometric authentication failed - authentication not recognized")
                
            case .userCancel:
                Logger.info("User cancelled biometric authentication")
                
            case .systemCancel:
                Logger.info("System cancelled biometric authentication")
                
            case .userFallback:
                Logger.info("User chose to use fallback authentication")
                
            case .biometryNotAvailable:
                Logger.error("Biometry not available on this device")
                
            case .biometryNotEnrolled:
                Logger.error("No biometry enrolled - user needs to set up Face ID/Touch ID")
                
            case .biometryLockout:
                Logger.error("Biometry locked out - too many failed attempts")
                handleBiometryLockout()
                
            case .passcodeNotSet:
                Logger.error("Device passcode not set")
                
            case .invalidContext:
                Logger.error("Invalid authentication context")
                
            default:
                Logger.error("Biometric authentication failed with error: \(error.localizedDescription)")
            }
            
            return false
            
        } catch {
            Logger.error("Unexpected authentication error: \(error.localizedDescription)")
            lastError = LAError(.authenticationFailed)
            return false
        }
    }
    
    /// Authenticate for app access (used when app requires biometric on launch)
    @MainActor
    func authenticateForAppAccess() async -> Bool {
        let reason = "Authenticate to access \(Bundle.main.displayName)"
        return await authenticate(reason: reason)
    }
    
    /// Authenticate for login (used when logging in with biometrics)
    @MainActor
    func authenticateForLogin() async -> Bool {
        let reason = "Log in to your account"
        return await authenticate(reason: reason)
    }
    
    /// Authenticate with biometrics only (no passcode fallback)
    @MainActor
    func authenticateWithBiometricsOnly(reason: String) async -> Bool {
        return await authenticate(reason: reason, policy: .deviceOwnerAuthenticationWithBiometrics)
    }
    
    // MARK: - Failed Attempts Management
    
    /// Handle a failed biometric attempt
    @MainActor
    private func handleFailedAttempt() {
        failedAttempts += 1
        
        if failedAttempts >= maxFailedAttempts {
            enableTemporaryLockout()
        }
    }
    
    /// Handle biometry lockout from the system
    @MainActor
    private func handleBiometryLockout() {
        // When the system locks out biometry, we should also enable our temporary lockout
        enableTemporaryLockout()
    }
    
    /// Enable temporary lockout due to failed attempts
    @MainActor
    private func enableTemporaryLockout() {
        isTemporarilyLocked = true
        
        // Clear any existing timer
        lockoutTimer?.invalidate()
        
        // Start lockout timer
        lockoutTimer = Timer.scheduledTimer(withTimeInterval: lockoutDuration, repeats: false) { _ in
            Task { @MainActor in
                BiometricAuthService.shared.disableTemporaryLockout()
            }
        }
        
        Logger.info("Biometric authentication temporarily locked for \(lockoutDuration) seconds")
    }
    
    /// Disable temporary lockout
    @MainActor
    private func disableTemporaryLockout() {
        isTemporarilyLocked = false
        lockoutTimer?.invalidate()
        lockoutTimer = nil
        Logger.info("Biometric authentication lockout expired")
    }
    
    /// Reset failed attempts counter
    @MainActor
    private func resetFailedAttempts() {
        failedAttempts = 0
        if isTemporarilyLocked {
            disableTemporaryLockout()
        }
    }
    
    /// Get human-readable error message from LAError
    func getErrorMessage(from error: LAError) -> String {
        switch error.code {
        case .authenticationFailed:
            return "Authentication failed. Please try again."
        case .userCancel:
            return "Authentication was cancelled."
        case .userFallback:
            return "User chose to enter password."
        case .biometryNotAvailable:
            return "\(biometryName) is not available on this device."
        case .biometryNotEnrolled:
            return "\(biometryName) is not set up. Please set up \(biometryName) in Settings."
        case .biometryLockout:
            return "\(biometryName) is locked. Please try again later or use your passcode."
        case .passcodeNotSet:
            return "Device passcode is not set."
        default:
            return "Authentication failed: \(error.localizedDescription)"
        }
    }
    
    /// Reset authentication state
    func reset() {
        Task { @MainActor in
            isUnlocked = false
            lastError = nil
            resetFailedAttempts()
        }
        setupContext()
    }
}

// MARK: - LAContext Extension for Biometric Type Detection
extension LAContext {
    enum BiometricType: String {
        case none
        case touchID
        case faceID
        case opticID // Added for future biometric methods
    }
    
    /// Returns the detected biometric type based on device capabilities
    var detectedBiometricType: BiometricType {
        var error: NSError?
        
        // Check if the device supports biometric authentication
        guard self.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        
        if #available(iOS 11.0, *) {
            // Determine the specific biometric type supported on iOS 11.0 and later
            switch self.biometryType {
            case .none:
                return .none
            case .touchID:
                return .touchID
            case .faceID:
                return .faceID
            default:
                if #available(iOS 17.0, *) {
                    // Support for potential future biometric methods
                    if self.biometryType == .opticID {
                        return .opticID
                    }
                }
                return .none
            }
        }
        
        // Fallback to checking for Touch ID support on iOS versions older than 11.0
        return self.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) ? .touchID : .none
    }
}

// Helper extension to get app display name
extension Bundle {
    var displayName: String {
        return object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
               object(forInfoDictionaryKey: "CFBundleName") as? String ??
               "Growth"
    }
}