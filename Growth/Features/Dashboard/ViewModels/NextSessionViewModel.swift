import Foundation
import Combine
import FirebaseAuth

/// View-model responsible for computing and exposing the next-session suggestion.
@MainActor
class NextSessionViewModel: ObservableObject {

    // MARK: - Published properties
    @Published var suggestion: NextSessionSuggestion?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Private
    private let firestoreService: FirestoreService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init(firestoreService: FirestoreService = .shared) {
        self.firestoreService = firestoreService
    }

    /// Fetches the best next-session suggestion for the currently logged-in user.
    func loadSuggestion() {
        guard let user = Auth.auth().currentUser else {
            self.errorMessage = "User not logged in"
            return
        }
        isLoading = true
        errorMessage = nil

        // Fetch user document first – needed for focus / readiness info.
        firestoreService.getUser(userId: user.uid) { [weak self] userModel, error in
            guard let self else { return }
            if let error = error {
                Task { @MainActor in
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
                return
            }

            // Extract the current focus method ID & stage from user doc custom fields.
            // Because earlier stories might not have stored these fields yet, attempt to
            // read them defensively.
            let docData = userModel?.toFirestoreData()
            // In Firestore, we expect: currentFocus.methodId and currentFocus.stage
            var focusMethodId: String? = nil
            if let focus = docData?["currentFocus"] as? [String: Any] {
                focusMethodId = focus["methodId"] as? String
                // Future: focus["stage"] may be useful; omit for now to avoid unused warning
            }

            guard let methodId = focusMethodId else {
                Task { @MainActor in
                    self.isLoading = false
                    self.errorMessage = "Select a focus method to get a suggestion."
                }
                return
            }

            // Fetch the GrowthMethod details to populate suggestion.
            self.firestoreService.getGrowthMethod(methodId: methodId) { method, error in
                Task { @MainActor in
                    self.isLoading = false
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        return
                    }
                    guard let method else {
                        self.errorMessage = "Growth method data unavailable"
                        return
                    }
                    let suggestion = NextSessionSuggestion(
                        id: method.id ?? methodId,
                        methodTitle: method.title,
                        stage: method.stage,
                        durationMinutes: method.estimatedDurationMinutes
                    )
                    self.suggestion = suggestion
                }
            }
        }
    }
} 