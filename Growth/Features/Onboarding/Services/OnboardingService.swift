import Foundation
import FirebaseFirestore
import FirebaseAuth

class OnboardingService: ObservableObject {
    static let shared = OnboardingService()
    private let db = Firestore.firestore()
    
    /// Record disclaimer acceptance for the current user
    func recordDisclaimerAcceptance(version: DisclaimerVersion, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "OnboardingService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated."])));
            return
        }
        
        let batch = db.batch()
        let userRef = db.collection("users").document(userId)
        let now = Date()
        
        // Update traditional disclaimer fields for backward compatibility
        let data: [String: Any] = [
            "disclaimerAccepted": true,
            "disclaimerAcceptedTimestamp": Timestamp(date: now),
            "disclaimerVersion": version.version
        ]
        batch.setData(data, forDocument: userRef, merge: true)
        
        // Also add to consent records array
        let consentData: [String: Any] = [
            "documentId": "medical_disclaimer",
            "documentVersion": version.version,
            "acceptedAt": Timestamp(date: now)
        ]
        batch.updateData([
            "consentRecords": FieldValue.arrayUnion([consentData])
        ], forDocument: userRef)
        
        // Commit the batch
        batch.commit { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    /// Check if disclaimer needs to be shown (user has not accepted current version)
    func needsDisclaimerAcceptance(user: User?) -> Bool {
        guard let user = user else { return true }
        return user.disclaimerAccepted != true || user.disclaimerVersion != DisclaimerVersion.current.version
    }
} 