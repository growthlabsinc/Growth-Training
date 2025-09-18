import SwiftUI
import Combine

class SessionDetailViewModel: ObservableObject {
    @Published var sessionLog: SessionLog
    @Published var growthMethod: GrowthMethod?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showDeleteConfirmation: Bool = false
    @Published var showEditSheet: Bool = false

    private var firestoreService = FirestoreService.shared
    private var cancellables = Set<AnyCancellable>()

    init(sessionLog: SessionLog, growthMethod: GrowthMethod?) {
        self.sessionLog = sessionLog
        self.growthMethod = growthMethod
        
        // If growthMethod is not provided, or to ensure it's up-to-date, fetch it.
        // For now, we assume it's correctly passed. If fetching is needed:
        // self.fetchGrowthMethodDetails(methodId: sessionLog.methodId)
    }

    // Placeholder for fetching method details if not passed or needs refresh
    // func fetchGrowthMethodDetails(methodId: String) { ... }

    func deleteSession() {
        isLoading = true
        firestoreService.deleteSessionLog(logId: sessionLog.id) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = "Failed to delete session: \(error.localizedDescription)"
                } else {
                    // Notify history view to refresh - this might need a more robust solution
                    // like a shared publisher or a callback.
                    NotificationCenter.default.post(name: .sessionLogDeleted, object: self?.sessionLog.id)
                    // Presentation dismissal will be handled by the view
                }
            }
        }
    }
}

extension Notification.Name {
    static let sessionLogDeleted = Notification.Name("sessionLogDeleted")
    static let sessionLogUpdated = Notification.Name("sessionLogUpdated")
} 