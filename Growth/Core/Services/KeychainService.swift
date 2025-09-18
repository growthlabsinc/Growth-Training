//
//  KeychainService.swift
//  Growth
//
//  Service for secure credential storage in Keychain
//

import Foundation
import Security
import LocalAuthentication

/// Service for managing secure credential storage in the iOS Keychain
class KeychainService {
    static let shared = KeychainService()
    
    private let service = Bundle.main.bundleIdentifier ?? "com.growthtraining.Growth"
    private let credentialsKey = "user.credentials"
    private let refreshTokenKey = "user.refreshToken"
    private let biometricCredentialsKey = "user.credentials.biometric"
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Store user credentials securely in keychain
    func storeCredentials(email: String, password: String) -> Bool {
        let credentials = "\(email):\(password)"
        guard let data = credentials.data(using: .utf8) else { return false }
        
        return save(data: data, for: credentialsKey)
    }
    
    /// Retrieve stored credentials
    func retrieveCredentials() -> (email: String, password: String)? {
        guard let data = load(for: credentialsKey),
              let credentials = String(data: data, encoding: .utf8) else { return nil }
        
        let components = credentials.split(separator: ":", maxSplits: 1)
        guard components.count == 2 else { return nil }
        
        return (String(components[0]), String(components[1]))
    }
    
    /// Store refresh token
    func storeRefreshToken(_ token: String) -> Bool {
        guard let data = token.data(using: .utf8) else { return false }
        return save(data: data, for: refreshTokenKey)
    }
    
    /// Retrieve refresh token
    func retrieveRefreshToken() -> String? {
        guard let data = load(for: refreshTokenKey) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    /// Remove stored credentials
    func removeCredentials() {
        delete(for: credentialsKey)
    }
    
    /// Remove refresh token
    func removeRefreshToken() {
        delete(for: refreshTokenKey)
    }
    
    /// Remove all stored data
    func removeAll() {
        removeCredentials()
        removeRefreshToken()
        removeBiometricCredentials()
    }
    
    // MARK: - Biometric-Protected Storage (Following Apple's recommendations)
    
    /// Store credentials with biometric protection
    /// Based on Apple's "Accessing Keychain Items with Face ID or Touch ID" documentation
    func storeBiometricCredentials(email: String, password: String) async throws -> Bool {
        let credentials = "\(email):\(password)"
        guard let data = credentials.data(using: .utf8) else { return false }
        
        // Create access control for biometric authentication
        guard let access = SecAccessControlCreateWithFlags(
            nil, // Use the default allocator
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, // Most restrictive accessibility
            .userPresence, // Require user presence (biometrics or passcode fallback)
            nil // Ignore any error
        ) else {
            throw KeychainError.accessControlCreationFailed
        }
        
        // Create a context with custom configuration
        let context = LAContext()
        context.touchIDAuthenticationAllowableReuseDuration = 10 // 10-second grace period
        context.localizedReason = "Authenticate to save your login credentials securely"
        
        return try await saveBiometricData(data: data, for: biometricCredentialsKey, accessControl: access, context: context)
    }
    
    /// Retrieve biometric-protected credentials
    func retrieveBiometricCredentials() async throws -> (email: String, password: String)? {
        let context = LAContext()
        context.localizedReason = "Authenticate to access your saved login credentials"
        
        guard let data = try await loadBiometricData(for: biometricCredentialsKey, context: context),
              let credentials = String(data: data, encoding: .utf8) else { 
            return nil 
        }
        
        let components = credentials.split(separator: ":", maxSplits: 1)
        guard components.count == 2 else { return nil }
        
        return (String(components[0]), String(components[1]))
    }
    
    /// Remove biometric-protected credentials
    func removeBiometricCredentials() {
        delete(for: biometricCredentialsKey)
    }
    
    /// Check if biometric credentials are stored
    func hasBiometricCredentials() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: biometricCredentialsKey,
            kSecUseAuthenticationUI as String: kSecUseAuthenticationUISkip // Don't prompt for auth, just check existence
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // MARK: - Private Keychain Methods
    
    private func save(data: Data, for key: String) -> Bool {
        // Delete any existing item
        delete(for: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    private func load(for key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }
    
    private func delete(for key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Private Biometric Methods
    
    /// Save data with biometric protection
    private func saveBiometricData(data: Data, for key: String, accessControl: SecAccessControl, context: LAContext) async throws -> Bool {
        // Delete any existing item first
        delete(for: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecAttrAccessControl as String: accessControl,
            kSecUseAuthenticationContext as String: context,
            kSecValueData as String: data
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        switch status {
        case errSecSuccess:
            return true
        case errSecUserCanceled:
            throw KeychainError.userCancelled
        case errSecAuthFailed:
            throw KeychainError.authenticationFailed
        case errSecDuplicateItem:
            throw KeychainError.duplicateItem
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    /// Load biometric-protected data
    private func loadBiometricData(for key: String, context: LAContext) async throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true,
            kSecUseAuthenticationContext as String: context
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        switch status {
        case errSecSuccess:
            return result as? Data
        case errSecItemNotFound:
            return nil
        case errSecUserCanceled:
            throw KeychainError.userCancelled
        case errSecAuthFailed:
            throw KeychainError.authenticationFailed
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }
}

// MARK: - KeychainError

enum KeychainError: LocalizedError {
    case accessControlCreationFailed
    case userCancelled
    case authenticationFailed
    case duplicateItem
    case unexpectedStatus(OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .accessControlCreationFailed:
            return "Failed to create access control for biometric authentication"
        case .userCancelled:
            return "User cancelled biometric authentication"
        case .authenticationFailed:
            return "Biometric authentication failed"
        case .duplicateItem:
            return "Item already exists in keychain"
        case .unexpectedStatus(let status):
            return "Unexpected keychain status: \(status)"
        }
    }
}