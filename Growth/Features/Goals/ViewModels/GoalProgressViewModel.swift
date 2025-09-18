import Foundation
import Combine
import FirebaseAuth

/// ViewModel responsible for fetching and publishing the user's active goals.
@MainActor
final class GoalProgressViewModel: ObservableObject {
    // Published list of goals for the current user
    @Published private(set) var goals: [Goal] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String? = nil

    private var cancellables = Set<AnyCancellable>()
    private let goalService = GoalService.shared

    /// Public default initializer
    init() {
        // no-op, default state already initialized above
    }

    /// Fetch goals for the current user
    func loadGoals() {
        guard Auth.auth().currentUser != nil else {
            self.errorMessage = "User not logged in"
            return
        }
        isLoading = true
        errorMessage = nil
        goalService.fetchGoalsForCurrentUser { [weak self] goals, error in
            Task { @MainActor in
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                } else {
                    self?.goals = goals
                }
            }
        }
    }

    /// Returns goals that are incomplete (currentValue < targetValue) and not archived.
    var activeGoals: [Goal] {
        goals.filter { !$0.isArchived && $0.currentValue < $0.targetValue }
    }

    /// Convenience method to compute progress percentage for a goal.
    func progress(for goal: Goal) -> Double {
        guard goal.targetValue > 0 else { return 0 }
        return min(1.0, goal.currentValue / goal.targetValue)
    }

    #if DEBUG
    /// Debug initializer for SwiftUI previews allowing injection of mock goals.
    convenience init(previewGoals: [Goal]) {
        self.init()
        self.goals = previewGoals
    }
    #endif
} 