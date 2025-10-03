import Foundation
import Combine
import FirebaseAuth

/// ViewModel responsible for fetching badge definitions and the current user's earned badges
class BadgesViewModel: ObservableObject {
    // MARK: - Published properties
    @Published var allBadges: [Badge] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    private let firestoreService: FirestoreService
    
    // MARK: - Initialization
    init(firestoreService: FirestoreService = FirestoreService.shared) {
        self.firestoreService = firestoreService
    }

    // MARK: - Filter
    enum BadgeFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case earned = "Earned"
        case locked = "Locked"

        var id: String { rawValue }
    }

    @Published var selectedFilter: BadgeFilter = .all

    // MARK: - Computed badges according to filter
    var filteredBadges: [Badge] {
        switch selectedFilter {
        case .all:
            return allBadges
        case .earned:
            return allBadges.filter { $0.isEarned }
        case .locked:
            return allBadges.filter { !$0.isEarned }
        }
    }

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Public API
    func loadBadges() {
        guard let userId = Auth.auth().currentUser?.uid else {
            self.errorMessage = "User not authenticated."
            return
        }

        // Fetch badge definitions and user's earned badges in parallel
        isLoading = true
        errorMessage = nil

        let group = DispatchGroup()

        var allBadgeDefs: [Badge] = []
        var userEarnedBadges: [Badge] = []
        var firstError: Error?

        group.enter()
        firestoreService.getAllBadges { badges, error in
            if let error = error { firstError = error }
            allBadgeDefs = badges
            group.leave()
        }

        group.enter()
        firestoreService.getUserBadges(userId: userId) { badges, error in
            if let error = error { firstError = error }
            userEarnedBadges = badges
            group.leave()
        }

        group.notify(queue: .main) {
            self.isLoading = false
            if let error = firstError {
                self.errorMessage = error.localizedDescription
                return
            }

            // Map earned badges by id for quick lookup
            let earnedDict = Dictionary(uniqueKeysWithValues: userEarnedBadges.map { ($0.id, $0) })
            // Combine definitions with earned data
            self.allBadges = allBadgeDefs.map { badge in
                var mutableBadge = badge
                if let earned = earnedDict[badge.id] {
                    mutableBadge.earnedDate = earned.earnedDate
                }
                return mutableBadge
            }.sorted { (lhs, rhs) -> Bool in
                // Earned badges first, then locked; within each alphabetical by name
                if lhs.isEarned != rhs.isEarned {
                    return lhs.isEarned && !rhs.isEarned
                } else {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
            }
        }
    }
} 