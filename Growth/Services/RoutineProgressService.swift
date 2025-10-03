import Foundation
import FirebaseFirestore

/// Handles reading & updating routine progress documents in Firestore.
final class RoutineProgressService {
    static let shared = RoutineProgressService()
    private init() {}

    private func collection(for userId: String) -> CollectionReference? {
        guard !userId.isEmpty else { return nil }
        return Firestore.firestore().collection("users").document(userId).collection("routineProgress")
    }

    /// Fetch the progress document for the given routine.
    func fetchProgress(userId: String, routineId: String, completion: @escaping (RoutineProgress?) -> Void) {
        guard !userId.isEmpty, !routineId.isEmpty else {
            completion(nil)
            return
        }
        guard let collection = collection(for: userId) else {
            completion(nil)
            return
        }
        collection.document(routineId).getDocument { snapshot, error in
            if let data = snapshot?.data() {
                do {
                    var progress = try Firestore.Decoder().decode(RoutineProgress.self, from: data)
                    
                    // Check if we need to shift the routine day forward
                    if progress.isOverdue && !progress.isCompleted {
                        progress = self.shiftRoutineToToday(progress)
                        self.saveProgress(progress) { _ in
                            completion(progress)
                        }
                    } else {
                        completion(progress)
                    }
                } catch {
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }

    /// Create or update routine progress.
    func saveProgress(_ progress: RoutineProgress, completion: ((Error?) -> Void)? = nil) {
        guard !progress.userId.isEmpty, !progress.routineId.isEmpty else {
            completion?(nil)
            return
        }
        guard let collection = collection(for: progress.userId) else {
            completion?(nil)
            return
        }
        do {
            let dict = try Firestore.Encoder().encode(progress)
            collection.document(progress.routineId).setData(dict) { error in
                completion?(error)
            }
        } catch {
            completion?(error)
        }
    }

    /// Mark the current routine day as started
    func markRoutineDayStarted(userId: String, routineId: String, completion: ((RoutineProgress?) -> Void)? = nil) {
        fetchProgress(userId: userId, routineId: routineId) { progress in
            guard let progress = progress else {
                completion?(nil)
                return
            }
            
            // Progress already has startDate from initialization
            completion?(progress)
        }
    }

    /// Mark the current routine day as completed and advance to the next day
    func markRoutineDayCompleted(userId: String, routine: Routine, completion: ((RoutineProgress?) -> Void)? = nil) {
        fetchProgress(userId: userId, routineId: routine.id) { [weak self] progress in
            guard var progress = progress else {
                completion?(nil)
                return
            }
            
            // Mark as completed
            progress.markDayCompleted()
            progress.updatedAt = Date()
            
            // Don't automatically advance to the next day
            // The next day should only show when:
            // 1. It's actually the next calendar day, OR
            // 2. The user explicitly starts the next day's routine
            // This prevents showing "Day 2" while still completing Day 1
            
            self?.saveProgress(progress) { _ in
                completion?(progress)
            }
        }
    }

    /// Shift an overdue routine day to today
    private func shiftRoutineToToday(_ progress: RoutineProgress) -> RoutineProgress {
        var updatedProgress = progress
        // Update timestamp to reflect change
        updatedProgress.updatedAt = Date()
        return updatedProgress
    }

    /// Get the current routine day for display
    func getCurrentRoutineDay(userId: String, routine: Routine, completion: @escaping (DaySchedule?, RoutineProgress?) -> Void) {
        fetchProgress(userId: userId, routineId: routine.id) { progress in
            guard let progress = progress else {
                // No progress yet, return the first day
                completion(routine.schedule.first, nil)
                return
            }
            
            
            // Check if we should show the completed day or the current day
            var dayNumberToShow = progress.currentDayNumber
            
            // If the current day is completed and it's still the same calendar day,
            // show the completed day instead of advancing
            if progress.completedDays.contains(progress.currentDayNumber),
               let lastCompletedDate = progress.lastCompletedDate {
                let calendar = Calendar.current
                if calendar.isDateInToday(lastCompletedDate) {
                    // Still the same day, show the completed day
                    dayNumberToShow = progress.currentDayNumber
                }
            }
            
            // Get the day based on the number to show
            // Use dayNumberToShow - 1 as index (days are 1-based)
            let scheduleIndex = max(0, dayNumberToShow - 1)
            let currentDay = routine.schedule.indices.contains(scheduleIndex) 
                ? routine.schedule[scheduleIndex] 
                : routine.schedule.first
            
            
            completion(currentDay, progress)
        }
    }

    /// Initialize progress for a new routine
    func initializeProgress(userId: String, routine: Routine, startDate: Date = Date(), completion: ((RoutineProgress?) -> Void)? = nil) {
        let progress = RoutineProgress(userId: userId, routineId: routine.id, startDate: startDate)
        saveProgress(progress) { error in
            if error != nil {
                completion?(nil)
            } else {
                completion?(progress)
            }
        }
    }
    
    /// Check if we should advance to the next day and do so if appropriate
    func checkAndAdvanceToNextDayIfNeeded(userId: String, routine: Routine, completion: ((RoutineProgress?) -> Void)? = nil) {
        fetchProgress(userId: userId, routineId: routine.id) { [weak self] progress in
            guard var progress = progress else {
                completion?(nil)
                return
            }
            
            // Check if current day is completed
            guard progress.completedDays.contains(progress.currentDayNumber) else {
                // Current day not completed, don't advance
                completion?(progress)
                return
            }
            
            // Check if it's a new calendar day since last completion
            if let lastCompletedDate = progress.lastCompletedDate {
                let calendar = Calendar.current
                if !calendar.isDateInToday(lastCompletedDate) {
                    // It's a new day, advance to next routine day
                    if progress.currentDayNumber < routine.schedule.count {
                        progress.advanceToNextDay()
                    } else {
                        // Wrap around to the beginning if at the end
                        progress.currentDayNumber = 1
                    }
                    progress.updatedAt = Date()
                    
                    self?.saveProgress(progress) { _ in
                        completion?(progress)
                    }
                    return
                }
            }
            
            // Same day, don't advance
            completion?(progress)
        }
    }

    /// Check if a routine day has been completed for a specific date
    func isRoutineDayCompleted(userId: String, routineId: String, date: Date, completion: @escaping (Bool) -> Void) {
        fetchProgress(userId: userId, routineId: routineId) { progress in
            guard let progress = progress else {
                completion(false)
                return
            }
            
            // Check if the completed date matches the requested date
            if let completedDate = progress.lastCompletedDate {
                let calendar = Calendar.current
                completion(calendar.isDate(completedDate, inSameDayAs: date))
            } else {
                completion(false)
            }
        }
    }
    
    /// Increment the nextMethodIndex when a method is completed
    func incrementMethodIndex(userId: String, routineId: String, completion: ((RoutineProgress?) -> Void)? = nil) {
        fetchProgress(userId: userId, routineId: routineId) { [weak self] progress in
            guard var progress = progress else {
                completion?(nil)
                return
            }
            
            // Update timestamp
            progress.updatedAt = Date()
            
            // Progress tracking updated
            
            self?.saveProgress(progress) { error in
                if error != nil {
                    completion?(nil)
                } else {
                    completion?(progress)
                }
            }
        }
    }
    
    /// Reset the current routine day completion status (for debugging/testing)
    func resetTodaysCompletion(userId: String, routineId: String, completion: ((RoutineProgress?) -> Void)? = nil) {
        
        fetchProgress(userId: userId, routineId: routineId) { [weak self] progress in
            if var progress = progress {
                
                // Reset completion status for today
                progress.lastCompletedDate = nil
                
                // IMPORTANT: Remove current day from completedDays array
                progress.completedDays.removeAll { day in day == progress.currentDayNumber }
                
                // Reset isCompleted flag if it was set
                progress.isCompleted = false
                
                // Update the timestamp
                progress.updatedAt = Date()
                
                
                self?.saveProgress(progress) { error in
                    if error != nil {
                        completion?(nil)
                    } else {
                        
                        // Post notification to update UI
                        NotificationCenter.default.post(name: .routineProgressUpdated, object: progress)
                        
                        completion?(progress)
                    }
                }
            } else {
                // If no progress exists, create initial progress for today
                let initialProgress = RoutineProgress(userId: userId, routineId: routineId, startDate: Date())
                
                self?.saveProgress(initialProgress) { error in
                    if error != nil {
                        completion?(nil)
                    } else {
                        completion?(initialProgress)
                    }
                }
            }
        }
    }
} 