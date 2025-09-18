import FirebaseFirestore
import Firebase
import FirebaseAuth
import FirebaseFunctions

class UserService {
    static let shared = UserService()
    
    private let db = Firestore.firestore()
    private let usersCollection = "users"
    private let usernamesCollection = "usernames" // For username uniqueness
    func updateSelectedRoutine(userId: String, routineId: String?, completion: ((Error?) -> Void)? = nil) {
        guard !userId.isEmpty else {
            completion?(nil)
            return
        }
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        userRef.updateData(["selectedRoutineId": routineId ?? NSNull()]) { error in
            completion?(error)
        }
    }
    
    /// Update user's practice preference (routine or adhoc)
    func updatePracticePreference(userId: String, practiceMode: String, completion: @escaping (Error?) -> Void) {
        guard !userId.isEmpty else {
            completion(NSError(domain: "UserService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid user ID"]))
            return
        }
        
        let userRef = db.collection(usersCollection).document(userId)
        let updateData: [String: Any] = [
            "preferredPracticeMode": practiceMode,
            "practicePreferenceSetAt": Timestamp(date: Date())
        ]
        
        // First check if document exists
        userRef.getDocument { (document, error) in
            if let error = error {
                Logger.info("UserService: Error checking document existence: \(error)")
                completion(error)
                return
            }
            
            if document?.exists == true {
                // Document exists, update it
                userRef.updateData(updateData) { error in
                    if let error = error {
                        Logger.info("UserService: Error updating practice preference: \(error)")
                    } else {
                        Logger.info("UserService: Successfully updated practice preference to '\(practiceMode)'")
                    }
                    completion(error)
                }
            } else {
                // Document doesn't exist, create it with minimal data
                var userData: [String: Any] = [
                    "userId": userId,
                    "creationDate": Timestamp(date: Date()),
                    "lastLogin": Timestamp(date: Date())
                ]
                
                // Merge practice preference data
                userData.merge(updateData) { (_, new) in new }
                
                userRef.setData(userData) { error in
                    if let error = error {
                        Logger.info("UserService: Error creating user document with practice preference: \(error)")
                    } else {
                        Logger.info("UserService: Successfully created user document with practice preference")
                    }
                    completion(error)
                }
            }
        }
    }
    
    /// Update user's initial assessment results
    func updateInitialAssessment(userId: String, assessmentResult: String, methodId: String, completion: @escaping (Error?) -> Void) {
        guard !userId.isEmpty else {
            completion(NSError(domain: "UserService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid user ID"]))
            return
        }
        
        let userRef = db.collection(usersCollection).document(userId)
        let updateData: [String: Any] = [
            "initialAssessmentResult": assessmentResult,
            "initialMethodId": methodId,
            "initialAssessmentDate": Timestamp(date: Date())
        ]
        
        // First check if document exists
        userRef.getDocument { (document, error) in
            if let error = error {
                Logger.info("UserService: Error checking document existence: \(error)")
                completion(error)
                return
            }
            
            if document?.exists == true {
                // Document exists, update it
                userRef.updateData(updateData) { error in
                    if let error = error {
                        Logger.info("UserService: Error updating initial assessment: \(error)")
                    } else {
                        Logger.info("UserService: Successfully updated initial assessment")
                    }
                    completion(error)
                }
            } else {
                // Document doesn't exist, create it with minimal data
                var userData: [String: Any] = [
                    "userId": userId,
                    "creationDate": Timestamp(date: Date()),
                    "lastLogin": Timestamp(date: Date())
                ]
                
                // Merge assessment data
                userData.merge(updateData) { (_, new) in new }
                
                userRef.setData(userData) { error in
                    if let error = error {
                        Logger.info("UserService: Error creating user document with assessment: \(error)")
                    } else {
                        Logger.info("UserService: Successfully created user document with assessment")
                    }
                    completion(error)
                }
            }
        }
    }

    func fetchSelectedRoutineId(userId: String, completion: @escaping (String?) -> Void) {
        guard !userId.isEmpty else {
            completion(nil)
            return
        }
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        userRef.getDocument { snapshot, error in
            if let data = snapshot?.data(), let routineId = data["selectedRoutineId"] as? String {
                completion(routineId)
            } else {
                completion(nil)
            }
        }
    }
    
    /// Fetch user data from Firestore
    func fetchUser(userId: String, completion: @escaping (Result<User, Error>) -> Void) {
        guard !userId.isEmpty else {
            completion(.failure(NSError(domain: "UserService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid user ID"])))
            return
        }
        
        let userRef = db.collection(usersCollection).document(userId)
        userRef.getDocument { snapshot, error in
            // Handle Firebase errors
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Check for valid snapshot
            guard let snapshot = snapshot else {
                completion(.failure(NSError(domain: "UserService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No snapshot returned from Firebase"])))
                return
            }
            
            // Check if document exists
            guard snapshot.exists else {
                completion(.failure(NSError(domain: "UserService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User document not found"])))
                return
            }
            
            // Safely attempt to create User from document
            guard let user = User(document: snapshot) else {
                // Log the document data for debugging
                if let data = snapshot.data() {
                    Logger.error("UserService: Failed to parse user data for userId: \(userId), data keys: \(Array(data.keys))")
                } else {
                    Logger.error("UserService: No data in document for userId: \(userId)")
                }
                completion(.failure(NSError(domain: "UserService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse user data from document"])))
                return
            }
            
            completion(.success(user))
        }
    }
    
    /// Update user's first name
    func updateFirstName(userId: String, firstName: String, completion: @escaping (Error?) -> Void) {
        guard !userId.isEmpty else {
            completion(NSError(domain: "UserService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid user ID"]))
            return
        }
        
        let userRef = db.collection(usersCollection).document(userId)
        
        // First check if document exists
        userRef.getDocument { (document, error) in
            if let error = error {
                Logger.info("UserService: Error checking document existence: \(error)")
                completion(error)
                return
            }
            
            if document?.exists == true {
                // Document exists, update it
                userRef.updateData(["firstName": firstName]) { error in
                    if let error = error {
                        Logger.info("UserService: Error updating firstName: \(error)")
                    } else {
                        Logger.info("UserService: Successfully updated firstName to '\(firstName)'")
                    }
                    completion(error)
                }
            } else {
                // Document doesn't exist, create it with minimal data
                let userData: [String: Any] = [
                    "userId": userId,
                    "firstName": firstName,
                    "creationDate": Timestamp(date: Date()),
                    "lastLogin": Timestamp(date: Date())
                ]
                
                userRef.setData(userData) { error in
                    if let error = error {
                        Logger.info("UserService: Error creating user document: \(error)")
                    } else {
                        Logger.info("UserService: Successfully created user document with firstName '\(firstName)'")
                    }
                    completion(error)
                }
            }
        }
    }
    
    /// Update multiple user fields
    func updateUserFields(userId: String, fields: [String: Any], completion: @escaping (Error?) -> Void) {
        guard !userId.isEmpty else {
            completion(NSError(domain: "UserService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid user ID"]))
            return
        }
        
        let userRef = db.collection(usersCollection).document(userId)
        userRef.updateData(fields) { error in
            completion(error)
        }
    }
    
    // MARK: - App Tour Methods
    
    /// Check if user should see the app tour
    func shouldShowAppTour(userId: String, completion: @escaping (Bool) -> Void) {
        guard !userId.isEmpty else {
            completion(false)
            return
        }
        
        let userRef = db.collection(usersCollection).document(userId)
        userRef.getDocument { (document, error) in
            if error != nil {
                completion(false)
                return
            }
            
            guard let data = document?.data() else {
                completion(true) // New user, show tour
                return
            }
            
            let hasSeenTour = data["hasSeenAppTour"] as? Bool ?? false
            let hasCompletedTour = data["hasCompletedAppTour"] as? Bool ?? false
            
            completion(!hasSeenTour && !hasCompletedTour)
        }
    }
    
    /// Mark that user has started the app tour
    func markAppTourStarted(userId: String, completion: ((Error?) -> Void)? = nil) {
        updateUserFields(userId: userId, fields: [
            "hasSeenAppTour": true
        ], completion: completion ?? { _ in })
    }
    
    /// Mark that user has completed the app tour
    func markAppTourCompleted(userId: String, completion: ((Error?) -> Void)? = nil) {
        updateUserFields(userId: userId, fields: [
            "hasCompletedAppTour": true,
            "hasSeenAppTour": true,
            "tourCompletedAt": Timestamp(date: Date())
        ], completion: completion ?? { _ in })
    }
    
    /// Mark that user has skipped the app tour
    func markAppTourSkipped(userId: String, completion: ((Error?) -> Void)? = nil) {
        updateUserFields(userId: userId, fields: [
            "hasSeenAppTour": true,
            "hasSkippedAppTour": true,
            "tourSkippedAt": Timestamp(date: Date())
        ], completion: completion ?? { _ in })
    }
    
    // MARK: - Username Management
    
    /// Check if a username is available
    /// - Parameters:
    ///   - username: The username to check
    /// - Returns: True if available, false if taken
    func checkUsernameAvailability(_ username: String) async throws -> Bool {
        let lowercaseUsername = username.lowercased()
        
        // Basic validation - check format first
        let usernameRegex = "^[a-zA-Z0-9_]{3,20}$"
        let usernamePredicate = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
        
        if !usernamePredicate.evaluate(with: lowercaseUsername) {
            throw NSError(domain: "UserService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid username format"])
        }
        
        // Call Firebase Function to check username availability
        do {
            let functions = Functions.functions()
            let callable = functions.httpsCallable("checkUsernameAvailability")
            
            let result = try await callable.call(["username": lowercaseUsername])
            
            if let data = result.data as? [String: Any],
               let available = data["available"] as? Bool {
                return available
            } else {
                // If we can't parse the response, assume username is taken for safety
                Logger.error("UserService: Invalid response from checkUsernameAvailability function")
                return false
            }
        } catch {
            Logger.error("UserService: Error calling checkUsernameAvailability function: \(error)")
            // If the function fails, we should still allow the user to proceed
            // The server will validate again during account creation
            throw NSError(domain: "UserService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to verify username availability. Please try again."])
        }
    }
    
    /// Update user's username
    /// - Parameters:
    ///   - userId: The user's ID
    ///   - username: The new username
    ///   - displayName: The display name
    func updateUsername(_ username: String, displayName: String, userId: String? = nil) async throws {
        guard let userId = userId ?? Auth.auth().currentUser?.uid else {
            throw NSError(domain: "UserService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user ID available"])
        }
        
        // Check availability first
        let isAvailable = try await checkUsernameAvailability(username)
        guard isAvailable else {
            throw NSError(domain: "UserService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Username is already taken"])
        }
        
        // Update user document
        try await db.collection(usersCollection).document(userId).updateData([
            "username": username.lowercased(),
            "displayName": displayName
        ])
    }
    
    // MARK: - Block User
    
    /// Block a user from seeing their content
    func blockUser(userId: String, blockedBy: String) async throws {
        guard !userId.isEmpty && !blockedBy.isEmpty else {
            throw NSError(domain: "UserService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid user IDs"])
        }
        
        // Add to the current user's blocked list
        let userRef = db.collection(usersCollection).document(blockedBy)
        
        try await userRef.updateData([
            "blockedUsers": FieldValue.arrayUnion([userId]),
            "lastUpdated": Timestamp(date: Date())
        ])
        
        Logger.info("UserService: User \(userId) blocked by \(blockedBy)")
    }
    
    /// Unblock a user
    func unblockUser(userId: String, unblockedBy: String) async throws {
        guard !userId.isEmpty && !unblockedBy.isEmpty else {
            throw NSError(domain: "UserService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid user IDs"])
        }
        
        // Remove from the current user's blocked list
        let userRef = db.collection(usersCollection).document(unblockedBy)
        
        try await userRef.updateData([
            "blockedUsers": FieldValue.arrayRemove([userId]),
            "lastUpdated": Timestamp(date: Date())
        ])
        
        Logger.info("UserService: User \(userId) unblocked by \(unblockedBy)")
    }
    
    /// Get list of blocked users for filtering
    func getBlockedUsers(for userId: String) async throws -> [String] {
        guard !userId.isEmpty else {
            throw NSError(domain: "UserService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid user ID"])
        }
        
        let userDoc = try await db.collection(usersCollection).document(userId).getDocument()
        
        if let data = userDoc.data(),
           let blockedUsers = data["blockedUsers"] as? [String] {
            return blockedUsers
        }
        
        return []
    }
} 