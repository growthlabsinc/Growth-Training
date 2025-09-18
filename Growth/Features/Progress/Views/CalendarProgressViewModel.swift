import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class CalendarProgressViewModel: ObservableObject {
    @Published var dailyProgress: [Date: DailyProgress] = [:]
    @Published var isLoading = false
    @Published var selectedDateSessions: [SessionRecord] = []
    
    private let db = Firestore.firestore()
    private var userId: String? {
        Auth.auth().currentUser?.uid
    }
    
    struct DailyProgress {
        let date: Date
        let sessionsCompleted: Int
        let promptsCompleted: Int
        let totalDuration: Int // in seconds
        let methodsUsed: Set<String>
    }
    
    struct SessionRecord {
        let id: String
        let methodName: String
        let promptsCompleted: Int
        let duration: Int
        let timestamp: Date
    }
    
    init() {
        loadProgressData()
    }
    
    func getProgress(for date: Date) -> DailyProgress? {
        let calendar = Calendar.current
        return dailyProgress.first { calendar.isDate($0.key, inSameDayAs: date) }?.value
    }
    
    func loadSessionsForDate(_ date: Date) {
        guard let userId = userId else { return }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }
        
        isLoading = true
        
        db.collection("users").document(userId).collection("sessions")
            .whereField("timestamp", isGreaterThanOrEqualTo: startOfDay)
            .whereField("timestamp", isLessThan: endOfDay)
            .order(by: "timestamp", descending: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    Logger.debug("Error loading sessions: \(error)")
                    self.isLoading = false
                    return
                }
                
                self.selectedDateSessions = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    guard let methodName = data["methodName"] as? String,
                          let promptsCompleted = data["promptsCompleted"] as? Int,
                          let duration = data["duration"] as? Int,
                          let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() else {
                        return nil
                    }
                    
                    return SessionRecord(
                        id: doc.documentID,
                        methodName: methodName,
                        promptsCompleted: promptsCompleted,
                        duration: duration,
                        timestamp: timestamp
                    )
                } ?? []
                
                self.isLoading = false
            }
    }
    
    private func loadProgressData() {
        guard let userId = userId else { return }
        
        isLoading = true
        
        // Load last 90 days of session data
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -90, to: endDate) else { return }
        
        db.collection("users").document(userId).collection("sessions")
            .whereField("timestamp", isGreaterThanOrEqualTo: startDate)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    Logger.debug("Error loading progress data: \(error)")
                    self.isLoading = false
                    return
                }
                
                // Group sessions by day
                var progressByDay: [Date: (sessions: Int, prompts: Int, duration: Int, methods: Set<String>)] = [:]
                
                snapshot?.documents.forEach { doc in
                    let data = doc.data()
                    guard let timestamp = (data["timestamp"] as? Timestamp)?.dateValue(),
                          let promptsCompleted = data["promptsCompleted"] as? Int,
                          let duration = data["duration"] as? Int,
                          let methodName = data["methodName"] as? String else {
                        return
                    }
                    
                    let dayStart = calendar.startOfDay(for: timestamp)
                    
                    if var existing = progressByDay[dayStart] {
                        existing.sessions += 1
                        existing.prompts += promptsCompleted
                        existing.duration += duration
                        existing.methods.insert(methodName)
                        progressByDay[dayStart] = existing
                    } else {
                        progressByDay[dayStart] = (
                            sessions: 1,
                            prompts: promptsCompleted,
                            duration: duration,
                            methods: [methodName]
                        )
                    }
                }
                
                // Convert to DailyProgress objects
                self.dailyProgress = progressByDay.reduce(into: [:]) { result, entry in
                    result[entry.key] = DailyProgress(
                        date: entry.key,
                        sessionsCompleted: entry.value.sessions,
                        promptsCompleted: entry.value.prompts,
                        totalDuration: entry.value.duration,
                        methodsUsed: entry.value.methods
                    )
                }
                
                self.isLoading = false
            }
    }
    
    // MARK: - Statistics
    
    func getCurrentStreak() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var checkDate = today
        
        while let progress = getProgress(for: checkDate), progress.sessionsCompleted > 0 {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDay
        }
        
        return streak
    }
    
    func getLongestStreak() -> Int {
        let sortedDates = dailyProgress.keys.sorted()
        guard !sortedDates.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        var longestStreak = 0
        var currentStreak = 1
        
        for i in 1..<sortedDates.count {
            let prevDate = sortedDates[i-1]
            let currentDate = sortedDates[i]
            
            if calendar.dateComponents([.day], from: prevDate, to: currentDate).day == 1 {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                currentStreak = 1
            }
        }
        
        return max(longestStreak, currentStreak)
    }
    
    func getTotalSessions() -> Int {
        dailyProgress.values.reduce(0) { $0 + $1.sessionsCompleted }
    }
    
    func getTotalTime() -> Int {
        dailyProgress.values.reduce(0) { $0 + $1.totalDuration }
    }
}