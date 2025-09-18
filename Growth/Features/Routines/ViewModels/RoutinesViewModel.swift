import Foundation
import Combine
import FirebaseFirestore

class RoutinesViewModel: ObservableObject {
    @Published var routines: [Routine] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var selectedRoutineId: String?
    @Published var routineProgress: RoutineProgress?
    
    private let routineService = RoutineService.shared
    private let userService = UserService()
    private var cancellables = Set<AnyCancellable>()
    private(set) var userId: String
    
    // Static cache for last user's routine (persists across logout/login)
    private static let lastUserRoutineKey = "last_user_routine_cache"
    
    init(userId: String) {
        self.userId = userId
        // Don't load anything if userId is empty (not logged in)
        guard !userId.isEmpty else {
            return
        }
        
        // Check static cache first (for same user re-login)
        if let cacheData = UserDefaults.standard.dictionary(forKey: Self.lastUserRoutineKey),
           let cachedUserId = cacheData["userId"] as? String,
           let cachedRoutineId = cacheData["routineId"] as? String,
           cachedUserId == userId {
            self.selectedRoutineId = cachedRoutineId
        }
        // Then check user-specific cache
        else if let cachedRoutineId = UserDefaults.standard.string(forKey: "cached_routine_\(userId)") {
            self.selectedRoutineId = cachedRoutineId
        }
        loadRoutines()
        fetchSelectedRoutineId()
        setupNotificationObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupNotificationObservers() {
        // Listen for routine deletion
        NotificationCenter.default.publisher(for: Notification.Name("routineDeleted"))
            .sink { [weak self] notification in
                if let deletedRoutineId = notification.object as? String {
                    // Remove from local array immediately
                    self?.routines.removeAll { $0.id == deletedRoutineId }
                    // If the deleted routine was selected, clear selection
                    if self?.selectedRoutineId == deletedRoutineId {
                        self?.selectedRoutineId = nil
                    }
                }
                // Reload routines to ensure consistency
                self?.loadRoutines()
            }
            .store(in: &cancellables)
        
        // Listen for routine updates
        NotificationCenter.default.publisher(for: Notification.Name("routineUpdated"))
            .sink { [weak self] _ in
                self?.loadRoutines()
            }
            .store(in: &cancellables)
    }
    
    
    func loadRoutines() {
        isLoading = true
        error = nil
        
        // Create a dispatch group to wait for all calls
        let group = DispatchGroup()
        var allRoutines: [Routine] = []
        var customRoutines: [Routine] = []
        var communityRoutines: [Routine] = []
        var fetchError: Error?
        
        // Fetch standard routines
        group.enter()
        routineService.fetchAllRoutines { result in
            switch result {
            case .success(let routines):
                allRoutines = routines
                for _ in routines {
                }
            case .failure(let err):
                fetchError = err
            }
            group.leave()
        }
        
        // Fetch custom routines if user is logged in
        if !userId.isEmpty {
            group.enter()
            routineService.fetchUserCustomRoutines(userId: userId) { result in
                switch result {
                case .success(let routines):
                    customRoutines = routines
                case .failure(_):
                    // Ignore custom routine errors - they're optional
                    break
                }
                group.leave()
            }
        }
        
        // Fetch community routines
        group.enter()
        routineService.fetchCommunityRoutines { result in
            switch result {
            case .success(let routines):
                communityRoutines = routines
            case .failure(_):
                // Ignore community routine errors - they're optional
                break
            }
            group.leave()
        }
        
        // Combine results
        group.notify(queue: .main) { [weak self] in
            self?.isLoading = false
            if let error = fetchError {
                self?.error = error.localizedDescription
            } else {
                // Combine standard, custom, and community routines
                // Use a dictionary to deduplicate by ID
                var uniqueRoutines: [String: Routine] = [:]

                // Add standard routines
                for routine in allRoutines {
                    uniqueRoutines[routine.id] = routine
                }

                // Add custom routines
                for routine in customRoutines {
                    uniqueRoutines[routine.id] = routine
                }

                // Add community routines (these might overlap with custom)
                for routine in communityRoutines {
                    // Only add if not already present (prefer local custom version)
                    if uniqueRoutines[routine.id] == nil {
                        uniqueRoutines[routine.id] = routine
                    }
                }

                let totalRoutines = Array(uniqueRoutines.values)
                self?.routines = totalRoutines

                // If we have a selected routine ID but haven't loaded its progress yet, load it now
                if let selectedId = self?.selectedRoutineId,
                   self?.routineProgress == nil,
                   totalRoutines.contains(where: { $0.id == selectedId }) {
                    self?.loadRoutineProgress()
                }

                // Log Firebase routines specifically
                let firebaseRoutines = totalRoutines.filter { $0.id == "janus_protocol_12week" || $0.id == "standard_growth_routine" }
                if !firebaseRoutines.isEmpty {
                    for _ in firebaseRoutines {
                    }
                } else {
                }
            }
        }
    }
    
    @Published var showRoutineChangeConfirmation = false
    @Published var pendingRoutineId: String?
    @Published var pendingRoutineName: String?
    
    func selectRoutine(_ routineId: String?) {
        // Store the previous routine ID before changing
        let previousRoutineId = selectedRoutineId
        
        selectedRoutineId = routineId
        
        // Clear current progress immediately to prevent showing old routine's progress
        routineProgress = nil
        
        // Reset progress for the previous routine if switching to a different routine
        if let previousId = previousRoutineId, 
            let newId = routineId,
           previousId != newId {
            // Delete the progress for the previous routine
            let db = Firestore.firestore()
            db.collection("users").document(userId).collection("routineProgress").document(previousId).delete { error in
                if error != nil {
                } else {
                }
            }
        }
        
        // Cache the selection locally
        if let routineId = routineId {
            UserDefaults.standard.set(routineId, forKey: "cached_routine_\(userId)")
            // Also save to static cache with userId
            let cacheData = ["userId": userId, "routineId": routineId]
            UserDefaults.standard.set(cacheData, forKey: Self.lastUserRoutineKey)
            
            // Always initialize fresh progress for the new routine
            if let routine = routines.first(where: { $0.id == routineId }) {
                // Initialize new progress starting from Day 1
                RoutineProgressService.shared.initializeProgress(userId: userId, routine: routine) { [weak self] newProgress in
                    DispatchQueue.main.async {
                        self?.routineProgress = newProgress
                    }
                }
            }
        } else {
            UserDefaults.standard.removeObject(forKey: "cached_routine_\(userId)")
            UserDefaults.standard.removeObject(forKey: Self.lastUserRoutineKey)
            routineProgress = nil
        }
        userService.updateSelectedRoutine(userId: userId, routineId: routineId) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.error = error.localizedDescription
                }
            }
        }
    }
    
    func requestRoutineChange(_ routineId: String, routineName: String) {
        pendingRoutineId = routineId
        pendingRoutineName = routineName
        showRoutineChangeConfirmation = true
    }
    
    func confirmRoutineChange() {
        if let routineId = pendingRoutineId {
            selectRoutine(routineId)
            showRoutineChangeConfirmation = false
            pendingRoutineId = nil
            pendingRoutineName = nil
        }
    }
    
    func cancelRoutineChange() {
        showRoutineChangeConfirmation = false
        pendingRoutineId = nil
        pendingRoutineName = nil
    }
    
    func updateUser(_ newUserId: String) {
        guard newUserId != userId else { return }
        userId = newUserId
        
        // Try to restore from cache first
        if let cachedRoutineId = UserDefaults.standard.string(forKey: "cached_routine_\(newUserId)") {
            selectedRoutineId = cachedRoutineId
        } else {
            selectedRoutineId = nil
        }
        
        routineProgress = nil
        routines = []
        loadRoutines()
        fetchSelectedRoutineId()
    }
    
    func fetchSelectedRoutineId() {
        userService.fetchSelectedRoutineId(userId: userId) { [weak self] routineId in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                // Clear progress if routine is changing
                if self.selectedRoutineId != routineId {
                    self.routineProgress = nil
                }
                
                self.selectedRoutineId = routineId
                // Cache the fetched value
                if let routineId = routineId {
                    UserDefaults.standard.set(routineId, forKey: "cached_routine_\(self.userId)")
                    // Also save to static cache with userId
                    let cacheData = ["userId": self.userId, "routineId": routineId]
                    UserDefaults.standard.set(cacheData, forKey: Self.lastUserRoutineKey)
                } else {
                    UserDefaults.standard.removeObject(forKey: "cached_routine_\(self.userId)")
                    // Only clear static cache if it was for this user
                    if let cacheData = UserDefaults.standard.dictionary(forKey: Self.lastUserRoutineKey),
                       let cachedUserId = cacheData["userId"] as? String,
                       cachedUserId == self.userId {
                        UserDefaults.standard.removeObject(forKey: Self.lastUserRoutineKey)
                    }
                }
                self.loadRoutineProgress()
            }
        }
    }
    
    private func loadRoutineProgress() {
        guard let routineId = selectedRoutineId else {
            routineProgress = nil
            return
        }
        
        guard let routine = routines.first(where: { $0.id == routineId }) else {
            routineProgress = nil
            return
        }
        
        RoutineProgressService.shared.fetchProgress(userId: userId, routineId: routineId) { [weak self] progress in
            if progress == nil {
                // No progress exists, initialize it
                RoutineProgressService.shared.initializeProgress(userId: self?.userId ?? "", routine: routine) { newProgress in
                    DispatchQueue.main.async {
                        self?.routineProgress = newProgress
                    }
                }
            } else {
                // Progress exists, use it
                DispatchQueue.main.async {
                    self?.routineProgress = progress
                }
            }
        }
    }
    
    /// Returns the next method for the provided date based on progress.
    func nextMethod(for date: Date) -> GrowthMethod? {
        guard let routineId = selectedRoutineId,
              let routine = routines.first(where: { $0.id == routineId }),
              let progress = routineProgress else { return nil }
        
        // Get the current day from progress
        let scheduleIndex = progress.currentDayNumber - 1 // Convert 1-based to 0-based index
        guard routine.schedule.indices.contains(scheduleIndex) else { return nil }
        let daySchedule = routine.schedule[scheduleIndex]
        
        guard let ids = daySchedule.methodIds, !ids.isEmpty else { return nil }
        
        // For now, always return the first method of the day
        // TODO: Add method tracking within a day if needed
        let methodId = ids[0]
        
        // Try to get from cache synchronously (if available)
        if let cachedData = GrowthMethodService.shared.methodCache.object(forKey: methodId as NSString) as? Data,
           let cachedMethod = try? NSKeyedUnarchiver.unarchivedObject(ofClass: GrowthMethod.self, from: cachedData) {
            return cachedMethod
        }
        // Otherwise, return nil (async fetch would require refactor)
        return nil
    }
    
    /// Get the current routine day
    func getCurrentRoutineDay() -> DaySchedule? {
        guard let routineId = selectedRoutineId,
              let routine = routines.first(where: { $0.id == routineId }),
              let progress = routineProgress else { return nil }
        
        let scheduleIndex = progress.currentDayNumber - 1 // Convert 1-based to 0-based index
        guard routine.schedule.indices.contains(scheduleIndex) else { return nil }
        return routine.schedule[scheduleIndex]
    }
    
    /// Advance routine progress after completing a method
    func markMethodCompleted(completion: ((Bool) -> Void)? = nil) {
        guard let routineId = selectedRoutineId,
              let routine = routines.first(where: { $0.id == routineId }),
              let progress = routineProgress else {
            completion?(false)
            return
        }
        
        // Get current day
        let scheduleIndex = progress.currentDayNumber - 1 // Convert 1-based to 0-based index
        guard routine.schedule.indices.contains(scheduleIndex) else {
            completion?(false)
            return
        }
        let currentDay = routine.schedule[scheduleIndex]
        
        guard let methodIds = currentDay.methodIds, !methodIds.isEmpty else {
            completion?(false)
            return
        }
        
        // Progress tracking is now based on day completion
        // startDate is set when RoutineProgress is created
        
        // Mark day as completed and advance to next day
        RoutineProgressService.shared.markRoutineDayCompleted(userId: userId, routine: routine) { [weak self] updatedProgress in
            DispatchQueue.main.async {
                self?.routineProgress = updatedProgress
                completion?(true)
            }
        }
    }
    
    /// Reset routine progress to start from Day 1
    func resetRoutineProgress(completion: ((Bool) -> Void)? = nil) {
        guard let routineId = selectedRoutineId,
              let routine = routines.first(where: { $0.id == routineId }) else {
            completion?(false)
            return
        }
        
        // Delete existing progress
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("routineProgress").document(routineId).delete { [weak self] error in
            if error != nil {
                completion?(false)
                return
            }
            
            // Create new progress starting from Day 1
            RoutineProgressService.shared.initializeProgress(userId: self?.userId ?? "", routine: routine, startDate: Date()) { newProgress in
                DispatchQueue.main.async {
                    self?.routineProgress = newProgress
                    completion?(true)
                }
            }
        }
    }
}
