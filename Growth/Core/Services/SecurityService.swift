import Foundation
import Security

/// Service responsible for handling sensitive data storage and other security utilities.
/// Currently provides:
/// 1. Basic Keychain CRUD helpers for storing small secrets (e.g. auth tokens).
/// 2. Helper for applying strong file protection to local files.
///
/// NOTE: Keychain helpers here use a simple (key, value) model. For more sophisticated
/// data you may want to create a wrapper model or use Codable with JSON Data.
final class SecurityService {
    // MARK: - Singleton
    static let shared = SecurityService()
    private init() {}

    // MARK: - Keychain Keys
    struct Keys {
        /// Example key for Firebase Auth ID token (refreshable via Firebase SDK)
        static let firebaseIDToken = "com.growthlabs.growthmethod.firebase.idToken"
    }

    // MARK: - Public API – Keychain Convenience

    /// Store a string securely in the Keychain.
    /// - Parameters:
    ///   - value: The string to store.
    ///   - key: Unique key used as the account attribute in Keychain query.
    /// - Returns: Boolean indicating success.
    @discardableResult
    func saveSecureString(_ value: String, for key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        return saveSecureData(data, for: key)
    }

    /// Retrieve a string from the Keychain.
    /// - Parameter key: The key used when saving.
    /// - Returns: Optional string if found.
    func readSecureString(for key: String) -> String? {
        guard let data = readSecureData(for: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Delete a keychain item by key.
    /// - Parameter key: The key used when saving.
    /// - Returns: Boolean indicating deletion success.
    @discardableResult
    func deleteSecureItem(for key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - File Protection Helper

    /// Apply `.complete` file protection to the file at the specified URL.
    /// If the file does not exist this method returns gracefully.
    /// - Parameter url: File URL.
    func applyCompleteFileProtectionIfExists(at url: URL) {
        let fm = FileManager.default
        guard fm.fileExists(atPath: url.path) else { return }
        do {
            try fm.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: url.path)
        } catch {
            #if DEBUG
            Logger.error("[SecurityService] Failed to set file protection for \(url.lastPathComponent): \(error)")
            #endif
        }
    }

    // MARK: - Private Keychain Helpers

    private func saveSecureData(_ data: Data, for key: String) -> Bool {
        // Delete existing item if present to avoid duplicates.
        _ = deleteSecureItem(for: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            // Accessible when device is unlocked – change to .afterFirstUnlock if needed for BG tasks.
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    private func readSecureData(for key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else { return nil }
        return item as? Data
    }
} 