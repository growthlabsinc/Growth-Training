import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Facade service for Goal CRUD operations.
final class GoalService {
    static let shared = GoalService()
    private init() {}

    private let firestore = FirestoreService.shared

    // MARK: - CRUD
    func createGoal(_ goal: Goal, completion: @escaping (Bool, Error?) -> Void) {
        var g = goal
        // Ensure current user
        guard Auth.auth().currentUser != nil else {
            completion(false, NSError(domain: "GoalService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
            return
        }
        g.id = g.id ?? UUID().uuidString
        g.createdAt = Date()
        g.updatedAt = Date()
        let data = g.toFirestore
        firestore.db.collection("goals").document(g.id!).setData(data) { error in
            completion(error == nil, error)
        }
    }

    func updateGoal(_ goal: Goal, completion: @escaping (Bool, Error?) -> Void) {
        guard let id = goal.id else { completion(false, NSError(domain: "GoalService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Goal missing ID"])); return }
        var g = goal
        g.updatedAt = Date()
        firestore.db.collection("goals").document(id).setData(g.toFirestore, merge: true) { error in
            completion(error == nil, error)
        }
    }

    func deleteGoal(_ goalId: String, completion: @escaping (Bool, Error?) -> Void) {
        firestore.db.collection("goals").document(goalId).delete { error in
            completion(error == nil, error)
        }
    }

    func fetchGoalsForCurrentUser(completion: @escaping ([Goal], Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion([], NSError(domain: "GoalService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
            return
        }
        firestore.db.collection("goals")
            .whereField("userId", isEqualTo: uid)
            .order(by: "createdAt", descending: false)
            .getDocuments { snap, error in
                if let error = error {
                    completion([], error)
                    return
                }
                let goals = snap?.documents.compactMap { Goal(document: $0) } ?? []
                completion(goals, nil)
            }
    }

    func fetchGoals(forMethodId methodId: String, completion: @escaping ([Goal], Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion([], NSError(domain: "GoalService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
            return
        }
        firestore.db.collection("goals")
            .whereField("userId", isEqualTo: uid)
            .whereField("associatedMethodIds", arrayContains: methodId)
            .getDocuments { snap, error in
                if let error = error {
                    completion([], error)
                    return
                }
                let goals = snap?.documents.compactMap { Goal(document: $0) } ?? []
                completion(goals, nil)
            }
    }

    // MARK: - Progress Updates
    /// Increment a goal's current value by a given amount and automatically mark completion if target reached.
    /// - Parameters:
    ///   - goalId: The goal's document ID.
    ///   - amount: Amount to increment the currentValue by (can be negative for corrections).
    ///   - completion: Completion callback with success flag and optional error.
    func incrementGoalProgress(goalId: String, amount: Double, completion: @escaping (Bool, Error?) -> Void) {
        let goalRef = firestore.db.collection("goals").document(goalId)
        firestore.db.runTransaction({ (transaction, errorPointer) -> Any? in
            let document: DocumentSnapshot
            do {
                try document = transaction.getDocument(goalRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }
            guard var goal = Goal(document: document) else {
                errorPointer?.pointee = NSError(domain: "GoalService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to parse goal data"])
                return nil
            }
            // Update progress
            goal.currentValue += amount
            if goal.currentValue < 0 { goal.currentValue = 0 }
            // Clamp to target
            if goal.currentValue >= goal.targetValue {
                goal.currentValue = goal.targetValue
                // Mark completed if not already
                if goal.completedAt == nil {
                    goal.completedAt = Date()
                }
            }
            goal.updatedAt = Date()
            // Write back updated data
            transaction.setData(goal.toFirestore, forDocument: goalRef, merge: true)
            return nil
        }) { (_, error) in
            completion(error == nil, error)
        }
    }

    /// Set a goal's current value explicitly (e.g., after recalculation).
    func setGoalProgress(goalId: String, newValue: Double, completion: @escaping (Bool, Error?) -> Void) {
        var value = newValue
        if value < 0 { value = 0 }
        let goalRef = firestore.db.collection("goals").document(goalId)
        goalRef.updateData([
            "currentValue": value,
            "updatedAt": Timestamp(date: Date())
        ]) { error in
            completion(error == nil, error)
        }
    }
} 