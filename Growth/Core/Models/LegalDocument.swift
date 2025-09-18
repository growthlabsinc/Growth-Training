import Foundation

/// Model representing a legal document such as Privacy Policy, Terms of Use, or Disclaimers.
struct LegalDocument: Identifiable, Codable {
    /// Unique identifier (e.g., "privacy_policy", "terms_of_use", "disclaimer")
    let id: String
    /// Human-readable title
    let title: String
    /// Markdown or plain-text content of the document
    let content: String
    /// Semantic version string (e.g., "1.0.0")
    let version: String
    /// Last updated timestamp
    let lastUpdated: Date
    
    // MARK: - Version Helpers
    /// Compare semantic versions (simple lexicographic compare).
    /// Returns true if self.version is newer than otherVersion.
    func isNewer(than otherVersion: String) -> Bool {
        return version.compare(otherVersion, options: .numeric) == .orderedDescending
    }
} 