import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

/// Service responsible for managing app tour state and persistence
class AppTourService: ObservableObject {
    static let shared = AppTourService()
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    @Published var hasCompletedTour: Bool = false
    @Published var hasSeenTour: Bool = false
    
    private let tourCompletionKey = "hasCompletedAppTour"
    private let tourSeenKey = "hasSeenAppTour"
    
    private init() {
        loadTourState()
    }
    
    /// Load tour state from UserDefaults and Firebase
    private func loadTourState() {
        // Load from UserDefaults first for immediate state
        hasCompletedTour = UserDefaults.standard.bool(forKey: tourCompletionKey)
        hasSeenTour = UserDefaults.standard.bool(forKey: tourSeenKey)
        
        // Then sync with Firebase if user is authenticated
        if let userId = Auth.auth().currentUser?.uid {
            fetchTourStateFromFirebase(userId: userId)
        }
    }
    
    /// Fetch tour state from Firebase
    private func fetchTourStateFromFirebase(userId: String) {
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self,
                  let data = snapshot?.data(),
                  error == nil else { return }
            
            if let completed = data["hasCompletedAppTour"] as? Bool {
                self.hasCompletedTour = completed
                UserDefaults.standard.set(completed, forKey: self.tourCompletionKey)
            }
            
            if let seen = data["hasSeenAppTour"] as? Bool {
                self.hasSeenTour = seen
                UserDefaults.standard.set(seen, forKey: self.tourSeenKey)
            }
        }
    }
    
    /// Check if tour should be shown
    func shouldShowTour() -> Bool {
        return !hasSeenTour && !hasCompletedTour
    }
    
    /// Mark tour as started
    func markTourStarted() {
        hasSeenTour = true
        UserDefaults.standard.set(true, forKey: tourSeenKey)
        
        if let userId = Auth.auth().currentUser?.uid {
            db.collection("users").document(userId).updateData([
                "hasSeenAppTour": true
            ]) { _ in }
        }
    }
    
    /// Mark tour as completed
    func markTourCompleted() {
        hasCompletedTour = true
        hasSeenTour = true
        UserDefaults.standard.set(true, forKey: tourCompletionKey)
        UserDefaults.standard.set(true, forKey: tourSeenKey)
        
        if let userId = Auth.auth().currentUser?.uid {
            db.collection("users").document(userId).updateData([
                "hasCompletedAppTour": true,
                "hasSeenAppTour": true,
                "tourCompletedAt": FieldValue.serverTimestamp()
            ]) { _ in }
        }
    }
    
    /// Mark tour as skipped
    func markTourSkipped() {
        hasSeenTour = true
        UserDefaults.standard.set(true, forKey: tourSeenKey)
        
        if let userId = Auth.auth().currentUser?.uid {
            db.collection("users").document(userId).updateData([
                "hasSeenAppTour": true,
                "hasSkippedAppTour": true,
                "tourSkippedAt": FieldValue.serverTimestamp()
            ]) { _ in }
        }
    }
    
    /// Reset tour state (for testing purposes)
    func resetTourState() {
        hasCompletedTour = false
        hasSeenTour = false
        UserDefaults.standard.removeObject(forKey: tourCompletionKey)
        UserDefaults.standard.removeObject(forKey: tourSeenKey)
        UserDefaults.standard.synchronize()
        
        // Note: Firebase update should be done separately by the caller
        // to ensure proper error handling and user feedback
    }
    
    /// Get the default tour configuration
    func getTourConfiguration() -> AppTourConfiguration {
        return AppTourConfiguration.defaultTour
    }
}