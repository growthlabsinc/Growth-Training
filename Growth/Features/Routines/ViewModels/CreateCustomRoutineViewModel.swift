import Foundation
import SwiftUI
import Combine
import FirebaseAuth

/// ViewModel for creating custom routines (Premium feature)
public class CreateCustomRoutineViewModel: ObservableObject {
    @Published var routineName: String = ""
    @Published var routineDescription: String = ""
    @Published var selectedMethods: [GrowthMethod] = []
    @Published var selectedDifficulty: RoutineDifficulty = .intermediate
    @Published var selectedDuration: Int = 14
    @Published var shareWithCommunity: Bool = false
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    /// Entitlement manager for checking feature access
    private let entitlementManager: EntitlementProvider
    
    /// Available routine difficulties
    enum RoutineDifficulty: String, CaseIterable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
    }
    
    public init(entitlementManager: EntitlementProvider? = nil) {
        self.entitlementManager = entitlementManager ?? DefaultEntitlementProvider()
    }
    
    /// Save the custom routine
    func save() {
        isLoading = true
        error = nil
        
        // Placeholder implementation - would integrate with RoutineService
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
            // Would show success state or navigate back
        }
    }
    
    /// Save a custom routine with completion handler
    func saveCustomRoutine(_ routine: Routine, shareWithCommunity: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        isLoading = true
        error = nil
        
        // Update local properties from routine
        routineName = routine.name
        routineDescription = routine.description
        self.shareWithCommunity = shareWithCommunity
        
        // Get current user ID
        guard let userId = Auth.auth().currentUser?.uid else {
            self.isLoading = false
            self.error = "User not authenticated"
            completion(.failure(NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        // Call the RoutineService
        RoutineService.shared.saveCustomRoutine(routine, userId: userId, shareWithCommunity: shareWithCommunity, entitlementProvider: entitlementManager) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    self?.error = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Validate routine creation inputs
    var isValid: Bool {
        !routineName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !selectedMethods.isEmpty
    }
}