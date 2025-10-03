import SwiftUI
import Combine
import FirebaseAuth

class RestDayViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var wellnessActivities: [WellnessActivity] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentPrompt: JournalingPrompt?
    
    // For logging new wellness activities
    @Published var selectedActivityType: WellnessActivityType = .stretching
    @Published var activityDuration: String = ""
    @Published var activityNotes: String = ""
    @Published var showingActivityLogger = false
    @Published var isSavingActivity = false
    
    // MARK: - Private Properties
    private let schedule: DaySchedule
    private let firestoreService = FirestoreService.shared
    private let promptService = JournalingPromptService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var todaysActivities: [WellnessActivity] {
        let calendar = Calendar.current
        let today = Date()
        return wellnessActivities.filter { activity in
            calendar.isDate(activity.loggedAt, inSameDayAs: today)
        }
    }
    
    var totalWellnessTime: Int {
        return todaysActivities.reduce(0) { $0 + $1.duration }
    }
    
    var hasActivitiesToday: Bool {
        return !todaysActivities.isEmpty
    }
    
    var activitySummaryText: String {
        let count = todaysActivities.count
        let time = totalWellnessTime
        
        if count == 0 {
            return "No wellness activities logged today"
        } else if count == 1 {
            return "1 wellness activity • \(time) min total"
        } else {
            return "\(count) wellness activities • \(time) min total"
        }
    }
    
    // MARK: - Initialization
    init(schedule: DaySchedule) {
        self.schedule = schedule
        loadWellnessPrompt()
        loadTodaysWellnessActivities()
    }
    
    // MARK: - Public Methods
    func logWellnessActivity() {
        guard let durationInt = Int(activityDuration), durationInt > 0 else {
            errorMessage = "Please enter a valid duration"
            return
        }
        
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            return
        }
        
        isSavingActivity = true
        errorMessage = nil
        
        let activity = WellnessActivity(
            type: selectedActivityType,
            duration: durationInt,
            notes: activityNotes.isEmpty ? nil : activityNotes
        )
        
        // Create a session log entry for the wellness activity
        let sessionLog = SessionLog(
            id: UUID().uuidString,
            userId: userId,
            duration: durationInt,
            startTime: Date().addingTimeInterval(-Double(durationInt * 60)),
            endTime: Date(),
            userNotes: activity.notes,
            methodId: nil, // No method for wellness activities
            sessionIndex: nil,
            moodBefore: .neutral,
            moodAfter: .positive,
            intensity: nil,
            variation: "wellness_\(activity.type.rawValue)" // Mark as wellness activity
        )
        
        // Save the session log
        firestoreService.saveSessionLog(sessionLog) { [weak self] error in
            DispatchQueue.main.async {
                self?.isSavingActivity = false
                
                if let error = error {
                    self?.errorMessage = "Failed to save activity: \(error.localizedDescription)"
                } else {
                    // Add to local array for immediate UI update
                    self?.wellnessActivities.append(activity)
                    self?.resetActivityForm()
                    self?.showingActivityLogger = false
                }
            }
        }
    }
    
    func showActivityLogger(for type: WellnessActivityType) {
        selectedActivityType = type
        activityDuration = ""
        activityNotes = ""
        showingActivityLogger = true
    }
    
    func dismissActivityLogger() {
        showingActivityLogger = false
        resetActivityForm()
    }
    
    func refreshWellnessPrompt() {
        currentPrompt = promptService.randomPrompt(for: .recovery)
    }
    
    // MARK: - Private Methods
    private func loadWellnessPrompt() {
        currentPrompt = promptService.randomPrompt(for: .recovery)
    }
    
    private func loadTodaysWellnessActivities() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        
        // Get today's date range
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        let _ = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? today
        
        // Load session logs and filter for today's wellness activities
        firestoreService.getSessionLogsForUserFromLogsByEndTime(userId: userId, limit: 50) { [weak self] logs, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Failed to load wellness activities: \(error.localizedDescription)"
                    return
                }
                
                // Filter for today's wellness activities
                let todaysWellnessLogs = logs.filter { log in
                    // Check if it's a wellness activity and from today
                    guard log.variation?.hasPrefix("wellness_") == true else { return false }
                    let calendar = Calendar.current
                    return calendar.isDate(log.endTime, inSameDayAs: today)
                }
                
                // Convert wellness session logs to wellness activities
                self?.wellnessActivities = todaysWellnessLogs.compactMap { log in
                    guard let variationString = log.variation,
                          variationString.hasPrefix("wellness_") else { return nil }
                    
                    let typeString = String(variationString.dropFirst("wellness_".count))
                    guard let type = WellnessActivityType(rawValue: typeString) else { return nil }
                    
                    return WellnessActivity(
                        id: log.id,
                        type: type,
                        duration: log.duration,
                        notes: log.userNotes,
                        loggedAt: log.endTime
                    )
                }
            }
        }
    }
    
    private func resetActivityForm() {
        selectedActivityType = .stretching
        activityDuration = ""
        activityNotes = ""
        errorMessage = nil
    }
}