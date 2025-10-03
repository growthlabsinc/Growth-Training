# Community Routines Technical Implementation Guide

## MVP Implementation Steps

### Step 1: Update Data Models

#### 1.1 Enhance RoutineModel
```swift
// Growth/Core/Models/RoutineModel.swift

// Add to existing RoutineModel
extension RoutineModel {
    // Community metadata
    var creatorUsername: String?
    var creatorDisplayName: String?
    var sharedDate: Date?
    var downloadCount: Int = 0
    var reportCount: Int = 0
    var moderationStatus: String = "pending" // pending, approved, flagged, removed
    var isBlockedByUser: Bool = false // Client-side flag
}
```

#### 1.2 Update User Model
```swift
// Growth/Core/Models/User.swift

// Add to existing User model
extension User {
    var username: String? // Unique username for creators
    var displayName: String? // Public display name
    var blockedUserIds: [String] = [] // Users they've blocked
    var hasCreatedContent: Bool = false // Track if user has shared content
    var creatorStats: CreatorStats?
}

struct CreatorStats: Codable {
    let routinesShared: Int
    let totalDownloads: Int
    let firstSharedDate: Date?
}
```

### Step 2: Create Reporting Models

#### 2.1 Report Model
```swift
// Growth/Core/Models/Report.swift

import Foundation
import FirebaseFirestore

struct Report: Codable, Identifiable {
    @DocumentID var id: String?
    let reporterId: String
    let contentId: String
    let contentType: String // "routine"
    let creatorId: String
    let reason: ReportReason
    let details: String?
    let createdAt: Date
    let status: String // "pending", "resolved"
    
    enum ReportReason: String, CaseIterable, Codable {
        case inappropriate = "inappropriate"
        case spam = "spam"
        case misleading = "misleading"
        case copyright = "copyright"
        case other = "other"
        
        var displayName: String {
            switch self {
            case .inappropriate: return "Inappropriate Content"
            case .spam: return "Spam"
            case .misleading: return "Misleading Information"
            case .copyright: return "Copyright Violation"
            case .other: return "Other"
            }
        }
    }
}
```

### Step 3: Update RoutineService

#### 3.1 Add Community Methods
```swift
// Growth/Features/Routines/Services/RoutineService.swift

extension RoutineService {
    
    // Fetch community routines with blocking filter
    func fetchCommunityRoutines(excludeBlockedUsers: [String]) async throws -> [RoutineModel] {
        let db = Firestore.firestore()
        
        var query = db.collection("routines")
            .whereField("isCustom", isEqualTo: true)
            .whereField("shareWithCommunity", isEqualTo: true)
            .whereField("moderationStatus", isEqualTo: "approved")
        
        let snapshot = try await query.getDocuments()
        
        let routines = snapshot.documents.compactMap { doc -> RoutineModel? in
            guard var routine = try? doc.data(as: RoutineModel.self) else { return nil }
            
            // Filter out blocked creators
            if let creatorId = routine.createdBy,
               excludeBlockedUsers.contains(creatorId) {
                return nil
            }
            
            return routine
        }
        
        return routines.sorted { ($0.sharedDate ?? Date.distantPast) > ($1.sharedDate ?? Date.distantPast) }
    }
    
    // Share routine to community
    func shareRoutineWithCommunity(_ routine: RoutineModel, username: String, displayName: String) async throws {
        let db = Firestore.firestore()
        
        var sharedRoutine = routine
        sharedRoutine.shareWithCommunity = true
        sharedRoutine.creatorUsername = username
        sharedRoutine.creatorDisplayName = displayName
        sharedRoutine.sharedDate = Date()
        sharedRoutine.moderationStatus = "pending"
        
        // Save to main routines collection
        try await db.collection("routines").document(routine.id).setData(sharedRoutine.toDictionary())
        
        // Update user's creator stats
        try await updateCreatorStats(for: routine.createdBy ?? "")
    }
    
    // Report a routine
    func reportRoutine(_ routineId: String, reason: Report.ReportReason, details: String?) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { throw CustomError.unauthorized }
        
        let db = Firestore.firestore()
        
        // Get routine details
        let routine = try await db.collection("routines").document(routineId).getDocument(as: RoutineModel.self)
        
        let report = Report(
            reporterId: userId,
            contentId: routineId,
            contentType: "routine",
            creatorId: routine.createdBy ?? "",
            reason: reason,
            details: details,
            createdAt: Date(),
            status: "pending"
        )
        
        // Save report
        try await db.collection("reports").addDocument(data: report.toDictionary())
        
        // Increment report count
        try await db.collection("routines").document(routineId).updateData([
            "reportCount": FieldValue.increment(Int64(1))
        ])
    }
}
```

