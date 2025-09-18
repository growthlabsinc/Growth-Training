import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth
import FirebaseFunctions

/// Debug service to verify Live Activity and Firebase integration
class LiveActivityDebugger {
    static let shared = LiveActivityDebugger()
    
    private let db = Firestore.firestore()
    private let functions = Functions.functions()
    
    private init() {}
    
    /// Comprehensive debug check for Live Activity setup
    func performDebugCheck() async {
        print("\n🔍 ========== LIVE ACTIVITY DEBUG CHECK ==========")
        
        // 1. Check user authentication
        await checkAuthentication()
        
        // 2. Check Firestore collections
        await checkFirestoreCollections()
        
        // 3. Check Cloud Functions
        await checkCloudFunctions()
        
        // 4. Check Live Activity status
        if #available(iOS 16.1, *) {
            LiveActivityManager.shared.debugPrintCurrentState()
        }
        
        print("================================================\n")
    }
    
    private func checkAuthentication() async {
        print("\n🔐 Authentication Check:")
        if let user = Auth.auth().currentUser {
            print("  ✅ User authenticated")
            print("  - UID: \(user.uid)")
            print("  - Email: \(user.email ?? "No email")")
            print("  - Anonymous: \(user.isAnonymous)")
        } else {
            print("  ❌ No authenticated user")
        }
    }
    
    private func checkFirestoreCollections() async {
        print("\n📚 Firestore Collections Check:")
        
        guard let userId = Auth.auth().currentUser?.uid else {
            print("  ❌ Cannot check - no authenticated user")
            return
        }
        
        // Check activeTimers collection
        print("\n  📁 activeTimers collection:")
        do {
            let activeTimerDoc = try await db.collection("activeTimers").document(userId).getDocument()
            if activeTimerDoc.exists {
                print("    ✅ Document exists")
                if let data = activeTimerDoc.data() {
                    print("    - Data: \(data)")
                }
            } else {
                print("    ⚠️ No document found for user")
            }
        } catch {
            print("    ❌ Error reading activeTimers: \(error)")
        }
        
        // Check liveActivityTokens collection
        print("\n  📁 liveActivityTokens collection:")
        do {
            let tokens = try await db.collection("liveActivityTokens")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()
            
            print("    - Found \(tokens.documents.count) tokens")
            for doc in tokens.documents {
                print("    - Token document ID: \(doc.documentID)")
                let data = doc.data()
                print("      - Push token: \(data["pushToken"] ?? "None")")
                print("      - Method: \(data["methodName"] ?? "None")")
            }
        } catch {
            print("    ❌ Error reading liveActivityTokens: \(error)")
        }
    }
    
    private func checkCloudFunctions() async {
        print("\n☁️ Cloud Functions Check:")
        
        // Test if functions are reachable
        print("  - Testing updateLiveActivityTimer function...")
        
        let testData = [
            "activityId": "test-debug-\(UUID().uuidString)",
            "action": "ping"
        ]
        
        do {
            let result = try await functions.httpsCallable("updateLiveActivityTimer").call(testData)
            print("    ✅ Function is reachable")
            if let data = result.data as? [String: Any] {
                print("    - Response: \(data)")
            }
        } catch {
            print("    ❌ Function call failed: \(error)")
            if let functionsError = error as NSError? {
                print("    - Error code: \(functionsError.code)")
                print("    - Error domain: \(functionsError.domain)")
                print("    - Error details: \(functionsError.userInfo)")
            }
        }
    }
    
    /// Test sending a push update manually
    func testPushUpdate(activityId: String, action: String) async {
        print("\n📤 Testing Push Update:")
        print("  - Activity ID: \(activityId)")
        print("  - Action: \(action)")
        
        let data = [
            "activityId": activityId,
            "action": action,
            "endTime": ISO8601DateFormatter().string(from: Date().addingTimeInterval(300))
        ]
        
        do {
            print("  - Calling updateLiveActivityTimer...")
            let result = try await functions.httpsCallable("updateLiveActivityTimer").call(data)
            print("  ✅ Push update sent successfully")
            if let responseData = result.data as? [String: Any] {
                print("  - Response: \(responseData)")
            }
        } catch {
            print("  ❌ Push update failed: \(error)")
        }
    }
}