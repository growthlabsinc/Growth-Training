import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
class CommunityRoutineViewModel: ObservableObject {
    @Published var creator: User?
    @Published var isVerifiedCreator = false
    @Published var averageRating: Double = 0.0
    @Published var totalRatings: Int = 0
    @Published var downloadCount: Int = 0
    @Published var activeUsers: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private let userService = UserService.shared
    private let routineService = RoutineService.shared
    
    var routinesViewModel: RoutinesViewModel?
    
    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
    
    // MARK: - Load Routine Details
    
    func loadRoutineDetails(_ routine: Routine) {
        Task {
            isLoading = true
            
            // Load creator info
            if let creatorId = routine.createdBy {
                await loadCreatorInfo(creatorId)
            }
            
            // Load routine statistics
            await loadRoutineStats(routine.id)
            
            isLoading = false
        }
    }
    
    private func loadCreatorInfo(_ userId: String) async {
        do {
            let userDoc = try await db.collection("users").document(userId).getDocument()
            if let userData = userDoc.data() {
                await MainActor.run {
                    self.creator = User(
                        id: userId,
                        firstName: userData["firstName"] as? String,
                        creationDate: Date(),
                        lastLogin: Date(),
                        settings: UserSettings(
                            notificationsEnabled: false,
                            reminderTime: nil,
                            privacyLevel: .medium
                        ),
                        username: userData["username"] as? String ?? "unknown",
                        displayName: userData["displayName"] as? String ?? userData["firstName"] as? String ?? "User"
                    )
                    
                    // Check if verified creator (placeholder logic)
                    self.isVerifiedCreator = userData["isVerified"] as? Bool ?? false
                }
            }
        } catch {
            Logger.debug("Error loading creator info: \(error)")
        }
    }
    
    private func loadRoutineStats(_ routineId: String) async {
        do {
            // Load ratings
            let ratingsSnapshot = try await db.collection("routines").document(routineId)
                .collection("ratings").getDocuments()
            
            var totalRating = 0.0
            var ratingCount = 0
            
            for doc in ratingsSnapshot.documents {
                if let rating = doc.data()["rating"] as? Double {
                    totalRating += rating
                    ratingCount += 1
                }
            }
            
            // Load download count
            let statsDoc = try await db.collection("routines").document(routineId)
                .collection("statistics").document("stats").getDocument()
            
            await MainActor.run {
                self.totalRatings = ratingCount
                self.averageRating = ratingCount > 0 ? totalRating / Double(ratingCount) : 0.0
                
                if let statsData = statsDoc.data() {
                    self.downloadCount = statsData["downloads"] as? Int ?? 0
                    self.activeUsers = statsData["activeUsers"] as? Int ?? 0
                }
            }
        } catch {
            Logger.debug("Error loading routine stats: \(error)")
        }
    }
    
    // MARK: - User Actions
    
    func checkIfRoutineSaved(routineId: String, userId: String) async -> Bool {
        do {
            let doc = try await db.collection("users").document(userId)
                .collection("savedRoutines").document(routineId).getDocument()
            return doc.exists
        } catch {
            Logger.debug("Error checking saved routine: \(error)")
            return false
        }
    }
    
    func saveRoutine(_ routine: Routine) async -> Bool {
        guard let userId = currentUserId else { return false }
        
        do {
            // Save to user's collection
            try await db.collection("users").document(userId)
                .collection("savedRoutines").document(routine.id).setData([
                    "routineId": routine.id,
                    "savedAt": Timestamp(date: Date()),
                    "name": routine.name,
                    "createdBy": routine.createdBy ?? "",
                    "isCustom": routine.isCustom ?? false
                ])
            
            // Update download count
            try await incrementDownloadCount(routine.id)
            
            return true
        } catch {
            Logger.debug("Error saving routine: \(error)")
            errorMessage = "Failed to save routine"
            return false
        }
    }
    
    func selectRoutine(_ routine: Routine) async {
        guard let userId = currentUserId else { return }
        
        // Update selected routine in user service
        userService.updateSelectedRoutine(userId: userId, routineId: routine.id)
    }
    
    func getUserRating(routineId: String, userId: String) async -> Int {
        do {
            let doc = try await db.collection("routines").document(routineId)
                .collection("ratings").document(userId).getDocument()
            
            if let data = doc.data(), let rating = data["rating"] as? Int {
                return rating
            }
        } catch {
            Logger.debug("Error getting user rating: \(error)")
        }
        return 0
    }
    
    func rateRoutine(routineId: String, rating: Int) async {
        guard let userId = currentUserId else { return }
        
        do {
            // Save user's rating
            try await db.collection("routines").document(routineId)
                .collection("ratings").document(userId).setData([
                    "rating": rating,
                    "userId": userId,
                    "timestamp": Timestamp(date: Date())
                ])
            
            // Update routine's average rating
            await updateRoutineRating(routineId)
            
        } catch {
            Logger.debug("Error rating routine: \(error)")
            errorMessage = "Failed to submit rating"
        }
    }
    
    func deleteRoutine() {
        // Implementation for deleting user's own routine
        // This would need proper authorization checks
    }
    
    // MARK: - Private Helpers
    
    private func incrementDownloadCount(_ routineId: String) async throws {
        let statsRef = db.collection("routines").document(routineId)
            .collection("statistics").document("stats")
        
        try await statsRef.setData([
            "downloads": FieldValue.increment(Int64(1)),
            "lastDownload": Timestamp(date: Date())
        ], merge: true)
    }
    
    private func updateRoutineRating(_ routineId: String) async {
        do {
            // Recalculate average rating
            let ratingsSnapshot = try await db.collection("routines").document(routineId)
                .collection("ratings").getDocuments()
            
            var totalRating = 0.0
            var ratingCount = 0
            
            for doc in ratingsSnapshot.documents {
                if let rating = doc.data()["rating"] as? Double {
                    totalRating += rating
                    ratingCount += 1
                }
            }
            
            let averageRating = ratingCount > 0 ? totalRating / Double(ratingCount) : 0.0
            
            // Update routine document
            try await db.collection("routines").document(routineId).updateData([
                "averageRating": averageRating,
                "ratingCount": ratingCount
            ])
            
        } catch {
            Logger.debug("Error updating routine rating: \(error)")
        }
    }
}