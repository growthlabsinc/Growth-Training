import Foundation
import FirebaseFirestore
import FirebaseAuth

class RoutineService {
    static let shared = RoutineService()
    
    private let db = Firestore.firestore()
    private let routinesCollection = "routines"
    private let usersCollection = "users"
    
    private init() {}

    // Fetch all routines
    func fetchAllRoutines(completion: @escaping (Result<[Routine], Error>) -> Void) {
        
        db.collection(routinesCollection).getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let documents = snapshot?.documents else {
                completion(.success([]))
                return
            }
            
            
            var routines: [Routine] = []
            var failedRoutines: [(String, Error)] = []
            
            for doc in documents {
                do {
                    let routine = try doc.data(as: Routine.self)
                    routines.append(routine)
                    
                } catch {
                    failedRoutines.append((doc.documentID, error))
                    
                }
            }
            
            completion(.success(routines))
        }
    }
    
    // Fetch only standard (non-custom) routines
    func fetchStandardRoutines(completion: @escaping (Result<[Routine], Error>) -> Void) {
        
        db.collection(routinesCollection)
            .whereField("isCustom", isEqualTo: false)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                
                var routines: [Routine] = []
                var failedRoutines: [(String, Error)] = []
                
                for doc in documents {
                    do {
                        let routine = try doc.data(as: Routine.self)
                        routines.append(routine)
                        
                    } catch {
                        failedRoutines.append((doc.documentID, error))
                        
                    }
                }
                
                completion(.success(routines))
            }
    }
    
    // Fetch community-shared custom routines
    func fetchCommunityRoutines(completion: @escaping (Result<[Routine], Error>) -> Void) {
        // Get current user's blocked list first
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            // No user logged in, just fetch all community routines
            fetchAllCommunityRoutines(completion: completion)
            return
        }
        
        Task {
            do {
                let blockedUsers = try await UserService.shared.getBlockedUsers(for: currentUserId)
                
                do {
                    let snapshot = try await db.collection(routinesCollection)
                        .whereField("isCustom", isEqualTo: true)
                        .whereField("shareWithCommunity", isEqualTo: true)
                        .getDocuments()
                    
                    let documents = snapshot.documents
                    
                    let routines: [Routine] = documents.compactMap { doc in
                        guard let routine = try? doc.data(as: Routine.self) else { return nil }
                        
                        // Filter out blocked creators
                        if let creatorId = routine.createdBy,
                           blockedUsers.contains(creatorId) {
                            return nil
                        }
                        
                        return routine
                    }.sorted { $0.createdAt > $1.createdAt }
                    
                    completion(.success(routines))
                } catch {
                    completion(.failure(error))
                }
            } catch {
                // If we can't get blocked users, just fetch all
                fetchAllCommunityRoutines(completion: completion)
            }
        }
    }
    
    private func fetchAllCommunityRoutines(completion: @escaping (Result<[Routine], Error>) -> Void) {
        db.collection(routinesCollection)
            .whereField("isCustom", isEqualTo: true)
            .whereField("shareWithCommunity", isEqualTo: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                let routines: [Routine] = documents.compactMap { doc in
                    try? doc.data(as: Routine.self)
                }
                completion(.success(routines))
            }
    }

    // Fetch a specific routine by ID
    func fetchRoutine(by id: String, completion: @escaping (Result<Routine, Error>) -> Void) {
        db.collection(routinesCollection).document(id).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let doc = snapshot, doc.exists, let routine = try? doc.data(as: Routine.self) else {
                completion(.failure(NSError(domain: "RoutineService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Routine not found."])))
                return
            }
            completion(.success(routine))
        }
    }
    
    // Fetch a specific routine by ID, checking both main collection and user's custom routines
    func fetchRoutineFromAnySource(by id: String, userId: String?, completion: @escaping (Result<Routine, Error>) -> Void) {
        // If we have a user ID and it's either a custom_ prefixed ID or looks like a UUID, check user's custom routines first
        if let userId = userId, (id.starts(with: "custom_") || (id.contains("-") && id.count == 36)) {
            
            let userRoutineRef = db.collection(usersCollection).document(userId).collection("customRoutines").document(id)
            
            userRoutineRef.getDocument { [weak self] snapshot, error in
                if error != nil {
                    
                    // Fallback to main collection
                    self?.fetchRoutine(by: id, completion: completion)
                    return
                }
                
                if let doc = snapshot, doc.exists, let routine = try? doc.data(as: Routine.self) {
                    
                    completion(.success(routine))
                } else {
                    
                    // Fallback to main collection
                    self?.fetchRoutine(by: id, completion: completion)
                }
            }
        } else {
            // For non-custom routines, use the regular fetch method
            fetchRoutine(by: id, completion: completion)
        }
    }

    // Update user's selected routine
    func updateUserSelectedRoutine(userId: String, routineId: String?, completion: ((Error?) -> Void)? = nil) {
        let userRef = db.collection(usersCollection).document(userId)
        userRef.updateData(["selectedRoutineId": routineId ?? NSNull()]) { error in
            completion?(error)
        }
    }
    
    // Check if a routine name already exists in the community
    func checkCommunityRoutineNameExists(name: String) async throws -> Bool {
        // Trim whitespace and convert to lowercase for case-insensitive comparison
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Query for routines with the same name (case-insensitive)
        let snapshot = try await db.collection(routinesCollection)
            .whereField("isCustom", isEqualTo: true)
            .whereField("shareWithCommunity", isEqualTo: true)
            .getDocuments()
        
        // Check if any routine has the same normalized name
        for document in snapshot.documents {
            if let routineName = document.data()["name"] as? String {
                let normalizedRoutineName = routineName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if normalizedRoutineName == normalizedName {
                    return true
                }
            }
        }
        
        return false
    }
    
    // Save a custom routine
    func saveCustomRoutine(_ routine: Routine, userId: String, shareWithCommunity: Bool = false, entitlementProvider: EntitlementProvider, completion: @escaping (Result<Void, Error>) -> Void) {
        // Feature gating check - Custom Routines require premium or limited free usage
        Task { @MainActor in
            let access = FeatureAccess.from(feature: "customRoutines", using: entitlementProvider)
            
            switch access {
            case .granted:
                // Full access - proceed normally
                self.performSaveCustomRoutine(routine, userId: userId, shareWithCommunity: shareWithCommunity, completion: completion)
                
            case .limited(_):
                // Limited access - check current routine count for free users
                self.checkCustomRoutineLimit(userId: userId) { [weak self] result in
                    switch result {
                    case .success(let count):
                        if count >= 1 { // Free users can create 1 custom routine
                            completion(.failure(RoutineServiceError.customRoutineLimitReached(current: count, limit: 1)))
                            return
                        }
                        // User is within limit, proceed
                        self?.performSaveCustomRoutine(routine, userId: userId, shareWithCommunity: shareWithCommunity, completion: completion)
                        
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
                
            case .denied(let reason):
                // Access denied - return appropriate error
                switch reason {
                case .noSubscription, .insufficientTier:
                    completion(.failure(RoutineServiceError.premiumRequired))
                case .trialExpired:
                    completion(.failure(RoutineServiceError.trialExpired))
                case .usageLimitReached:
                    completion(.failure(RoutineServiceError.customRoutineLimitReached(current: 0, limit: 1)))
                case .featureNotAvailable:
                    completion(.failure(RoutineServiceError.featureUnavailable))
                }
            }
        }
    }
    
    // Helper method to perform the actual save operation
    private func performSaveCustomRoutine(_ routine: Routine, userId: String, shareWithCommunity: Bool = false, completion: @escaping (Result<Void, Error>) -> Void) {
        // Create a user-specific custom routines collection
        let userRoutinesRef = db.collection(usersCollection).document(userId).collection("customRoutines")
        
        // Create a modified routine for user's personal collection
        var personalRoutine = routine
        personalRoutine.createdBy = userId
        personalRoutine.isCustom = true
        
        // Always save as non-shared in user's personal collection so it appears in "Custom" category
        personalRoutine.shareWithCommunity = false
        
        do {
            try userRoutinesRef.document(routine.id).setData(from: personalRoutine) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    // If sharing with community, also try to add to the main routines collection
                    if shareWithCommunity {
                        var communityRoutine = routine
                        communityRoutine.createdBy = userId
                        communityRoutine.isCustom = true
                        communityRoutine.shareWithCommunity = true
                        communityRoutine.moderationStatus = "pending"
                        
                        // Create a dictionary with only the fields we need to save
                        var routineData: [String: Any] = [
                            "id": communityRoutine.id,
                            "name": communityRoutine.name,
                            "description": communityRoutine.description,
                            "difficulty": communityRoutine.difficulty.rawValue,
                            "duration": communityRoutine.duration,
                            "focusAreas": communityRoutine.focusAreas,
                            "stages": communityRoutine.stages,
                            "createdDate": Timestamp(date: communityRoutine.createdDate),
                            "lastUpdated": Timestamp(date: communityRoutine.lastUpdated),
                            "isCustom": true,
                            "createdBy": userId,
                            "shareWithCommunity": true,
                            "moderationStatus": "pending",
                            "tags": communityRoutine.tags
                        ]
                        
                        // Encode schedule manually to ensure proper format
                        let scheduleData = communityRoutine.schedule.map { day -> [String: Any] in
                            let methodsData = day.methods.map { method -> [String: Any] in
                                return [
                                    "id": method.id,
                                    "methodId": method.methodId,
                                    "duration": method.duration,
                                    "order": method.order
                                ]
                            }
                            
                            return [
                                "id": day.id,
                                "day": day.day,
                                "description": day.description,
                                "isRestDay": day.isRestDay,
                                "methods": methodsData,
                                "notes": day.notes
                            ]
                        }
                        routineData["schedule"] = scheduleData
                        
                        self.db.collection(self.routinesCollection).document(routine.id).setData(routineData) { communityError in
                            if let communityError = communityError {
                                Logger.error("⚠️ Failed to share routine with community: \(communityError.localizedDescription)")
                                // Still consider this a success since personal save worked
                            } else {
                                Logger.info("✅ Successfully shared routine with community")
                            }
                        }
                    }
                    
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    // Fetch user's custom routines
    func fetchUserCustomRoutines(userId: String, completion: @escaping (Result<[Routine], Error>) -> Void) {
        let userRoutinesRef = db.collection(usersCollection).document(userId).collection("customRoutines")
        
        userRoutinesRef.getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion(.success([]))
                return
            }
            
            let routines: [Routine] = documents.compactMap { doc in
                try? doc.data(as: Routine.self)
            }
            
            completion(.success(routines))
        }
    }
    
    // MARK: - Community Features
    
    // Fetch community routines with blocking filter (async version)
    func fetchCommunityRoutines(excludeBlockedUsers: [String]) async throws -> [Routine] {
        let query = db.collection(routinesCollection)
            .whereField("isCustom", isEqualTo: true)
            .whereField("shareWithCommunity", isEqualTo: true)
            .whereField("moderationStatus", isEqualTo: "approved")
        
        let snapshot = try await query.getDocuments()
        
        let routines = snapshot.documents.compactMap { doc -> Routine? in
            guard let routine = try? doc.data(as: Routine.self) else { return nil }
            
            // Filter out blocked creators
            if let creatorId = routine.createdBy,
               excludeBlockedUsers.contains(creatorId) {
                return nil
            }
            
            return routine
        }
        
        return routines.sorted { ($0.sharedDate ?? Date.distantPast) > ($1.sharedDate ?? Date.distantPast) }
    }
    
    // Share routine to community
    func shareRoutineWithCommunity(_ routine: Routine, username: String, displayName: String) async throws {
        // Ensure we have the current user's ID
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "RoutineService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        var sharedRoutine = routine
        sharedRoutine.shareWithCommunity = true
        sharedRoutine.creatorUsername = username
        sharedRoutine.creatorDisplayName = displayName
        sharedRoutine.sharedDate = Date()
        sharedRoutine.moderationStatus = "pending"
        sharedRoutine.createdBy = userId // Ensure createdBy is set to current user
        
        // Create a dictionary with only the fields we need to save
        var routineData: [String: Any] = [
            "id": sharedRoutine.id,
            "name": sharedRoutine.name,
            "description": sharedRoutine.description,
            "difficulty": sharedRoutine.difficulty.rawValue,
            "duration": sharedRoutine.duration,
            "focusAreas": sharedRoutine.focusAreas,
            "stages": sharedRoutine.stages,
            "createdDate": Timestamp(date: sharedRoutine.createdDate),
            "lastUpdated": Timestamp(date: sharedRoutine.lastUpdated),
            "isCustom": true,
            "createdBy": userId, // Use the authenticated user ID
            "shareWithCommunity": true,
            "creatorUsername": username,
            "creatorDisplayName": displayName,
            "sharedDate": Timestamp(date: sharedRoutine.sharedDate ?? Date()),
            "moderationStatus": "pending",
            "tags": sharedRoutine.tags
        ]
        
        // Encode schedule manually to ensure proper format
        let scheduleData = sharedRoutine.schedule.map { day -> [String: Any] in
            let methodsData = day.methods.map { method -> [String: Any] in
                return [
                    "id": method.id,
                    "methodId": method.methodId,
                    "duration": method.duration,
                    "order": method.order
                ]
            }
            
            return [
                "id": day.id,
                "day": day.day,
                "description": day.description,
                "isRestDay": day.isRestDay,
                "methods": methodsData,
                "notes": day.notes
            ]
        }
        routineData["schedule"] = scheduleData
        
        // Save to main routines collection
        let docRef = db.collection(routinesCollection).document(routine.id)
        try await docRef.setData(routineData)
        
        // Update user's creator stats
        if let userId = routine.createdBy {
            try await updateCreatorStats(for: userId)
        }
    }
    
    // Report a routine
    func reportRoutine(_ routineId: String, reason: ReportReason, details: String?) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "RoutineService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Get routine details
        let routineDoc = try await db.collection(routinesCollection).document(routineId).getDocument()
        guard let routine = try? routineDoc.data(as: Routine.self) else {
            throw NSError(domain: "RoutineService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Routine not found"])
        }
        
        let report = Report(
            reporterId: userId,
            contentId: routineId,
            contentType: .routine,
            creatorId: routine.createdBy ?? "",
            reason: reason,
            details: details,
            createdAt: Date(),
            status: .pending
        )
        
        // Save report
        try await db.collection("reports").addDocument(data: report.toDictionary())
        
        // Increment report count
        try await db.collection(routinesCollection).document(routineId).updateData([
            "reportCount": FieldValue.increment(Int64(1))
        ])
    }
    
    // Update creator statistics
    private func updateCreatorStats(for userId: String) async throws {
        let userRef = db.collection(usersCollection).document(userId)
        
        // Count shared routines
        let sharedRoutines = try await db.collection(routinesCollection)
            .whereField("createdBy", isEqualTo: userId)
            .whereField("shareWithCommunity", isEqualTo: true)
            .getDocuments()
        
        let routineCount = sharedRoutines.documents.count
        var totalDownloads = 0
        
        for doc in sharedRoutines.documents {
            if let routine = try? doc.data(as: Routine.self) {
                totalDownloads += routine.downloadCount
            }
        }
        
        // Update user document
        try await userRef.updateData([
            "hasCreatedContent": routineCount > 0,
            "creatorStats.routinesShared": routineCount,
            "creatorStats.totalDownloads": totalDownloads,
            "creatorStats.firstSharedDate": routineCount > 0 ? FieldValue.serverTimestamp() : NSNull()
        ])
    }
    
    // Delete custom routine
    func deleteCustomRoutine(routineId: String, userId: String) async throws {
        // Delete from user's custom routines collection
        try await db.collection(usersCollection).document(userId)
            .collection("customRoutines").document(routineId).delete()
        
        // Also delete from main routines collection if it exists there
        let mainRoutineDoc = db.collection(routinesCollection).document(routineId)
        let mainRoutineSnapshot = try await mainRoutineDoc.getDocument()
        
        if mainRoutineSnapshot.exists {
            try await mainRoutineDoc.delete()
        }
    }
    
    // Unshare routine from community
    func unshareRoutineFromCommunity(_ routineId: String) async throws {
        try await db.collection(routinesCollection).document(routineId).updateData([
            "shareWithCommunity": false,
            "moderationStatus": "private",
            "sharedDate": FieldValue.delete()
        ])
    }
    
    // Update custom routine
    func updateCustomRoutine(_ routine: Routine, userId: String) async throws {
        // Ensure user owns this routine
        guard routine.createdBy == userId else {
            throw NSError(domain: "RoutineService", code: 403, userInfo: [NSLocalizedDescriptionKey: "You can only update your own routines"])
        }
        
        // Create routine data dictionary
        var routineData: [String: Any] = [
            "id": routine.id,
            "name": routine.name,
            "description": routine.description,
            "difficulty": routine.difficulty.rawValue,
            "duration": routine.duration,
            "focusAreas": routine.focusAreas,
            "stages": routine.stages,
            "createdDate": Timestamp(date: routine.createdDate),
            "lastUpdated": Timestamp(date: Date()), // Always update to current time
            "isCustom": true,
            "createdBy": userId,
            "shareWithCommunity": routine.shareWithCommunity ?? false,
            "version": routine.version
        ]
        
        // Add community fields if shared
        if routine.shareWithCommunity == true {
            routineData["creatorUsername"] = routine.creatorUsername ?? ""
            routineData["creatorDisplayName"] = routine.creatorDisplayName ?? ""
            if let sharedDate = routine.sharedDate {
                routineData["sharedDate"] = Timestamp(date: sharedDate)
            }
            routineData["moderationStatus"] = routine.moderationStatus
            routineData["tags"] = routine.tags
        }
        
        // Encode schedule manually
        let scheduleData = routine.schedule.map { day -> [String: Any] in
            let methodsData = day.methods.map { method -> [String: Any] in
                return [
                    "id": method.id,
                    "methodId": method.methodId,
                    "duration": method.duration,
                    "order": method.order
                ]
            }
            
            return [
                "id": day.id,
                "day": day.day,
                "description": day.description,
                "isRestDay": day.isRestDay,
                "methods": methodsData,
                "notes": day.notes
            ]
        }
        routineData["schedule"] = scheduleData
        
        // Update in user's custom routines collection
        try await db.collection(usersCollection).document(userId)
            .collection("customRoutines").document(routine.id).setData(routineData)
        
        // Update in main routines collection if shared
        if routine.shareWithCommunity == true {
            try await db.collection(routinesCollection).document(routine.id).setData(routineData)
        } else {
            // If no longer shared, remove from main collection
            let mainRoutineDoc = db.collection(routinesCollection).document(routine.id)
            let mainRoutineSnapshot = try await mainRoutineDoc.getDocument()
            
            if mainRoutineSnapshot.exists {
                try await mainRoutineDoc.delete()
            }
        }
    }
    
    // MARK: - Feature Gating Helpers
    
    /// Check how many custom routines a user has created
    private func checkCustomRoutineLimit(userId: String, completion: @escaping (Result<Int, Error>) -> Void) {
        let userRoutinesRef = db.collection(usersCollection).document(userId).collection("customRoutines")
        
        userRoutinesRef.getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            let count = snapshot?.documents.count ?? 0
            completion(.success(count))
        }
    }
}

// MARK: - Routine Service Errors

/// Error types for routine service operations
enum RoutineServiceError: Error, LocalizedError {
    case premiumRequired
    case trialExpired
    case customRoutineLimitReached(current: Int, limit: Int)
    case featureUnavailable
    
    var errorDescription: String? {
        switch self {
        case .premiumRequired:
            return "Custom routines require a Premium subscription. Upgrade to create unlimited routines."
        case .trialExpired:
            return "Your free trial has expired. Upgrade to Premium to continue creating custom routines."
        case .customRoutineLimitReached(let current, let limit):
            return "You've reached your limit of \(limit) custom routine. Upgrade to Premium for unlimited routines. (Currently: \(current)/\(limit))"
        case .featureUnavailable:
            return "Custom routines are currently unavailable. Please try again later."
        }
    }
    
    /// Whether this error should show an upgrade prompt
    var shouldShowUpgradePrompt: Bool {
        switch self {
        case .premiumRequired, .trialExpired, .customRoutineLimitReached:
            return true
        default:
            return false
        }
    }
} 