### Step 4: Create User Blocking Service

#### 4.1 BlockingService
```swift
// Growth/Core/Services/BlockingService.swift

import Foundation
import FirebaseFirestore
import FirebaseAuth

class BlockingService: ObservableObject {
    static let shared = BlockingService()
    
    @Published var blockedUserIds: Set<String> = []
    
    private init() {
        loadBlockedUsers()
    }
    
    func loadBlockedUsers() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        UserService.shared.fetchUser(userId: userId) { result in
            if case .success(let user) = result {
                self.blockedUserIds = Set(user.blockedUserIds ?? [])
            }
        }
    }
    
    func blockUser(_ blockedUserId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { throw CustomError.unauthorized }
        
        let db = Firestore.firestore()
        
        try await db.collection("users").document(userId).updateData([
            "blockedUserIds": FieldValue.arrayUnion([blockedUserId])
        ])
        
        blockedUserIds.insert(blockedUserId)
    }
    
    func unblockUser(_ blockedUserId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { throw CustomError.unauthorized }
        
        let db = Firestore.firestore()
        
        try await db.collection("users").document(userId).updateData([
            "blockedUserIds": FieldValue.arrayRemove([blockedUserId])
        ])
        
        blockedUserIds.remove(blockedUserId)
    }
    
    func isUserBlocked(_ userId: String) -> Bool {
        return blockedUserIds.contains(userId)
    }
}
```

### Step 5: Update UI Components

#### 5.1 Update BrowseRoutinesView
```swift
// Growth/Features/Routines/Views/BrowseRoutinesView.swift

// Add to RoutineCategory enum
case community = "Community"

// Add to categoryIcon computed property
case .community:
    return "person.2.fill"

// Update fetchRoutines() method
private func fetchRoutines() {
    Task {
        do {
            switch selectedCategory {
            case .community:
                let blockedUsers = Array(BlockingService.shared.blockedUserIds)
                let communityRoutines = try await routineService.fetchCommunityRoutines(
                    excludeBlockedUsers: blockedUsers
                )
                await MainActor.run {
                    self.filteredRoutines = communityRoutines
                }
            // ... existing cases
            }
        } catch {
            print("Error fetching routines: \(error)")
        }
    }
}

// Add community badge to routine cards
private func routineCard(_ routine: RoutineModel) -> some View {
    // ... existing card code
    
    // Add community indicator
    if routine.shareWithCommunity == true {
        HStack {
            Image(systemName: "person.2.fill")
                .font(.caption2)
            Text("by \(routine.creatorUsername ?? "Unknown")")
                .font(.caption)
                .lineLimit(1)
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(4)
    }
}
```

#### 5.2 Create Report Sheet
```swift
// Growth/Features/Routines/Views/ReportRoutineSheet.swift

import SwiftUI

struct ReportRoutineSheet: View {
    let routine: RoutineModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason: Report.ReportReason?
    @State private var additionalDetails = ""
    @State private var isSubmitting = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Why are you reporting this routine?") {
                    ForEach(Report.ReportReason.allCases, id: \.self) { reason in
                        Button(action: {
                            selectedReason = reason
                        }) {
                            HStack {
                                Text(reason.displayName)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedReason == reason {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
                
                Section("Additional Details (Optional)") {
                    TextEditor(text: $additionalDetails)
                        .frame(minHeight: 100)
                }
                
                Section {
                    Text("Reports are reviewed by our moderation team. False reports may result in action against your account.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Report Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") {
                        submitReport()
                    }
                    .disabled(selectedReason == nil || isSubmitting)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func submitReport() {
        guard let reason = selectedReason else { return }
        
        isSubmitting = true
        
        Task {
            do {
                try await RoutineService.shared.reportRoutine(
                    routine.id,
                    reason: reason,
                    details: additionalDetails.isEmpty ? nil : additionalDetails
                )
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isSubmitting = false
                }
            }
        }
    }
}
```

