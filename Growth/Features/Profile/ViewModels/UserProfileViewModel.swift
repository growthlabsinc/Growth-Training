import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

@MainActor
class UserProfileViewModel: ObservableObject {
    @Published var bio: String?
    @Published var joinDate: Date?
    @Published var isVerified = false
    @Published var sharedRoutinesCount = 0
    @Published var totalDownloads = 0
    @Published var averageRating: Double = 0.0
    @Published var sharedRoutines: [Routine] = []
    @Published var isLoadingRoutines = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private let routineService = RoutineService.shared
    
    // MARK: - Load Profile
    
    func loadUserProfile(_ user: User) {
        Task {
            await loadUserDetails(user.id)
            await loadUserStats(user.id)
            await loadSharedRoutines(user.id)
        }
    }
    
    private func loadUserDetails(_ userId: String) async {
        do {
            let doc = try await db.collection("users").document(userId).getDocument()
            
            if let data = doc.data() {
                await MainActor.run {
                    self.bio = data["bio"] as? String
                    self.isVerified = data["isVerified"] as? Bool ?? false
                    
                    if let timestamp = data["creationDate"] as? Timestamp {
                        self.joinDate = timestamp.dateValue()
                    }
                }
            }
        } catch {
            Logger.debug("Error loading user details: \(error)")
        }
    }
    
    private func loadUserStats(_ userId: String) async {
        do {
            // Load shared routines count
            let routinesQuery = try await db.collection("routines")
                .whereField("createdBy", isEqualTo: userId)
                .whereField("isPublic", isEqualTo: true)
                .getDocuments()
            
            var totalDownloads = 0
            var totalRating = 0.0
            var ratingCount = 0
            
            // Calculate stats from all routines
            for doc in routinesQuery.documents {
                let data = doc.data()
                
                // Get download count from statistics
                if let statsDoc = try? await db.collection("routines").document(doc.documentID)
                    .collection("statistics").document("stats").getDocument(),
                   let statsData = statsDoc.data() {
                    totalDownloads += statsData["downloads"] as? Int ?? 0
                }
                
                // Get average rating
                if let rating = data["averageRating"] as? Double,
                   let count = data["ratingCount"] as? Int,
                   count > 0 {
                    totalRating += rating * Double(count)
                    ratingCount += count
                }
            }
            
            await MainActor.run {
                self.sharedRoutinesCount = routinesQuery.documents.count
                self.totalDownloads = totalDownloads
                self.averageRating = ratingCount > 0 ? totalRating / Double(ratingCount) : 0.0
            }
        } catch {
            Logger.debug("Error loading user stats: \(error)")
        }
    }
    
    private func loadSharedRoutines(_ userId: String) async {
        await MainActor.run {
            isLoadingRoutines = true
        }
        
        do {
            let query = try await db.collection("routines")
                .whereField("createdBy", isEqualTo: userId)
                .whereField("isPublic", isEqualTo: true)
                .order(by: "creationDate", descending: true)
                .limit(to: 10)
                .getDocuments()
            
            let routines = query.documents.compactMap { doc -> Routine? in
                try? doc.data(as: Routine.self)
            }
            
            await MainActor.run {
                self.sharedRoutines = routines
                self.isLoadingRoutines = false
            }
        } catch {
            Logger.debug("Error loading shared routines: \(error)")
            await MainActor.run {
                self.errorMessage = "Failed to load routines"
                self.isLoadingRoutines = false
            }
        }
    }
    
    // MARK: - Block/Unblock
    
    func checkIfUserBlocked(userId: String, by blockerId: String) async -> Bool {
        do {
            let doc = try await db.collection("users").document(blockerId)
                .collection("blockedUsers").document(userId).getDocument()
            return doc.exists
        } catch {
            Logger.debug("Error checking block status: \(error)")
            return false
        }
    }
    
    func toggleBlockUser(userId: String, blockerId: String, shouldBlock: Bool) async -> Bool {
        do {
            let blockedRef = db.collection("users").document(blockerId)
                .collection("blockedUsers").document(userId)
            
            if shouldBlock {
                // Block user
                try await blockedRef.setData([
                    "userId": userId,
                    "blockedAt": Timestamp(date: Date())
                ])
                
                // Also add to global moderation collection for filtering
                try await db.collection("moderation").document("blockedRelations")
                    .collection("blocks").document("\(blockerId)_\(userId)").setData([
                        "blockerId": blockerId,
                        "blockedUserId": userId,
                        "timestamp": Timestamp(date: Date())
                    ])
            } else {
                // Unblock user
                try await blockedRef.delete()
                
                // Remove from global moderation collection
                try await db.collection("moderation").document("blockedRelations")
                    .collection("blocks").document("\(blockerId)_\(userId)").delete()
            }
            
            return true
        } catch {
            Logger.debug("Error toggling block status: \(error)")
            errorMessage = shouldBlock ? "Failed to block user" : "Failed to unblock user"
            return false
        }
    }
}