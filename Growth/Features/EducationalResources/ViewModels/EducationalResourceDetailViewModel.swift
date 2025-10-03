import Foundation
import Combine
import FirebaseFirestore

class EducationalResourceDetailViewModel: ObservableObject {
    @Published var resource: EducationalResource?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var firestoreService: FirestoreService
    private var resourceId: String
    
    init(resourceId: String, firestoreService: FirestoreService = .shared) {
        self.resourceId = resourceId
        self.firestoreService = firestoreService
        fetchResource()
    }
    
    /// Fetches the resource data from Firestore
    func fetchResource() {
        guard !resourceId.isEmpty else {
            errorMessage = "Resource ID is missing."
            isLoading = false // Ensure loading state is reset
            Logger.debug("Error: Attempted to fetch resource with an empty ID.")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        firestoreService.getEducationalResource(resourceId: resourceId) { [weak self] resource, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let resource = resource else {
                    self.errorMessage = "Resource not found"
                    return
                }
                
                self.resource = resource
            }
        }
    }
} 