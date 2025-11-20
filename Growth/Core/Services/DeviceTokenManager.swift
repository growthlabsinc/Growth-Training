//
//  DeviceTokenManager.swift
//  Growth
//
//  Device token management with deduplication and environment tracking
//

import Foundation
import Firebase
import FirebaseFirestore
import UIKit

/// Manages device tokens to prevent duplicate notifications
class DeviceTokenManager {
    static let shared = DeviceTokenManager()

    private let db = Firestore.firestore()

    private init() {}

    /// Get a unique device identifier
    private var deviceIdentifier: String {
        // Use vendor ID as a stable device identifier
        // This will be the same for all builds from the same developer on the same device
        return UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    }

    /// Get the current build type
    private var buildType: String {
        #if DEBUG
        return "debug"
        #elseif targetEnvironment(simulator)
        return "simulator"
        #else
        return "release"
        #endif
    }

    /// Get the current environment
    private var environment: String {
        // Detect environment from bundle identifier or configuration
        let bundleID = Bundle.main.bundleIdentifier ?? ""

        // Check for environment-specific identifiers if you use them
        if bundleID.contains(".dev") || bundleID.contains(".development") {
            return "development"
        } else if bundleID.contains(".staging") {
            return "staging"
        } else {
            return "production"
        }
    }

    /// Store device token with metadata to prevent duplicates
    func storeDeviceToken(userId: String, token: String, fcmToken: String?, completion: @escaping (Error?) -> Void) {
        let deviceId = deviceIdentifier
        let buildInfo = buildType
        let env = environment

        // Create comprehensive token data
        let tokenData: [String: Any] = [
            "token": token,
            "fcmToken": fcmToken ?? "",
            "platform": "iOS",
            "deviceId": deviceId,
            "buildType": buildInfo,
            "environment": env,
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            "buildNumber": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown",
            "osVersion": UIDevice.current.systemVersion,
            "deviceModel": UIDevice.current.model,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
            "lastActive": FieldValue.serverTimestamp()
        ]

        // Use device ID + build type as the document ID to ensure only one token per device/build combination
        let documentId = "\(deviceId)_\(buildInfo)"

        Logger.info("📱 Storing device token:")
        Logger.info("  Device ID: \(deviceId)")
        Logger.info("  Build Type: \(buildInfo)")
        Logger.info("  Environment: \(env)")
        Logger.info("  Document ID: \(documentId)")

        // First, clean up old tokens from this device
        cleanupOldTokensForDevice(userId: userId, currentDocumentId: documentId) { _ in
            // Store the new/updated token
            self.db.collection("users").document(userId)
                .collection("deviceTokens").document(documentId)
                .setData(tokenData) { error in
                    if let error = error {
                        Logger.error("Failed to store device token: \(error)")
                    } else {
                        Logger.info("✅ Device token stored successfully")
                    }
                    completion(error)
                }
        }
    }

    /// Clean up old tokens for this device to prevent duplicates
    private func cleanupOldTokensForDevice(userId: String, currentDocumentId: String, completion: @escaping (Error?) -> Void) {
        let deviceId = deviceIdentifier

        // Query for all tokens from this device
        db.collection("users").document(userId)
            .collection("deviceTokens")
            .whereField("deviceId", isEqualTo: deviceId)
            .getDocuments { snapshot, error in
                if let error = error {
                    Logger.error("Failed to query old tokens: \(error)")
                    completion(error)
                    return
                }

                guard let documents = snapshot?.documents else {
                    completion(nil)
                    return
                }

                // Delete old tokens from the same device but different builds
                let batch = self.db.batch()
                var deletedCount = 0

                for document in documents {
                    // Don't delete the current token
                    if document.documentID != currentDocumentId {
                        Logger.info("🗑️ Removing old token: \(document.documentID)")
                        batch.deleteDocument(document.reference)
                        deletedCount += 1
                    }
                }

                if deletedCount > 0 {
                    batch.commit { error in
                        if let error = error {
                            Logger.error("Failed to delete old tokens: \(error)")
                        } else {
                            Logger.info("✅ Cleaned up \(deletedCount) old token(s)")
                        }
                        completion(error)
                    }
                } else {
                    completion(nil)
                }
            }
    }

    /// Clean up tokens older than specified days
    func cleanupStaleTokens(userId: String, olderThanDays: Int = 30, completion: @escaping (Error?) -> Void) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -olderThanDays, to: Date()) ?? Date()
        let cutoffTimestamp = Timestamp(date: cutoffDate)

        db.collection("users").document(userId)
            .collection("deviceTokens")
            .whereField("lastActive", isLessThan: cutoffTimestamp)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(error)
                    return
                }

                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    completion(nil)
                    return
                }

                let batch = self.db.batch()
                for document in documents {
                    batch.deleteDocument(document.reference)
                }

                batch.commit { error in
                    if error == nil {
                        Logger.info("🧹 Cleaned up \(documents.count) stale token(s)")
                    }
                    completion(error)
                }
            }
    }

    /// Update last active timestamp for current device token
    func updateLastActive(userId: String) {
        let documentId = "\(deviceIdentifier)_\(buildType)"

        db.collection("users").document(userId)
            .collection("deviceTokens").document(documentId)
            .updateData([
                "lastActive": FieldValue.serverTimestamp()
            ]) { error in
                if let error = error {
                    Logger.debug("Failed to update last active: \(error)")
                }
            }
    }

    /// Get active tokens for a user (for debugging)
    func getActiveTokens(userId: String, completion: @escaping ([String: Any]?, Error?) -> Void) {
        db.collection("users").document(userId)
            .collection("deviceTokens")
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(nil, error)
                    return
                }

                var tokens: [String: Any] = [:]

                snapshot?.documents.forEach { document in
                    let data = document.data()
                    tokens[document.documentID] = [
                        "token": data["token"] as? String ?? "",
                        "buildType": data["buildType"] as? String ?? "",
                        "environment": data["environment"] as? String ?? "",
                        "deviceId": data["deviceId"] as? String ?? "",
                        "lastActive": (data["lastActive"] as? Timestamp)?.dateValue() ?? Date()
                    ]
                }

                completion(tokens, nil)
            }
    }
}