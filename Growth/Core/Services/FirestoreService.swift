//
//  FirestoreService.swift
//  Growth
//
//  Created by Developer on 5/9/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

/// Service class for handling Firestore database operations
class FirestoreService {
    // MARK: - Properties
    
    /// Shared instance for singleton access
    static let shared = FirestoreService()
    
    /// Firestore database reference
    public let db = Firestore.firestore()
    
    /// Collection names
    private enum Collection {
        static let users = "users"
        static let methods = "growthMethods"
        static let logs = "sessionLogs"
        static let resources = "educationalResources"
        static let badges = "badges"
    }
    
    // MARK: - Session Log Operations
    
    /// Save a session log to Firestore
    /// - Parameters:
    ///   - sessionLog: The session log to save
    ///   - completion: Completion handler with optional Error
    func saveSessionLog(_ sessionLog: SessionLog, completion: @escaping (Error?) -> Void) {
        let docRef = db.collection(Collection.logs).document(sessionLog.id)
        
        docRef.setData(sessionLog.toFirestore) { error in
            completion(error)
        }
    }
    
    /// Get session logs for a user from the 'logs' collection, ordered by endTime
    /// - Parameters:
    ///   - userId: The user ID
    ///   - limit: Maximum number of logs to retrieve
    ///   - completion: Completion handler with array of SessionLog and optional Error
    func getSessionLogsForUserFromLogsByEndTime(userId: String, limit: Int = 10, completion: @escaping ([SessionLog], Error?) -> Void) {
        db.collection(Collection.logs)
            .whereField("userId", isEqualTo: userId)
            .order(by: "endTime", descending: true)
            .limit(to: limit)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    completion([], error)
                    return
                }
                var logs: [SessionLog] = []
                for document in querySnapshot?.documents ?? [] {
                    if let log = SessionLog(document: document) {
                        logs.append(log)
                    }
                }
                completion(logs, nil)
            }
    }
    
    /// Retrieves session logs for a user from the 'logs' collection, ordered by startTime
    /// - Parameters:
    ///   - userId: The ID of the user
    ///   - limit: Maximum number of logs to retrieve (default: 20)
    ///   - completion: Completion handler with array of SessionLog and optional Error
    func getSessionLogsForUserFromLogsByStartTime(userId: String, limit: Int = 20, completion: @escaping ([SessionLog], Error?) -> Void) {
        db.collection(Collection.logs)
            .whereField("userId", isEqualTo: userId)
            .order(by: "startTime", descending: true)
            .limit(to: limit)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    completion([], error)
                    return
                }
                var logs: [SessionLog] = []
                for document in querySnapshot?.documents ?? [] {
                    if let log = SessionLog(document: document) {
                        logs.append(log)
                    }
                }
                completion(logs, nil)
            }
    }
    
    /// Get session logs for a user from the 'sessionLogs' collection, ordered by endTime
    /// - Parameters:
    ///   - userId: The ID of the user
    ///   - limit: Maximum number of logs to retrieve (default: 20)
    ///   - completion: Callback with array of session logs and optional error
    func getSessionLogsForUser(userId: String, limit: Int = 20, completion: @escaping ([SessionLog], Error?) -> Void) {
        db.collection("sessionLogs")
            .whereField("userId", isEqualTo: userId)
            .order(by: "endTime", descending: true)
            .limit(to: limit)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion([], error)
                    return
                }
                guard let documents = snapshot?.documents else {
                    completion([], nil)
                    return
                }
                let sessionLogs = documents.compactMap { SessionLog(document: $0) }
                completion(sessionLogs, nil)
            }
    }
    
    /// Fetch session logs for a user within a date range
    /// - Parameters:
    ///   - userId: The user ID
    ///   - startDate: Start date (inclusive)
    ///   - endDate: End date (inclusive)
    ///   - completion: Completion handler with Result containing array of SessionLog or Error
    func fetchSessionLogs(forUserId userId: String, from startDate: Date, to endDate: Date, completion: @escaping (Result<[SessionLog], Error>) -> Void) {
        // Make sure end date includes the entire day
        let calendar = Calendar.current
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate
        
        db.collection(Collection.logs)
            .whereField("userId", isEqualTo: userId)
            .whereField("startTime", isGreaterThanOrEqualTo: startDate)
            .whereField("startTime", isLessThanOrEqualTo: endOfDay)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let sessionLogs = documents.compactMap { SessionLog(document: $0) }
                completion(.success(sessionLogs))
            }
    }
    
    // MARK: - Initialization
    
    private init() {
        // Explicitly enforce secure (TLS) communication
        let settings = db.settings
#if canImport(FirebaseFirestore)
        // Although enabled by default, set explicitly for clarity/compliance audits.
        settings.isSSLEnabled = true
#endif
        db.settings = settings
    }
    
    // MARK: - User Operations
    
    /// Retrieves a user by ID
    /// - Parameters:
    ///   - userId: The ID of the user to retrieve
    ///   - completion: Completion handler with optional User and Error
    func getUser(userId: String, completion: @escaping (User?, Error?) -> Void) {
        let docRef = db.collection(Collection.users).document(userId)
        
        docRef.getDocument { (document, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let document = document, document.exists else {
                completion(nil, NSError(domain: "FirestoreService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"]))
                return
            }
            
            if let user = User(document: document) {
                completion(user, nil)
            } else {
                completion(nil, NSError(domain: "FirestoreService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to parse user data"]))
            }
        }
    }
    
    /// Creates or updates a user in Firestore
    /// - Parameters:
    ///   - user: The user to save
    ///   - completion: Completion handler with optional Error
    func saveUser(user: User, completion: @escaping (Error?) -> Void) {
        let docRef = db.collection(Collection.users).document(user.id)
        
        docRef.setData(user.toFirestoreData()) { error in
            completion(error)
        }
    }
    
    // MARK: - Growth Method Operations
    
    /// Retrieves a growth method by ID
    /// - Parameters:
    ///   - methodId: The ID of the growth method to retrieve
    ///   - completion: Completion handler with optional GrowthMethod and Error
    func getGrowthMethod(methodId: String, completion: @escaping (Growth.GrowthMethod?, Error?) -> Void) {
        let docRef = db.collection(Collection.methods).document(methodId)
        
        docRef.getDocument { (document, error) in
            if let error = error {
                completion(nil as Growth.GrowthMethod?, error)
                return
            }
            
            guard let document = document, document.exists else {
                completion(nil, NSError(domain: "FirestoreService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Growth method not found"]))
                return
            }
            
            if let method = Growth.GrowthMethod(document: document) {
                completion(method, nil)
            } else {
                completion(nil, NSError(domain: "FirestoreService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to parse growth method data"]))
            }
        }
    }
    
    /// Retrieves all growth methods
    /// - Parameter completion: Completion handler with array of Growth.GrowthMethod and optional Error
    func getAllGrowthMethods(completion: @escaping ([Growth.GrowthMethod], Error?) -> Void) {
        db.collection(Collection.methods)
            .order(by: "stage")
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    completion([], error)
                    return
                }
                
                var methods: [Growth.GrowthMethod] = []
                
                for document in querySnapshot?.documents ?? [] {
                    if let method = Growth.GrowthMethod(document: document) {
                        methods.append(method)
                    }
                }
                
                completion(methods, nil)
            }
    }
    
    /// Retrieves growth methods by stage
    /// - Parameters:
    ///   - stage: The stage to filter by
    ///   - completion: Completion handler with array of Growth.GrowthMethod and optional Error
    func getGrowthMethodsByStage(stage: Int, completion: @escaping ([Growth.GrowthMethod], Error?) -> Void) {
        db.collection(Collection.methods)
            .whereField("stage", isEqualTo: stage)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    completion([], error)
                    return
                }
                
                var methods: [Growth.GrowthMethod] = []
                
                for document in querySnapshot?.documents ?? [] {
                    if let method = Growth.GrowthMethod(document: document) {
                        methods.append(method)
                    }
                }
                
                completion(methods, nil)
            }
    }
    
    // MARK: - Session Log Operations
    
    /// Retrieves a session log by ID
    /// - Parameters:
    ///   - logId: The ID of the session log to retrieve
    ///   - completion: Completion handler with optional SessionLog and Error
    func getSessionLog(logId: String, completion: @escaping (SessionLog?, Error?) -> Void) {
        let docRef = db.collection(Collection.logs).document(logId)
        
        docRef.getDocument { (document, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let document = document, document.exists else {
                completion(nil, NSError(domain: "FirestoreService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Session log not found"]))
                return
            }
            
            if let log = SessionLog(snapshot: document) {
                completion(log, nil)
            } else {
                completion(nil, NSError(domain: "FirestoreService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to parse session log data"]))
            }
        }
    }
    
    /// Retrieves session logs for a specific date range
    /// - Parameters:
    ///   - userId: The ID of the user
    ///   - startDate: The start date of the range
    ///   - endDate: The end date of the range
    ///   - completion: Callback with array of session logs and optional error
    func getSessionLogsForDateRange(userId: String, startDate: Date, endDate: Date, completion: @escaping ([SessionLog], Error?) -> Void) {
        db.collection("sessionLogs")
            .whereField("userId", isEqualTo: userId)
            .whereField("endTime", isGreaterThanOrEqualTo: startDate)
            .whereField("endTime", isLessThanOrEqualTo: endDate)
            .order(by: "endTime", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion([], error)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion([], nil)
                    return
                }
                
                let sessionLogs = documents.compactMap { SessionLog(document: $0) }
                completion(sessionLogs, nil)
            }
    }
    
    // MARK: - Badge Operations
    
    /// Retrieves all badge definitions
    /// - Parameter completion: Completion handler with array of Badge and optional Error
    func getAllBadges(completion: @escaping ([Badge], Error?) -> Void) {
        db.collection(Collection.badges)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    completion([], error)
                    return
                }
                
                var badges: [Badge] = []
                
                for document in querySnapshot?.documents ?? [] {
                    if let badge = Badge(document: document) {
                        badges.append(badge)
                    }
                }
                
                completion(badges, nil)
            }
    }
    
    /// Retrieves a specific badge by ID
    /// - Parameters:
    ///   - badgeId: The ID of the badge to retrieve
    ///   - completion: Completion handler with optional Badge and Error
    func getBadge(badgeId: String, completion: @escaping (Badge?, Error?) -> Void) {
        let docRef = db.collection(Collection.badges).document(badgeId)
        
        docRef.getDocument { (document, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let document = document, document.exists else {
                completion(nil, NSError(domain: "FirestoreService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Badge not found"]))
                return
            }
            
            if let badge = Badge(document: document) {
                completion(badge, nil)
            } else {
                completion(nil, NSError(domain: "FirestoreService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to parse badge data"]))
            }
        }
    }
    
    /// Creates or updates a badge in Firestore
    /// - Parameters:
    ///   - badge: The badge to save
    ///   - completion: Completion handler with optional Error
    func saveBadge(badge: Badge, completion: @escaping (Error?) -> Void) {
        let docRef = db.collection(Collection.badges).document(badge.id)
        
        docRef.setData(badge.toFirestore) { error in
            completion(error)
        }
    }
    
    /// Retrieves badges earned by a user
    /// - Parameters:
    ///   - userId: The ID of the user
    ///   - completion: Completion handler with array of Badge and optional Error
    func getUserBadges(userId: String, completion: @escaping ([Badge], Error?) -> Void) {
        // First get the user's earned badge IDs
        let userRef = db.collection(Collection.users).document(userId)
        
        userRef.getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            
            if let error = error {
                completion([], error)
                return
            }
            
            guard let document = document, document.exists else {
                completion([], NSError(domain: "FirestoreService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"]))
                return
            }
            
            let userData = document.data() ?? [:]
            let earnedBadgeIds = userData["earnedBadges"] as? [String] ?? []
            
            if earnedBadgeIds.isEmpty {
                completion([], nil)
                return
            }
            
            // Then fetch the badge details for each earned badge
            let badgesRef = self.db.collection(Collection.badges)
                .whereField(FieldPath.documentID(), in: earnedBadgeIds)
            
            badgesRef.getDocuments { (querySnapshot, error) in
                if let error = error {
                    completion([], error)
                    return
                }
                
                var badges: [Badge] = []
                
                for document in querySnapshot?.documents ?? [] {
                    if var badge = Badge(document: document) {
                        // Set the earned date if available
                        if let userEarnedBadges = userData["earnedBadgesData"] as? [String: [String: Any]],
                           let badgeData = userEarnedBadges[badge.id],
                           let earnedTimestamp = badgeData["earnedDate"] as? Timestamp {
                            badge.earnedDate = earnedTimestamp.dateValue()
                        } else {
                            badge.earnedDate = Date() // Default to now if no date is found
                        }
                        
                        badges.append(badge)
                    }
                }
                
                completion(badges, nil)
            }
        }
    }
    
    /// Award a badge to a user
    /// - Parameters:
    ///   - userId: The ID of the user
    ///   - badgeId: The ID of the badge to award
    ///   - completion: Completion handler with optional Error
    func awardBadgeToUser(userId: String, badgeId: String, completion: @escaping (Error?) -> Void) {
        let userRef = db.collection(Collection.users).document(userId)
        
        // Transaction to ensure badge is only awarded once
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let document: DocumentSnapshot
            do {
                document = try transaction.getDocument(userRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            if !document.exists {
                let error = NSError(domain: "FirestoreService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
                errorPointer?.pointee = error
                return nil
            }
            
            // Get existing earned badges or initialize empty array
            let userData = document.data() ?? [:]
            var earnedBadgeIds = userData["earnedBadges"] as? [String] ?? []
            
            // Check if badge is already earned
            if earnedBadgeIds.contains(badgeId) {
                // Badge already earned, nothing to do
                return nil
            }
            
            // Add badge to earned badges
            earnedBadgeIds.append(badgeId)
            
            // Get or initialize the earned badges data dictionary
            var earnedBadgesData = userData["earnedBadgesData"] as? [String: [String: Any]] ?? [:]
            
            // Set the earned date for this badge
            earnedBadgesData[badgeId] = [
                "earnedDate": FieldValue.serverTimestamp()
            ]
            
            // Update the user document
            transaction.updateData([
                "earnedBadges": earnedBadgeIds,
                "earnedBadgesData": earnedBadgesData
            ], forDocument: userRef)
            
            return nil
        }) { (_, error) in
            completion(error)
        }
    }
    
    /// Check if user has earned a specific badge
    /// - Parameters:
    ///   - userId: The ID of the user
    ///   - badgeId: The ID of the badge to check
    ///   - completion: Completion handler with boolean result and optional Error
    func hasUserEarnedBadge(userId: String, badgeId: String, completion: @escaping (Bool, Error?) -> Void) {
        let userRef = db.collection(Collection.users).document(userId)
        
        userRef.getDocument { (document, error) in
            if let error = error {
                completion(false, error)
                return
            }
            
            guard let document = document, document.exists else {
                completion(false, NSError(domain: "FirestoreService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"]))
                return
            }
            
            let userData = document.data() ?? [:]
            let earnedBadgeIds = userData["earnedBadges"] as? [String] ?? []
            
            completion(earnedBadgeIds.contains(badgeId), nil)
        }
    }
    
    /// Creates a new session log in Firestore
    /// - Parameters:
    ///   - log: The session log to save
    ///   - completion: Completion handler with optional Error
    func saveSessionLog(log: SessionLog, completion: @escaping (Error?) -> Void) {
        let docRef = db.collection(Collection.logs).document(log.id)
        
        docRef.setData(log.toFirestoreData()) { error in
            completion(error)
        }
    }
    
    /// Deletes a session log from Firestore
    /// - Parameters:
    ///   - logId: The ID of the session log to delete.
    ///   - completion: Completion handler with optional Error.
    func deleteSessionLog(logId: String, completion: @escaping (Error?) -> Void) {
        let docRef = db.collection(Collection.logs).document(logId)
        docRef.delete {
            completion($0)
        }
    }
    
    // MARK: - Educational Resource Operations
    
    /// Retrieves an educational resource by ID
    /// - Parameters:
    ///   - resourceId: The ID of the educational resource to retrieve
    ///   - completion: Completion handler with optional EducationalResource and Error
    func getEducationalResource(resourceId: String, completion: @escaping (EducationalResource?, Error?) -> Void) {
        guard !resourceId.isEmpty else {
            Logger.info("Error: getEducationalResource called with empty resourceId.")
            completion(nil, NSError(domain: "FirestoreService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Resource ID cannot be empty."]))
            return
        }
        
        let docRef = db.collection(Collection.resources).document(resourceId)
        
        docRef.getDocument { (document, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let document = document, document.exists else {
                completion(nil, NSError(domain: "FirestoreService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Educational resource not found"]))
                return
            }
            
            // Assuming EducationalResource is Codable and has @DocumentID for its id field
            do {
                let resource = try document.data(as: EducationalResource.self)
                completion(resource, nil)
            } catch {
                completion(nil, error) // Pass the decoding error
            }
        }
    }
    
    /// Retrieves all educational resources, ordered by title.
    /// - Parameter completion: Completion handler with a Result containing an array of EducationalResource or an Error.
    func getAllEducationalResources(completion: @escaping (Result<[EducationalResource], Error>) -> Void) {
        Logger.info("🔍 FirestoreService: Starting getAllEducationalResources request")
        Logger.info("📱 Current user: \(Auth.auth().currentUser?.uid ?? "none")")
        Logger.info("📱 User authenticated: \(Auth.auth().currentUser != nil)")
        
        // Define the allowed articles for the Learn tab
        let allowedArticleTitles = [
            "Beginner's Guide to The Angion Method: Unlocking Your Growth Potential",
            "Preparing for Angion: Foundations for Health and Growth",
            "Intermediate Angion: Mastering the Angion Method 2.0",
            "Intermediate Angion: Cardiovascular Training for Organ Building",
            "Advanced Angion: The Vascion (Angion Method 3.0) – Apex of Male Enhancement",
            "The Angion Method – An Evolving Approach to Male Vascular Health and Growth",
            "The Core Mechanisms of Blood Vessel Growth: Glycocalyx, Shear Stress, and Smooth Muscles",
            "Holistic Male Sexual Health and Growth: Diet, Exercise, and Lifestyle"
        ]
        
        db.collection(Collection.resources)
            .order(by: "title") // Optionally order by title, or another relevant field
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    Logger.info("❌ FirestoreService: Query failed with error: \(error)")
                    Logger.info("❌ Error code: \((error as NSError).code)")
                    Logger.info("❌ Error domain: \((error as NSError).domain)")
                    Logger.info("❌ Error description: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }

                guard let querySnapshot = querySnapshot else {
                    Logger.info("❌ FirestoreService: Query snapshot was nil")
                    // This case should ideally be covered by the error above, but as a safeguard:
                    completion(.failure(NSError(domain: "FirestoreService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Query snapshot was nil."])))
                    return
                }

                Logger.info("✅ FirestoreService: Query successful, got \(querySnapshot.documents.count) documents")

                let resources = querySnapshot.documents.compactMap { document -> EducationalResource? in
                    do {
                        var resource = try document.data(as: EducationalResource.self)
                        // Explicitly assign the document ID, even though @DocumentID should handle it.
                        // This is a fallback/debugging step.
                        resource.id = document.documentID
                        
                        // Filter to only include allowed articles for the Learn tab
                        if allowedArticleTitles.contains(resource.title) {
                            return resource
                        } else {
                            Logger.info("📋 Filtering out article: \(resource.title)")
                            return nil
                        }
                    } catch {
                        Logger.info("❌ Error decoding educational resource \(document.documentID): \(error.localizedDescription)")
                        return nil // If decoding fails, exclude this item
                    }
                }
                
                Logger.info("✅ FirestoreService: Successfully decoded \(resources.count) resources after filtering")
                completion(.success(resources))
            }
    }
    
    /// Retrieves educational resources by category
    /// - Parameters:
    ///   - category: The category to filter by
    ///   - completion: Completion handler with array of EducationalResource and optional Error
    func getEducationalResourcesByCategory(category: ResourceCategory, completion: @escaping ([EducationalResource], Error?) -> Void) {
        db.collection(Collection.resources)
            .whereField("category", isEqualTo: category.rawValue)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    completion([], error)
                    return
                }
                
                var resources: [EducationalResource] = []
                
                for document in querySnapshot?.documents ?? [] {
                    if let resource = EducationalResource(document: document) {
                        resources.append(resource)
                    }
                }
                
                completion(resources, nil)
            }
    }
    
    // MARK: - Push Notification Methods
    
    /// Store a device token in Firestore for the specified user
    /// - Parameters:
    ///   - userId: The ID of the user
    ///   - token: The device token to store
    ///   - completion: Callback with an optional error
    func storeDeviceToken(userId: String, token: String, completion: @escaping (Error?) -> Void) {
        let deviceTokenData: [String: Any] = [
            "token": token,
            "platform": "iOS",
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        // Store in the user's device tokens collection
        db.collection("users").document(userId)
            .collection("deviceTokens").document(token)
            .setData(deviceTokenData) { error in
                completion(error)
            }
    }
    
    /// Update notification preferences for a user
    /// - Parameters:
    ///   - userId: The ID of the user
    ///   - preferences: The notification preferences to save
    ///   - completion: Callback with an optional error
    func updateNotificationPreferences(userId: String, preferences: NotificationPreferences, completion: @escaping (Error?) -> Void) {
        db.collection("users").document(userId)
            .collection("settings").document("notifications")
            .setData(preferences.toFirestore, merge: true) { error in
                completion(error)
            }
    }
    
    /// Fetch notification preferences for a user
    /// - Parameters:
    ///   - userId: The ID of the user
    ///   - completion: Callback with the retrieved preferences and an optional error
    func fetchNotificationPreferences(userId: String, completion: @escaping (NotificationPreferences?, Error?) -> Void) {
        db.collection("users").document(userId)
            .collection("settings").document("notifications")
            .getDocument { snapshot, error in
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                guard let snapshot = snapshot, snapshot.exists else {
                    // Return default preferences if no document exists
                    completion(NotificationPreferences(), nil)
                    return
                }
                
                let preferences = NotificationPreferences(document: snapshot)
                completion(preferences, nil)
            }
    }
    
    /// Save notification schedule preference for a specific notification type
    /// - Parameters:
    ///   - userId: The user ID
    ///   - type: The notification type identifier
    ///   - data: Preference data to save
    ///   - completion: Completion handler with optional error
    func saveNotificationSchedulePreference(userId: String, type: String, data: [String: Any], completion: @escaping (Error?) -> Void) {
        db.collection("users").document(userId)
            .collection("settings").document("notifications")
            .collection("schedules").document(type)
            .setData(data, merge: true) { error in
                completion(error)
            }
    }
    
    /// Fetch notification schedule preferences for a user
    /// - Parameters:
    ///   - userId: The user ID
    ///   - completion: Completion handler with preferences dictionary and optional error
    func fetchNotificationSchedulePreferences(userId: String, completion: @escaping ([String: [String: Any]]?, Error?) -> Void) {
        db.collection("users").document(userId)
            .collection("settings").document("notifications")
            .collection("schedules")
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    completion([:], nil)
                    return
                }
                
                var preferences: [String: [String: Any]] = [:]
                
                for document in documents {
                    preferences[document.documentID] = document.data()
                }
                
                completion(preferences, nil)
            }
    }
    
    // MARK: - Progression Events
    /// Saves a progression event to Firestore under `progressionEvents` collection.
    func saveProgressionEvent(_ event: ProgressionEvent, completion: @escaping (Error?) -> Void) {
        let collection = db.collection("progressionEvents")
        let docRef: DocumentReference
        if let id = event.id {
            docRef = collection.document(id)
        } else {
            docRef = collection.document()
        }
        docRef.setData(event.firestoreData) { error in
            completion(error)
        }
    }

    /// Fetches the last progression event for a user + method.
    func getLatestProgressionEvent(userId: String, methodId: String, completion: @escaping (ProgressionEvent?, Error?) -> Void) {
        db.collection("progressionEvents")
            .whereField("userId", isEqualTo: userId)
            .whereField("methodId", isEqualTo: methodId)
            .order(by: "timestamp", descending: true)
            .limit(to: 1)
            .getDocuments { snap, error in
                if let error = error {
                    completion(nil, error)
                    return
                }
                guard let doc = snap?.documents.first else {
                    completion(nil, nil)
                    return
                }
                let evt = ProgressionEvent(document: doc)
                completion(evt, nil)
            }
    }

    /// Fetches progression events for the given user. If `methodId` is provided, results are filtered to that method.
    func getProgressionEvents(userId: String, methodId: String? = nil, limit: Int = 100, completion: @escaping ([ProgressionEvent], Error?) -> Void) {
        var query: Query = db.collection("progressionEvents")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: false)
            .limit(to: limit)
        if let methodId = methodId {
            query = query.whereField("methodId", isEqualTo: methodId)
        }
        query.getDocuments { snap, error in
            if let error = error {
                completion([], error)
                return
            }
            let events = snap?.documents.compactMap { ProgressionEvent(document: $0) } ?? []
            completion(events, nil)
        }
    }
} 