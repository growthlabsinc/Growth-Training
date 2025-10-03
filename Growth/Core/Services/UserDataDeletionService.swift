import Foundation
import FirebaseAuth
import FirebaseFirestore
import UIKit

/// Service responsible for handling user data deletion requests (MVP implementation).
///
/// This service deletes:
///  • User document in `users` collection
///  • Session logs in `sessionLogs` collection
///  • Goals in `goals` collection
///  • Progression events in `progressionEvents` collection
///  • Any other collection filtered by `userId`
///
/// Optionally, it can also delete the Firebase Auth account itself.
@MainActor
final class UserDataDeletionService {
    static let shared = UserDataDeletionService()
    private init() {}
    
    private let db = Firestore.firestore()
    
    /// Initiates deletion of all user data (and optionally the account).
    /// - Parameters:
    ///   - userId: The UID of the user whose data should be deleted.
    ///   - deleteAuthAccount: If true, deletes the Firebase Auth account after data deletion.
    ///   - completion: Completion callback with success flag and optional error.
    func deleteAllUserData(userId: String, deleteAuthAccount: Bool = false, completion: @escaping (Bool, Error?) -> Void) {
        Task {
            do {
                // First delete Firestore data
                try await deleteFirestoreData(for: userId)
                
                // Then delete auth account if requested
                if deleteAuthAccount {
                    try await deleteAuthUser()
                }
                
                // Ensure we're on main thread for completion
                await MainActor.run {
                    completion(true, nil)
                }
            } catch {
                // Check if it's an auth error requiring reauthentication
                let nsError = error as NSError
                if nsError.domain == "FIRAuthErrorDomain" && nsError.code == 17014 {
                    // requiresRecentLogin error
                    await MainActor.run {
                        completion(false, NSError(domain: "UserDataDeletionService", 
                                                 code: 1, 
                                                 userInfo: [NSLocalizedDescriptionKey: "Your session has expired for security reasons. Please verify your identity to continue."]))
                    }
                } else if nsError.domain == "FIRAuthErrorDomain" {
                    // Other auth errors
                    await MainActor.run {
                        let message: String
                        switch nsError.code {
                        case 17011:
                            message = "User account not found. You may have already deleted this account."
                        case 17007:
                            message = "Your account appears to have been deleted or disabled."
                        default:
                            message = "Authentication error: \(error.localizedDescription)"
                        }
                        completion(false, NSError(domain: "UserDataDeletionService",
                                                 code: nsError.code,
                                                 userInfo: [NSLocalizedDescriptionKey: message]))
                    }
                } else {
                    await MainActor.run {
                        completion(false, error)
                    }
                }
            }
        }
    }
    
    // MARK: - Private helpers
    
    private func deleteAuthUser() async throws {
        guard let user = Auth.auth().currentUser else { 
            throw NSError(domain: "UserDataDeletionService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])
        }
        
        // Delete the user account
        try await user.delete()
        
        // Sign out to ensure clean state
        try Auth.auth().signOut()
    }
    
    /// Deletes user related documents across known collections. Extend list as new collections are added.
    private func deleteFirestoreData(for userId: String) async throws {
        Logger.info("UserDataDeletionService: Starting data deletion for user: \(userId)")
        
        // Collections where each document has `userId` field
        let perDocumentCollections = [
            "sessionLogs",
            "goals",
            "progressionEvents",
            "gains_entries",
            "activeTimers",
            "routineProgress",
            "deviceTokens",
            "customRoutines",
            "methodProgress",
            "achievements",
            "liveActivityTokens",
            "aiChatSessions",
            "progressSnapshots",
            "activityLogs"
        ]
        
        for collection in perDocumentCollections {
            do {
                Logger.info("UserDataDeletionService: Deleting documents from \(collection)...")
                try await deleteDocuments(in: collection, whereField: "userId", equals: userId)
                Logger.info("UserDataDeletionService: Successfully deleted from \(collection)")
            } catch {
                Logger.error("UserDataDeletionService: Error deleting from \(collection): \(error.localizedDescription)")
                // Continue with other collections even if one fails
            }
        }
        
        // Delete user-specific document collections (with userId as document ID)
        let userDocumentCollections = [
            "userPreferences",
            "reminderSettings",
            "subscriptions"
        ]
        
        for collection in userDocumentCollections {
            do {
                try await db.collection(collection).document(userId).delete()
            } catch {
                Logger.error("UserDataDeletionService: Error deleting from \(collection): \(error.localizedDescription)")
            }
        }
        
        // Delete subcollections under the user document
        let userRef = db.collection("users").document(userId)
        let subcollections = ["stats", "customRoutines", "routineProgress", "deviceTokens", "sessionLogs"]
        
        Logger.info("UserDataDeletionService: Deleting subcollections under users/\(userId)")
        for subcollection in subcollections {
            do {
                Logger.info("UserDataDeletionService: Deleting subcollection: \(subcollection)")
                let query = userRef.collection(subcollection).limit(to: 500)
                var batch = db.batch()
                var documentsInBatch = 0
                var totalDeleted = 0
                
                while true {
                    let snapshot = try await query.getDocuments()
                    guard !snapshot.documents.isEmpty else { 
                        Logger.info("UserDataDeletionService: No more documents in \(subcollection)")
                        break 
                    }
                    
                    for doc in snapshot.documents {
                        batch.deleteDocument(doc.reference)
                        documentsInBatch += 1
                        
                        if documentsInBatch >= 500 {
                            try await batch.commit()
                            totalDeleted += documentsInBatch
                            Logger.info("UserDataDeletionService: Deleted \(totalDeleted) documents from \(subcollection)")
                            batch = db.batch()
                            documentsInBatch = 0
                        }
                    }
                    
                    // Commit any remaining documents
                    if documentsInBatch > 0 {
                        try await batch.commit()
                        totalDeleted += documentsInBatch
                        Logger.info("UserDataDeletionService: Deleted \(totalDeleted) documents from \(subcollection)")
                    }
                    
                    if snapshot.documents.count < 500 {
                        break
                    }
                }
                Logger.info("UserDataDeletionService: Successfully deleted all documents from \(subcollection)")
            } catch {
                Logger.error("UserDataDeletionService: Error deleting subcollection \(subcollection): \(error.localizedDescription)")
            }
        }
        
        // Finally, delete the user document itself (must be last)
        Logger.info("UserDataDeletionService: Deleting user document...")
        try await db.collection("users").document(userId).delete()
        Logger.info("UserDataDeletionService: Successfully deleted user document")
    }
    
    /// Deletes documents in a collection that match a where filter, in batches of 500.
    private func deleteDocuments(in collection: String, whereField field: String, equals value: String) async throws {
        let query = db.collection(collection).whereField(field, isEqualTo: value).limit(to: 500)
        var batch: WriteBatch = db.batch()
        var documentsInBatch = 0
        
        while true {
            let snapshot = try await query.getDocuments()
            guard !snapshot.documents.isEmpty else { break }
            
            for doc in snapshot.documents {
                batch.deleteDocument(doc.reference)
                documentsInBatch += 1
                
                // Commit batch if it reaches 500 operations
                if documentsInBatch >= 500 {
                    try await batch.commit()
                    batch = db.batch()
                    documentsInBatch = 0
                }
            }
            
            // Commit any remaining documents in the batch
            if documentsInBatch > 0 {
                try await batch.commit()
                batch = db.batch()
                documentsInBatch = 0
            }
            
            // If fewer than 500 documents were fetched, we're done
            if snapshot.documents.count < 500 {
                break
            }
        }
    }
} 