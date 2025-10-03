import Foundation
import Combine
import FirebaseAuth

class EducationalResourcesListViewModel: ObservableObject {
    @Published var educationalResources: [EducationalResource] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private var firestoreService: FirestoreService
    private var authStateListener: AuthStateDidChangeListenerHandle?

    init(firestoreService: FirestoreService = .shared) {
        self.firestoreService = firestoreService
        setupAuthListener()
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    private func setupAuthListener() {
        // Listen for auth state changes and fetch resources when authenticated
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if user != nil {
                Logger.debug("🔍 User authenticated, fetching educational resources...")
                self?.fetchEducationalResources()
            } else {
                Logger.debug("❌ No authenticated user, clearing educational resources")
                self?.educationalResources = []
                self?.errorMessage = nil
                self?.isLoading = false
            }
        }
        
        // Also try to fetch immediately if user is already authenticated
        if Auth.auth().currentUser != nil {
            fetchEducationalResources()
        }
    }

    func fetchEducationalResources() {
        // Check authentication before making request
        guard let user = Auth.auth().currentUser else {
            Logger.debug("❌ No authenticated user - cannot fetch educational resources")
            DispatchQueue.main.async {
                self.errorMessage = "Authentication required to load resources"
                self.isLoading = false
            }
            return
        }
        
        Logger.debug("🔍 Fetching educational resources for user: \(user.uid)")
        isLoading = true
        errorMessage = nil

        firestoreService.getAllEducationalResources { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                switch result {
                case .success(let resources):
                    Logger.debug("✅ Successfully fetched \(resources.count) educational resources")
                    // Filter resources to ensure they have a valid ID
                    self.educationalResources = resources.filter { resource in
                        if let id = resource.id, !id.isEmpty {
                            return true
                        } else {
                            Logger.debug("Warning: Filtering out resource '\(resource.title)' due to nil or empty ID.")
                            return false
                        }
                    }
                    if self.educationalResources.isEmpty && !resources.isEmpty {
                        // This means all resources were filtered out, which might be an issue.
                        self.errorMessage = "Some resources could not be displayed properly."
                    } else if resources.isEmpty {
                        // This means Firestore returned no resources.
                        // The view will handle displaying "No resources available".
                        Logger.debug("⚠️ No educational resources found in Firestore")
                    }
                case .failure(let error):
                    Logger.debug("❌ Failed to fetch educational resources: \(error)")
                    
                    // Check for specific auth-related errors
                    let errorMessage = error.localizedDescription
                    if errorMessage.contains("permission") || 
                       errorMessage.contains("auth") ||
                       errorMessage.contains("unauthorized") {
                        self.errorMessage = "Authentication issue. Please try logging out and back in."
                        Logger.debug("🔒 Authentication error detected: \(error)")
                    } else {
                        self.errorMessage = "Failed to load educational resources: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
} 