#### 5.3 Update RoutineDetailView
```swift
// Growth/Features/Routines/Views/RoutineDetailView.swift

// Add menu button to toolbar
.toolbar {
    if routine.shareWithCommunity == true {
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Button(action: {
                    showingReportSheet = true
                }) {
                    Label("Report", systemImage: "exclamationmark.triangle")
                }
                
                if let creatorId = routine.createdBy {
                    Button(action: {
                        blockCreator(creatorId)
                    }) {
                        Label("Block Creator", systemImage: "person.crop.circle.badge.xmark")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
}
.sheet(isPresented: $showingReportSheet) {
    ReportRoutineSheet(routine: routine)
}

// Add creator info section
if routine.shareWithCommunity == true {
    VStack(alignment: .leading, spacing: 8) {
        Text("Created by")
            .font(.caption)
            .foregroundColor(.secondary)
        
        HStack {
            Image(systemName: "person.circle.fill")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading) {
                Text(routine.creatorDisplayName ?? "Unknown Creator")
                    .font(.headline)
                Text("@\(routine.creatorUsername ?? "unknown")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let downloads = routine.downloadCount, downloads > 0 {
                VStack(alignment: .trailing) {
                    Text("\(downloads)")
                        .font(.headline)
                    Text("Downloads")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    .padding(.horizontal)
}
```

### Step 6: Update CreateCustomRoutineView

#### 6.1 Add Community Sharing Toggle
```swift
// Growth/Features/Routines/Views/CreateCustomRoutineView.swift

// Add to state variables
@State private var shareWithCommunity = false
@State private var showingUsernameCreation = false
@State private var username = ""
@State private var displayName = ""

// Add to form sections
Section {
    Toggle("Share with Community", isOn: $shareWithCommunity)
    
    if shareWithCommunity {
        Text("Your routine will be visible to all Growth users after moderation approval.")
            .font(.caption)
            .foregroundColor(.secondary)
        
        // Check if user has username
        if userData?.username == nil {
            Button("Set Creator Username") {
                showingUsernameCreation = true
            }
            .foregroundColor(.accentColor)
        }
    }
} header: {
    Text("Community Sharing")
} footer: {
    if shareWithCommunity {
        Text("By sharing, you agree to our Community Guidelines and Terms of Service.")
            .font(.caption2)
    }
}

// Update save method
private func saveRoutine() async {
    // ... existing validation
    
    if shareWithCommunity {
        // Ensure user has username
        guard userData?.username != nil else {
            showingUsernameCreation = true
            return
        }
        
        try await routineService.shareRoutineWithCommunity(
            newRoutine,
            username: userData?.username ?? "",
            displayName: userData?.displayName ?? userData?.firstName ?? ""
        )
    } else {
        // Save privately as before
        try await routineService.saveCustomRoutine(newRoutine)
    }
}

// Add username creation sheet
.sheet(isPresented: $showingUsernameCreation) {
    CreateUsernameView { username, displayName in
        // Save username to user profile
        Task {
            try await UserService.shared.updateUsername(username, displayName: displayName)
            await loadUserData()
        }
    }
}
```

### Step 7: Create Admin Functions

