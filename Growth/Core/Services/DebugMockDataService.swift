//
//  DebugMockDataService.swift
//  Growth
//
//  Service for generating and managing mock session data in debug builds
//

import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

/// Service to generate and manage mock data for debug builds
class DebugMockDataService {
    // MARK: - Properties
    
    static let shared = DebugMockDataService()
    private let db = Firestore.firestore()
    private let sessionLogsCollection = "sessionLogs"
    private let gainsCollection = "gains_entries"
    
    // Flag to track if mock data has been initialized this session
    private var hasInitializedThisSession = false
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Initialize mock data for debug builds if needed
    func initializeMockDataIfNeeded() {
        #if DEBUG
        // Only run once per app session
        guard !hasInitializedThisSession else { return }
        hasInitializedThisSession = true
        
        // Only generate mock data in development environment
        guard EnvironmentDetector.isDevelopment else {
            Logger.debug("Not in development environment, skipping mock data")
            return
        }
        
        // Additional production safeguard - check bundle identifier
        if let bundleId = Bundle.main.bundleIdentifier,
           bundleId == "com.growthlabs.growthmethod" {
            Logger.debug("Production bundle detected, skipping mock data generation")
            return
        }
        
        // Wait for authentication
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let userId = Auth.auth().currentUser?.uid else {
                Logger.debug("No authenticated user, skipping mock data generation")
                return
            }
            
            self?.checkAndPopulateMockData(userId: userId)
        }
        #endif
    }
    
    /// Check if mock data exists and populate if needed
    private func checkAndPopulateMockData(userId: String) {
        #if DEBUG
        // Check if user already has session data
        db.collection(sessionLogsCollection)
            .whereField("userId", isEqualTo: userId)
            .limit(to: 5)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    Logger.error("Error checking for existing data: \(error)")
                    return
                }
                
                let existingCount = snapshot?.documents.count ?? 0
                
                // Only generate mock data if user has fewer than 5 sessions
                if existingCount < 5 {
                    Logger.debug("User has \(existingCount) sessions, generating mock data...")
                    self?.generateMockSessions(userId: userId)
                } else {
                    Logger.debug("User already has \(existingCount) sessions, skipping mock data")
                }
            }
        #endif
    }
    
    /// Generate realistic mock sessions
    private func generateMockSessions(userId: String) {
        #if DEBUG
        let methods = [
            ("am1_0", "Angion Method 1.0"),
            ("am2_0", "Angion Method 2.0"),
            ("am3_0", "Angion Method 3.0"),
            ("sabre", "SABRE"),
            ("bfr", "BFR Training")
        ]
        
        let variations = ["Standard", "Modified", "Intensive", "Light Practice", "Extended Session"]
        
        let notes = [
            "Great session today! Felt strong throughout.",
            "Started slow but finished strong. Good progress.",
            "Technique is improving, feeling more confident.",
            "Slight fatigue but pushed through. Happy with the effort.",
            "Best session this week! Energy levels were high.",
            "Steady progress, maintaining good form.",
            "Focus on breathing really helped today.",
            "Consistent improvement in endurance.",
            "Good recovery from yesterday's session.",
            "Feeling the benefits, circulation improved.",
            nil, nil // Some sessions without notes
        ]
        
        let batch = db.batch()
        var sessionsGenerated = 0
        
        // Generate sessions for the past 30 days
        for daysAgo in stride(from: 0, through: 29, by: 1) {
            // Skip some days randomly (to simulate realistic practice patterns)
            if daysAgo > 0 && Int.random(in: 1...10) > 7 {
                continue
            }
            
            // Limit to 20 mock sessions
            if sessionsGenerated >= 20 {
                break
            }
            
            let sessionDate = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
            let startTime = randomTimeOnDate(sessionDate)
            let duration = Int.random(in: 8...35) // 8-35 minutes
            let endTime = startTime.addingTimeInterval(TimeInterval(duration * 60))
            
            let method = methods.randomElement()!
            let moodBefore = Mood.allCases.randomElement()!
            let moodAfter = improvedMood(from: moodBefore)
            
            let sessionId = UUID().uuidString
            let sessionData: [String: Any] = [
                "userId": userId,
                "duration": duration,
                "startTime": Timestamp(date: startTime),
                "endTime": Timestamp(date: endTime),
                "methodId": method.0,
                "sessionIndex": Int.random(in: 1...12),
                "moodBefore": moodBefore.rawValue,
                "moodAfter": moodAfter.rawValue,
                "intensity": Int.random(in: 4...8),
                "variation": variations.randomElement() ?? "Standard",
                "notes": notes.randomElement() as Any,
                "isMockData": true, // Flag to identify mock data
                "createdAt": Timestamp(date: Date())
            ]
            
            let docRef = db.collection(sessionLogsCollection).document(sessionId)
            batch.setData(sessionData, forDocument: docRef)
            sessionsGenerated += 1
        }
        
        // Commit the batch
        batch.commit { error in
            if let error = error {
                Logger.error("[DebugMockData] Error generating mock sessions: \(error)")
            } else {
                Logger.debug("[DebugMockData] ✅ Successfully generated \(sessionsGenerated) mock sessions")
                
                // Post notification that mock data was generated
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: Notification.Name("MockDataGenerated"),
                        object: nil,
                        userInfo: ["count": sessionsGenerated]
                    )
                }
            }
        }
        #endif
    }
    
    /// Generate a random time on a specific date (between 6 AM and 9 PM)
    private func randomTimeOnDate(_ date: Date) -> Date {
        let calendar = Calendar.current
        let hour = Int.random(in: 6...21)
        let minute = [0, 15, 30, 45].randomElement()!
        
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        components.second = 0
        
        return calendar.date(from: components) ?? date
    }
    
    /// Simulate mood improvement after a session
    private func improvedMood(from initial: Mood) -> Mood {
        switch initial {
        case .veryNegative:
            return [.negative, .neutral].randomElement()!
        case .negative:
            return [.negative, .neutral, .positive].randomElement()!
        case .neutral:
            return [.neutral, .positive, .veryPositive].randomElement()!
        case .positive:
            return [.positive, .veryPositive].randomElement()!
        case .veryPositive:
            return .veryPositive
        }
    }
    
    // MARK: - Gains Mock Data Generation
    
    /// Generate realistic gains measurement data
    private func generateMockGainsData(userId: String) {
        #if DEBUG
        Logger.debug("[DebugMockData] Generating mock gains data for user: \(userId)")
        
        let batch = db.batch()
        var entriesGenerated = 0
        var measurements: [(date: Date, length: Double, girth: Double, eq: Int)] = []
        
        // Starting baseline measurements
        let baselineLength = 5.5  // Starting at 5.5 inches
        let baselineGirth = 4.5   // Starting at 4.5 inches
        let baselineEQ = 7         // Starting EQ of 7
        
        // Total gains to achieve
        let totalLengthGain = Double.random(in: 0.3...0.5)
        let totalGirthGain = Double.random(in: 0.2...0.4)
        
        // Generate measurements over the past 60 days (one every 3-4 days)
        for dayIndex in stride(from: 60, through: 0, by: -3) {
            // Add some randomness to the interval
            let actualDaysAgo = dayIndex + Int.random(in: -1...1)
            guard actualDaysAgo >= 0 else { continue }
            
            let measurementDate = Calendar.current.date(byAdding: .day, value: -actualDaysAgo, to: Date())!
            
            // Calculate progressive gains with upward trend
            let progressFactor = Double(60 - actualDaysAgo) / 60.0  // 0 to 1 over time
            
            // For the last entry (most recent), ensure it's the best
            let variationFactor: Double
            if actualDaysAgo <= 2 {
                // Last entry should be at or above the trend line
                variationFactor = Double.random(in: 1.0...1.08)
            } else {
                // Normal variation for other entries
                variationFactor = Double.random(in: 0.92...1.02)
            }
            
            // Length gains with progressive improvement
            let lengthGain = progressFactor * totalLengthGain * variationFactor
            let currentLength = baselineLength + lengthGain
            
            // Girth gains with progressive improvement
            let girthGain = progressFactor * totalGirthGain * variationFactor
            let currentGirth = baselineGirth + girthGain
            
            // EQ improvement: 0-2 points over 60 days
            let eqImprovement = Int(progressFactor * Double.random(in: 0...2))
            let currentEQ = min(10, baselineEQ + eqImprovement)
            
            // Store measurement for later processing
            measurements.append((
                date: measurementDate,
                length: currentLength,
                girth: currentGirth,
                eq: currentEQ
            ))
            
            // Limit to 20 entries
            if measurements.count >= 20 {
                break
            }
        }
        
        // Sort measurements by date (oldest to newest)
        measurements.sort { $0.date < $1.date }
        
        // Ensure the last few measurements show clear progress
        if measurements.count > 3 {
            let lastIndex = measurements.count - 1
            let secondLastIndex = measurements.count - 2
            
            // Make sure the last measurement is the best
            let maxLength = measurements[0..<lastIndex].map { $0.length }.max() ?? baselineLength
            let maxGirth = measurements[0..<lastIndex].map { $0.girth }.max() ?? baselineGirth
            
            // Adjust the last measurement to be slightly better than previous best
            measurements[lastIndex].length = max(measurements[lastIndex].length, maxLength + 0.05)
            measurements[lastIndex].girth = max(measurements[lastIndex].girth, maxGirth + 0.03)
            
            // Ensure second-to-last is also good (but not as good as last)
            if secondLastIndex >= 0 {
                measurements[secondLastIndex].length = max(measurements[secondLastIndex].length, maxLength + 0.02)
                measurements[secondLastIndex].girth = max(measurements[secondLastIndex].girth, maxGirth + 0.01)
            }
        }
        
        // Now create the Firestore entries
        for measurement in measurements {
            let notes = [
                "Feeling good about progress",
                "Consistent improvement noticed",
                "Recovery seems faster",
                "Vascularity improving",
                "Morning quality better",
                "Good session today",
                "New personal best!",  // Add for recent entries
                "Excellent progress",
                nil, nil  // Some entries without notes
            ].randomElement() ?? nil
            
            let entryId = UUID().uuidString
            let entryData: [String: Any] = [
                "userId": userId,
                "timestamp": Timestamp(date: measurement.date),
                "length": measurement.length,
                "girth": measurement.girth,
                "erectionQuality": measurement.eq,
                "notes": notes as Any,
                "measurementUnit": "imperial",
                "isMockData": true,
                "createdAt": Timestamp(date: Date()),
                "updatedAt": Timestamp(date: Date())
            ]
            
            let docRef = db.collection(gainsCollection).document(entryId)
            batch.setData(entryData, forDocument: docRef)
            entriesGenerated += 1
        }
        
        // Commit the batch
        batch.commit { error in
            if let error = error {
                Logger.error("[DebugMockData] Error generating mock gains data: \(error)")
            } else {
                Logger.debug("[DebugMockData] ✅ Successfully generated \(entriesGenerated) mock gains entries")
                
                // Post notification that gains data was generated
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: Notification.Name("MockGainsDataGenerated"),
                        object: nil,
                        userInfo: ["count": entriesGenerated]
                    )
                }
            }
        }
        #endif
    }
    
    // MARK: - Force Regeneration
    
    /// Force regenerate mock data regardless of existing data
    func forceRegenerateMockData(completion: @escaping (Error?) -> Void) {
        #if DEBUG
        // Additional production safeguard
        if let bundleId = Bundle.main.bundleIdentifier,
           bundleId == "com.growthlabs.growthmethod" {
            completion(NSError(domain: "DebugMockDataService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Cannot generate mock data in production"]))
            return
        }
        
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "DebugMockDataService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"]))
            return
        }
        
        Logger.debug("[DebugMockData] Force regenerating mock data for user: \(userId)")
        
        // First clear existing mock data
        clearAllMockData { [weak self] error in
            if let error = error {
                Logger.error("[DebugMockData] Failed to clear existing mock data: \(error)")
                completion(error)
                return
            }
            
            // Generate both session and gains mock data
            self?.generateMockSessions(userId: userId)
            self?.generateMockGainsData(userId: userId)
            completion(nil)
        }
        #else
        completion(nil)
        #endif
    }
    
    // MARK: - Cleanup Methods
    
    /// Remove all mock data for the current user
    func clearAllMockData(completion: @escaping (Error?) -> Void) {
        #if DEBUG
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "DebugMockDataService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"]))
            return
        }
        
        let group = DispatchGroup()
        var clearErrors: [Error] = []
        
        // Clear mock session logs
        group.enter()
        db.collection(sessionLogsCollection)
            .whereField("userId", isEqualTo: userId)
            .whereField("isMockData", isEqualTo: true)
            .getDocuments { [weak self] snapshot, error in
                defer { group.leave() }
                
                if let error = error {
                    clearErrors.append(error)
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    Logger.debug("[DebugMockData] No mock session data to clear")
                    return
                }
                
                let batch = self?.db.batch()
                documents.forEach { document in
                    batch?.deleteDocument(document.reference)
                }
                
                batch?.commit { error in
                    if let error = error {
                        Logger.error("[DebugMockData] Error clearing mock sessions: \(error)")
                        clearErrors.append(error)
                    } else {
                        Logger.debug("[DebugMockData] ✅ Successfully cleared \(documents.count) mock sessions")
                    }
                }
            }
        
        // Clear mock gains data
        group.enter()
        db.collection(gainsCollection)
            .whereField("userId", isEqualTo: userId)
            .whereField("isMockData", isEqualTo: true)
            .getDocuments { [weak self] snapshot, error in
                defer { group.leave() }
                
                if let error = error {
                    clearErrors.append(error)
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    Logger.debug("[DebugMockData] No mock gains data to clear")
                    return
                }
                
                let batch = self?.db.batch()
                documents.forEach { document in
                    batch?.deleteDocument(document.reference)
                }
                
                batch?.commit { error in
                    if let error = error {
                        Logger.error("[DebugMockData] Error clearing mock gains: \(error)")
                        clearErrors.append(error)
                    } else {
                        Logger.debug("[DebugMockData] ✅ Successfully cleared \(documents.count) mock gains entries")
                    }
                }
            }
        
        // Wait for all operations to complete
        group.notify(queue: .main) {
            if !clearErrors.isEmpty {
                completion(clearErrors.first)
            } else {
                completion(nil)
            }
        }
        #else
        completion(nil)
        #endif
    }
    
    /// Check if current data includes mock data
    func hasMockData(completion: @escaping (Bool) -> Void) {
        #if DEBUG
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        
        let group = DispatchGroup()
        var hasSessionMockData = false
        var hasGainsMockData = false
        
        // Check for session mock data
        group.enter()
        db.collection(sessionLogsCollection)
            .whereField("userId", isEqualTo: userId)
            .whereField("isMockData", isEqualTo: true)
            .limit(to: 1)
            .getDocuments { snapshot, _ in
                hasSessionMockData = !(snapshot?.documents.isEmpty ?? true)
                group.leave()
            }
        
        // Check for gains mock data
        group.enter()
        db.collection(gainsCollection)
            .whereField("userId", isEqualTo: userId)
            .whereField("isMockData", isEqualTo: true)
            .limit(to: 1)
            .getDocuments { snapshot, _ in
                hasGainsMockData = !(snapshot?.documents.isEmpty ?? true)
                group.leave()
            }
        
        // Return true if either type of mock data exists
        group.notify(queue: .main) {
            completion(hasSessionMockData || hasGainsMockData)
        }
        #else
        completion(false)
        #endif
    }
}

// MARK: - UI Helper Extensions

extension DebugMockDataService {
    /// Returns true if running in debug mode
    var isDebugMode: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    /// Returns a badge view modifier for debug mode
    func debugBadge() -> some View {
        #if DEBUG
        return Text("DEBUG")
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(4)
        #else
        return EmptyView()
        #endif
    }
}