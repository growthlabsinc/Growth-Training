import Foundation
import Combine
import FirebaseAuth

class RoutineDetailViewModel: ObservableObject {
    @Published var routine: Routine?
    @Published var isLoading: Bool = false
    @Published var error: String?

    private let routineService = RoutineService.shared
    private let authService = AuthService()
    private var cancellables = Set<AnyCancellable>()

    func loadRoutine(by id: String) {
        isLoading = true
        error = nil
        
        // Get current user ID - try both AuthService and Firebase Auth directly
        var userId = authService.currentUser?.id
        if userId == nil, let firebaseUser = Auth.auth().currentUser {
            userId = firebaseUser.uid
            Logger.debug("🔍 RoutineDetailViewModel: Using Firebase Auth user ID directly")
        }
        
        Logger.debug("🔍 RoutineDetailViewModel: Loading routine \(id), userId: \(userId ?? "none")")
        
        // For custom routines without the "custom_" prefix, also check the user's collection
        if userId != nil && !id.starts(with: "custom_") && id.contains("-") {
            // This looks like a UUID, might be a custom routine
            Logger.debug("🔍 RoutineDetailViewModel: Detected UUID format, checking user's custom routines first")
            routineService.fetchRoutineFromAnySource(by: id, userId: userId) { [weak self] result in
                DispatchQueue.main.async {
                    self?.handleRoutineResult(result, routineId: id, userId: userId)
                }
            }
        } else {
            routineService.fetchRoutineFromAnySource(by: id, userId: userId) { [weak self] result in
                DispatchQueue.main.async {
                    self?.handleRoutineResult(result, routineId: id, userId: userId)
                }
            }
        }
    }
    
    private func handleRoutineResult(_ result: Result<Routine, Error>, routineId: String, userId: String?) {
        isLoading = false
        switch result {
        case .success(let routine):
            Logger.debug("✅ RoutineDetailViewModel: Successfully loaded routine: \(routine.name)")
            self.routine = routine
        case .failure(let err):
            Logger.debug("❌ RoutineDetailViewModel: Failed to load routine: \(err)")
            // If we have a user ID and this looks like a custom routine, try the user's collection directly
            if let userId = userId, !routineId.starts(with: "custom_") && routineId.contains("-") {
                Logger.debug("🔍 RoutineDetailViewModel: Attempting to load as custom routine from user's collection")
                routineService.fetchUserCustomRoutines(userId: userId) { [weak self] customResult in
                    DispatchQueue.main.async {
                        switch customResult {
                        case .success(let routines):
                            if let customRoutine = routines.first(where: { $0.id == routineId }) {
                                Logger.debug("✅ RoutineDetailViewModel: Found custom routine in user's collection")
                                self?.routine = customRoutine
                            } else {
                                self?.error = "Routine not found"
                            }
                        case .failure:
                            self?.error = err.localizedDescription
                        }
                    }
                }
            } else {
                self.error = err.localizedDescription
            }
        }
    }
} 