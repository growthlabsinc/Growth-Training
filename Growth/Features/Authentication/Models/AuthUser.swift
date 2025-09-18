//
//  AuthUser.swift
//  Growth
//
//  Created by Developer on 5/9/25.
//

import Foundation
import Firebase
import FirebaseFirestore
// MARK: - TODO: Add FirebaseFirestoreSwift when pod is installed and use @DocumentID

/// Auth user model that matches the Firestore user document structure for authentication
struct AuthUser: Identifiable, Codable {
    /// Firebase Authentication UID
    var id: String?  // TODO: Change to @DocumentID var id: String? when FirebaseFirestoreSwift pod is installed
    
    /// User's email address
    let email: String
    
    /// Timestamp when the user account was created
    let createdAt: Timestamp
    
    /// Timestamp when the user data was last updated
    var updatedAt: Timestamp
    
    /// Flag indicating whether the user has completed the onboarding process
    var onboardingCompleted: Bool = false
    
    /// Custom CodingKeys to match Firestore field names
    enum CodingKeys: String, CodingKey {
        case id = "uid"
        case email
        case createdAt
        case updatedAt
        case onboardingCompleted
    }
    
    /// Creates a new user with the current timestamp
    /// - Parameters:
    ///   - id: The Firebase Authentication UID
    ///   - email: The user's email address
    ///   - onboardingCompleted: Whether onboarding is completed (default: false)
    init(id: String? = nil, email: String, onboardingCompleted: Bool = false) {
        self.id = id
        self.email = email
        self.onboardingCompleted = onboardingCompleted
        
        let now = Timestamp()
        self.createdAt = now
        self.updatedAt = now
    }
} 