//
//  AnonymizationService.swift
//  Growth
//
//  Created by Claude Code on 11/28/25.
//  Story 11.1: Anonymous Statistical ID Generation & Management
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Service for generating and managing anonymous statistical IDs for GrowthTrack exports
/// Provides privacy-preserving identifiers that allow longitudinal data tracking without exposing user identity
class AnonymizationService {
    /// Shared singleton instance
    static let shared = AnonymizationService()

    // MARK: - Private Constants

    /// UserDefaults key for storing anonymous statistical ID
    private let anonymousIdKey = "com.growthlabs.anonymousStatisticalId"

    /// UserDefaults key for tracking last ID regeneration timestamp
    private let lastRegenerationKey = "com.growthlabs.lastAnonymousIdRegeneration"

    /// Rate limit window in hours (24 hours minimum between regenerations)
    private let rateLimitHours: Double = 24

    // MARK: - Initialization

    /// Private initializer to enforce singleton pattern
    private init() {}

    // MARK: - Public Methods

    /// Retrieves existing anonymous ID or creates new one if none exists
    /// - Returns: Anonymous ID in GT-XXXXXXXX format (always non-nil)
    func getOrCreateAnonymousId() -> String {
        // Check for existing ID in UserDefaults
        if let existingId = UserDefaults.standard.string(forKey: anonymousIdKey),
           !existingId.isEmpty {
            return existingId
        }

        // No existing ID - generate new one
        let newId = generateNewId()
        logAnonymousIdGeneration(anonymousId: newId, action: "generated")
        return newId
    }

    /// Regenerates anonymous ID to break longitudinal linkage
    /// - Returns: New anonymous ID (GT-XXXXXXXX format)
    /// - Note: Rate limited to once per 24 hours. Returns existing ID if within rate limit window.
    func regenerateAnonymousId() -> String {
        // Check rate limiting
        guard canRegenerateId() else {
            // Return existing ID if rate limited
            return getOrCreateAnonymousId()
        }

        // Generate new ID
        let newId = generateNewId()

        // Update regeneration timestamp
        UserDefaults.standard.set(Date(), forKey: lastRegenerationKey)

        // Log regeneration for audit
        logAnonymousIdGeneration(anonymousId: newId, action: "regenerated")

        return newId
    }

    /// Checks if user can regenerate ID (not within rate limit window)
    /// - Returns: True if regeneration is allowed, false if rate limited
    func canRegenerateId() -> Bool {
        guard let lastDate = UserDefaults.standard.object(forKey: lastRegenerationKey) as? Date else {
            return true // First time, allow regeneration
        }

        let hoursSince = Date().timeIntervalSince(lastDate) / 3600
        return hoursSince >= rateLimitHours
    }

    /// Returns time remaining until next regeneration is allowed
    /// - Returns: TimeInterval in seconds until rate limit expires, or 0 if can regenerate now
    func timeUntilCanRegenerate() -> TimeInterval {
        guard let lastDate = UserDefaults.standard.object(forKey: lastRegenerationKey) as? Date else {
            return 0 // Can regenerate immediately
        }

        let elapsed = Date().timeIntervalSince(lastDate)
        let rateLimitSeconds = rateLimitHours * 3600
        let remaining = rateLimitSeconds - elapsed
        return max(0, remaining)
    }

    // MARK: - Private Methods

    /// Generates new anonymous ID in GT-XXXXXXXX format
    /// - Returns: Newly generated ID stored in UserDefaults
    private func generateNewId() -> String {
        // Generate UUID and take first 8 characters
        let uuid = UUID().uuidString
        let prefix = String(uuid.prefix(8)).uppercased()
        let anonymousId = "GT-\(prefix)"

        // Store in UserDefaults
        UserDefaults.standard.set(anonymousId, forKey: anonymousIdKey)

        // Store generation timestamp
        UserDefaults.standard.set(Date(), forKey: lastRegenerationKey)

        return anonymousId
    }

    /// Logs anonymous ID generation to Firestore for audit trail
    /// - Parameters:
    ///   - anonymousId: The generated anonymous ID (hashed for storage)
    ///   - action: Action performed (generated/regenerated)
    private func logAnonymousIdGeneration(anonymousId: String, action: String) {
        Task {
            do {
                let db = Firestore.firestore()

                // Hash the anonymous ID for audit storage (privacy protection)
                let hashedId = anonymousId.hashValue

                try await db.collection("anonymous_id_audit").addDocument(data: [
                    "userId": Auth.auth().currentUser?.uid ?? "unknown",
                    "anonymousIdHash": hashedId,
                    "timestamp": FieldValue.serverTimestamp(),
                    "action": action
                ])
            } catch {
                // Don't throw - audit logging should never block ID generation
                print("⚠️ AnonymizationService: Audit log failed - \(error.localizedDescription)")
            }
        }
    }
}
