//
//  BlockingService.swift
//  Growth
//
//  Service for managing user blocking functionality
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class BlockingService: ObservableObject {
    static let shared = BlockingService()
    
    @Published var blockedUserIds: Set<String> = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var authListener: AuthStateDidChangeListenerHandle?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupAuthListener()
    }
    
    deinit {
        listener?.remove()
        if let authListener = authListener {
            Auth.auth().removeStateDidChangeListener(authListener)
        }
    }
    
    private func setupAuthListener() {
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if user != nil {
                self?.loadBlockedUsers()
            } else {
                self?.clearBlockedUsers()
            }
        }
    }
    
    private func clearBlockedUsers() {
        blockedUserIds.removeAll()
        listener?.remove()
        listener = nil
    }
    
    func loadBlockedUsers() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        error = nil
        
        // Set up real-time listener for blocked users
        listener?.remove()
        listener = db.collection("users").document(userId)
            .addSnapshotListener { [weak self] documentSnapshot, error in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    self.error = error
                    Logger.error("Error loading blocked users: \(error)")
                    return
                }
                
                guard let document = documentSnapshot,
                      let data = document.data() else { return }
                
                if let blockedArray = data["blockedUserIds"] as? [String] {
                    self.blockedUserIds = Set(blockedArray)
                }
            }
    }
    
    func blockUser(_ blockedUserId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw CustomError.unauthorized
        }
        
        guard userId != blockedUserId else {
            throw CustomError.invalidInput(message: "Cannot block yourself")
        }
        
        try await db.collection("users").document(userId).updateData([
            "blockedUserIds": FieldValue.arrayUnion([blockedUserId])
        ])
        
        // Update local state immediately for better UX
        _ = await MainActor.run {
            blockedUserIds.insert(blockedUserId)
        }
    }
    
    func unblockUser(_ blockedUserId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw CustomError.unauthorized
        }
        
        try await db.collection("users").document(userId).updateData([
            "blockedUserIds": FieldValue.arrayRemove([blockedUserId])
        ])
        
        // Update local state immediately for better UX
        _ = await MainActor.run {
            blockedUserIds.remove(blockedUserId)
        }
    }
    
    func isUserBlocked(_ userId: String) -> Bool {
        return blockedUserIds.contains(userId)
    }
    
    // Check if current user is blocked by another user
    func isBlockedBy(_ userId: String) async throws -> Bool {
        let document = try await db.collection("users").document(userId).getDocument()
        
        guard let data = document.data(),
              let blockedArray = data["blockedUserIds"] as? [String],
              let currentUserId = Auth.auth().currentUser?.uid else {
            return false
        }
        
        return blockedArray.contains(currentUserId)
    }
    
    // Get list of blocked users with their profiles
    func getBlockedUserProfiles() async throws -> [User] {
        guard !blockedUserIds.isEmpty else { return [] }
        
        var profiles: [User] = []
        
        for blockedId in blockedUserIds {
            do {
                let document = try await db.collection("users").document(blockedId).getDocument()
                if let user = try? document.data(as: User.self) {
                    profiles.append(user)
                }
            } catch {
                Logger.error("Error fetching blocked user profile: \(error)")
            }
        }
        
        return profiles
    }
    
    // Report and block user in one action
    func reportAndBlockUser(_ userId: String, reason: ReportReason, details: String?) async throws {
        // First block the user
        try await blockUser(userId)
        
        // Then create a user report (different from content report)
        guard let reporterId = Auth.auth().currentUser?.uid else {
            throw CustomError.unauthorized
        }
        
        let report = Report(
            reporterId: reporterId,
            contentId: userId,
            contentType: .user,
            creatorId: userId,
            reason: reason,
            details: details,
            createdAt: Date(),
            status: .pending
        )
        
        try await db.collection("reports").addDocument(data: report.toDictionary())
    }
}

// MARK: - Custom Errors
enum CustomError: LocalizedError {
    case unauthorized
    case invalidInput(message: String)
    case networkError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "You must be logged in to perform this action"
        case .invalidInput(let message):
            return message
        case .networkError:
            return "Network error. Please check your connection"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}