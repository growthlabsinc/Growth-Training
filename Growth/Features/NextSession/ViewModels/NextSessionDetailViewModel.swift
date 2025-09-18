import Foundation
import Combine

/// ViewModel responsible for loading the full `GrowthMethod` for a `NextSessionSuggestion`
@MainActor
class NextSessionDetailViewModel: ObservableObject {
    // MARK: - Published
    @Published var method: GrowthMethod?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Private
    private let firestoreService: FirestoreService
    private var cancellables = Set<AnyCancellable>()
    private let suggestion: NextSessionSuggestion

    // MARK: - Init
    init(suggestion: NextSessionSuggestion,
         firestoreService: FirestoreService = .shared) {
        self.suggestion = suggestion
        self.firestoreService = firestoreService
        loadMethod()
    }

    // MARK: - Public Helpers
    func loadMethod() {
        isLoading = true
        errorMessage = nil
        firestoreService.getGrowthMethod(methodId: suggestion.id) { [weak self] method, error in
            guard let self else { return }
            Task { @MainActor in
                self.isLoading = false
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                guard let method = method else {
                    self.errorMessage = "Method data unavailable"
                    return
                }
                self.method = method
            }
        }
    }
} 