#### 7.1 Cloud Functions for Moderation
```javascript
// functions/moderation.js

const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Auto-moderate new community routines
exports.moderateNewRoutine = functions.firestore
    .document('routines/{routineId}')
    .onCreate(async (snap, context) => {
        const routine = snap.data();
        
        if (!routine.shareWithCommunity) return;
        
        // Basic profanity check
        const profanityList = ['badword1', 'badword2']; // Replace with actual list
        const textToCheck = `${routine.name} ${routine.description}`.toLowerCase();
        
        const containsProfanity = profanityList.some(word => 
            textToCheck.includes(word)
        );
        
        if (containsProfanity) {
            await snap.ref.update({
                moderationStatus: 'flagged',
                moderationReason: 'profanity'
            });
        } else {
            // Auto-approve if passes basic checks
            await snap.ref.update({
                moderationStatus: 'approved'
            });
        }
    });

// Process reports
exports.processReport = functions.firestore
    .document('reports/{reportId}')
    .onCreate(async (snap, context) => {
        const report = snap.data();
        const routineRef = admin.firestore()
            .collection('routines')
            .doc(report.contentId);
        
        const routine = await routineRef.get();
        const currentReports = routine.data().reportCount || 0;
        
        // Auto-flag if reaches threshold
        if (currentReports >= 3) {
            await routineRef.update({
                moderationStatus: 'flagged',
                flaggedAt: admin.firestore.FieldValue.serverTimestamp()
            });
        }
    });

// Admin function to ban user
exports.banUser = functions.https.onCall(async (data, context) => {
    // Verify admin
    if (!context.auth.token.admin) {
        throw new functions.https.HttpsError(
            'permission-denied',
            'Must be an admin'
        );
    }
    
    const { userId, reason } = data;
    
    // Add to banned users
    await admin.firestore()
        .collection('moderation')
        .doc('bannedUsers')
        .update({
            [userId]: {
                bannedAt: admin.firestore.FieldValue.serverTimestamp(),
                reason: reason,
                bannedBy: context.auth.uid
            }
        });
    
    // Remove all their content
    const routines = await admin.firestore()
        .collection('routines')
        .where('createdBy', '==', userId)
        .get();
    
    const batch = admin.firestore().batch();
    routines.forEach(doc => {
        batch.update(doc.ref, {
            moderationStatus: 'removed',
            removedReason: 'user_banned'
        });
    });
    
    await batch.commit();
    
    return { success: true };
});
```

### Step 8: Update Firestore Rules

```javascript
// firestore.rules

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isSignedIn() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }
    
    function isBanned() {
      return exists(/databases/$(database)/documents/moderation/bannedUsers/$(request.auth.uid));
    }
    
    // Routines with community sharing
    match /routines/{routineId} {
      allow read: if isSignedIn();
      
      allow create: if isSignedIn() 
        && request.resource.data.createdBy == request.auth.uid
        && !isBanned();
      
      allow update: if isOwner(resource.data.createdBy)
        && !isBanned()
        && request.resource.data.diff(resource.data).affectedKeys()
            .hasOnly(['name', 'description', 'stages', 'shareWithCommunity']);
      
      allow delete: if isOwner(resource.data.createdBy);
    }
    
    // Reports
    match /reports/{reportId} {
      allow read: if isOwner(resource.data.reporterId) 
        || request.auth.token.admin == true;
      
      allow create: if isSignedIn()
        && request.resource.data.reporterId == request.auth.uid
        && !isBanned();
    }
    
    // User blocking
    match /users/{userId} {
      allow update: if isOwner(userId)
        && request.resource.data.diff(resource.data).affectedKeys()
            .hasOnly(['blockedUserIds']);
    }
  }
}
```

## Testing Checklist

### Unit Tests
- [ ] Report submission with all reason types
- [ ] User blocking/unblocking
- [ ] Community routine filtering
- [ ] Moderation status updates

### Integration Tests
- [ ] End-to-end sharing flow
- [ ] Report submission and processing
- [ ] Block user and content hiding
- [ ] Creator profile updates

### Manual Testing
- [ ] Create and share routine
- [ ] Browse community routines
- [ ] Report inappropriate content
- [ ] Block/unblock creators
- [ ] Verify content filtering

## Deployment Steps

1. **Update Firestore indexes**
   ```
   firebase deploy --only firestore:indexes
   ```

2. **Deploy security rules**
   ```
   firebase deploy --only firestore:rules
   ```

3. **Deploy Cloud Functions**
   ```
   firebase deploy --only functions
   ```

4. **Update app with feature flag**
   ```swift
   if FeatureFlags.communityRoutinesEnabled {
       // Show community features
   }
   ```

5. **Monitor and iterate**
   - Watch error logs
   - Monitor report rates
   - Gather user feedback