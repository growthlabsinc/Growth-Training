//
//  SessionService.swift
//  Growth
//
//  Service for managing practice session data including logging and retrieval
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class SessionService {
    // MARK: - Properties
    
    static let shared = SessionService()
    
    private let firestoreService = FirestoreService.shared
    private let db = Firestore.firestore()
    private let sessionLogsCollection = "sessionLogs"
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Session Management
    
    /// Save a session log to Firestore
    /// - Parameters:
    ///   - sessionLog: The session log to save
    ///   - completion: Completion handler with optional error
    func saveSessionLog(_ sessionLog: SessionLog, completion: @escaping (Error?) -> Void) {
        // Ensure we have a valid user ID
        guard !sessionLog.userId.isEmpty else {
            completion(NSError(domain: "SessionService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid user ID"]))
            return
        }
        
        // Use FirestoreService to save the session log
        firestoreService.saveSessionLog(log: sessionLog) { error in
            if let error = error {
                completion(error)
            } else {
                
                // Post notification for session log creation
                NotificationCenter.default.post(name: .sessionLogCreated, object: sessionLog)
                
                completion(nil)
            }
        }
    }
    
    /// Fetch session logs for a user
    /// - Parameters:
    ///   - userId: The user ID to fetch logs for
    ///   - limit: Maximum number of logs to return (default 50)
    ///   - completion: Completion handler with array of session logs and optional error
    func fetchSessionLogs(userId: String, limit: Int = 50, completion: @escaping ([SessionLog], Error?) -> Void) {
        guard !userId.isEmpty else {
            completion([], NSError(domain: "SessionService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid user ID"]))
            return
        }
        
        db.collection(sessionLogsCollection)
            .whereField("userId", isEqualTo: userId)
            .order(by: "endTime", descending: true)
            .limit(to: limit)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion([], error)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion([], nil)
                    return
                }
                
                let sessionLogs = documents.compactMap { SessionLog(document: $0) }
                completion(sessionLogs, nil)
            }
    }
    
    /// Fetch session logs for a specific date range
    /// - Parameters:
    ///   - userId: The user ID to fetch logs for
    ///   - startDate: The start date of the range
    ///   - endDate: The end date of the range
    ///   - completion: Completion handler with array of session logs and optional error
    func fetchSessionLogs(userId: String, from startDate: Date, to endDate: Date, completion: @escaping ([SessionLog], Error?) -> Void) {
        firestoreService.getSessionLogsForDateRange(userId: userId, startDate: startDate, endDate: endDate, completion: completion)
    }
    
    /// Fetch a specific session log by ID
    /// - Parameters:
    ///   - logId: The session log ID
    ///   - completion: Completion handler with optional session log and error
    func fetchSessionLog(logId: String, completion: @escaping (SessionLog?, Error?) -> Void) {
        firestoreService.getSessionLog(logId: logId, completion: completion)
    }
    
    /// Delete a session log
    /// - Parameters:
    ///   - logId: The session log ID to delete
    ///   - completion: Completion handler with optional error
    func deleteSessionLog(logId: String, completion: @escaping (Error?) -> Void) {
        firestoreService.deleteSessionLog(logId: logId) { error in
            if let error = error {
                completion(error)
            } else {
                
                // Post notification for session log deletion
                NotificationCenter.default.post(name: .sessionLogDeleted, object: logId)
                
                completion(nil)
            }
        }
    }
    
    /// Update an existing session log
    /// - Parameters:
    ///   - sessionLog: The updated session log
    ///   - completion: Completion handler with optional error
    func updateSessionLog(_ sessionLog: SessionLog, completion: @escaping (Error?) -> Void) {
        // For updates, we just save the session log again (Firestore will overwrite)
        saveSessionLog(sessionLog) { error in
            if error == nil {
                // Post notification for session log update
                NotificationCenter.default.post(name: .sessionLogUpdated, object: sessionLog)
            }
            completion(error)
        }
    }
    
    // MARK: - Statistics and Aggregation
    
    /// Get total practice time for a user
    /// - Parameters:
    ///   - userId: The user ID
    ///   - completion: Completion handler with total minutes and optional error
    func getTotalPracticeTime(userId: String, completion: @escaping (Int, Error?) -> Void) {
        guard !userId.isEmpty else {
            completion(0, NSError(domain: "SessionService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid user ID"]))
            return
        }
        
        db.collection(sessionLogsCollection)
            .whereField("userId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(0, error)
                    return
                }
                
                let totalMinutes = snapshot?.documents.compactMap { SessionLog(document: $0) }
                    .reduce(0) { $0 + $1.duration } ?? 0
                
                completion(totalMinutes, nil)
            }
    }
    
    /// Get session count for a user
    /// - Parameters:
    ///   - userId: The user ID
    ///   - methodId: Optional method ID to filter by
    ///   - completion: Completion handler with session count and optional error
    func getSessionCount(userId: String, methodId: String? = nil, completion: @escaping (Int, Error?) -> Void) {
        guard !userId.isEmpty else {
            completion(0, NSError(domain: "SessionService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid user ID"]))
            return
        }
        
        var query = db.collection(sessionLogsCollection)
            .whereField("userId", isEqualTo: userId)
        
        if let methodId = methodId {
            query = query.whereField("methodId", isEqualTo: methodId)
        }
        
        query.getDocuments { snapshot, error in
            if let error = error {
                completion(0, error)
                return
            }
            
            completion(snapshot?.documents.count ?? 0, nil)
        }
    }
    
    /// Get the most recent session for a user
    /// - Parameters:
    ///   - userId: The user ID
    ///   - completion: Completion handler with optional session log and error
    func getMostRecentSession(userId: String, completion: @escaping (SessionLog?, Error?) -> Void) {
        guard !userId.isEmpty else {
            completion(nil, NSError(domain: "SessionService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid user ID"]))
            return
        }
        
        db.collection(sessionLogsCollection)
            .whereField("userId", isEqualTo: userId)
            .order(by: "endTime", descending: true)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                if let document = snapshot?.documents.first,
                   let sessionLog = SessionLog(document: document) {
                    completion(sessionLog, nil)
                } else {
                    completion(nil, nil)
                }
            }
    }
}

// MARK: - Notification Names
// Note: sessionLogCreated, sessionLogUpdated, and sessionLogDeleted are defined in other ViewModels