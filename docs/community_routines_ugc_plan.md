# Community Routines UGC Implementation Plan

## Executive Summary

This document outlines the comprehensive plan for implementing user-generated content (UGC) functionality for community-shared routines in the Growth app. The implementation includes content sharing, discovery, moderation, and safety features required for Apple App Store compliance.

## 1. Core Requirements

### 1.1 Functional Requirements
- Users can toggle custom routines to share with community
- Community routines appear in Browse section under "Community" category
- Users can report inappropriate content
- Users can block content from specific creators
- Admins can moderate content and block users
- Content filtering and safety measures

### 1.2 Apple App Store Requirements
- Clear reporting mechanism for inappropriate content
- Ability to block users and their content
- Content moderation system
- Clear community guidelines
- Age-appropriate content filtering
- Privacy protection for users

## 2. Data Model Updates

### 2.1 Enhanced Routine Model
```swift
// Additional fields for RoutineModel
struct RoutineModel {
    // Existing fields...
    
    // UGC Enhancement fields
    var communityMetadata: CommunityMetadata?
    var moderationStatus: ModerationStatus = .pending
    var reportCount: Int = 0
    var downloadCount: Int = 0
    var rating: Double?
    var ratingCount: Int = 0
    var tags: [String] = []
    var version: Int = 1
}

struct CommunityMetadata {
    let creatorUsername: String
    let creatorDisplayName: String
    let creatorPhotoURL: String?
    let sharedDate: Date
    let lastModified: Date
    let isVerifiedCreator: Bool = false
}

enum ModerationStatus: String, CaseIterable {
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"
    case flagged = "flagged"
    case removed = "removed"
}
```

### 2.2 User Model Enhancements
```swift
// Additional fields for User model
struct User {
    // Existing fields...
    
    // Creator profile
    var creatorProfile: CreatorProfile?
    var blockedUsers: [String] = []
    var blockedByUsers: [String] = []
    var reportedContent: [String] = []
    var moderationFlags: [ModerationFlag] = []
}

struct CreatorProfile {
    let username: String // Unique, immutable
    let displayName: String
    let bio: String?
    let photoURL: String?
    let joinedDate: Date
    let routinesShared: Int = 0
    let totalDownloads: Int = 0
    let averageRating: Double = 0
    let isVerified: Bool = false
    let isBanned: Bool = false
}
```

### 2.3 Reporting System Models
```swift
struct ContentReport {
    let id: String
    let reporterId: String
    let contentId: String
    let contentType: ContentType
    let creatorId: String
    let reason: ReportReason
    let additionalDetails: String?
    let reportDate: Date
    let status: ReportStatus
    let moderatorId: String?
    let moderatorAction: ModeratorAction?
    let resolutionDate: Date?
}

enum ReportReason: String, CaseIterable {
    case inappropriate = "inappropriate"
    case spam = "spam"
    case misleading = "misleading"
    case harmful = "harmful"
    case copyright = "copyright"
    case other = "other"
}

enum ReportStatus: String {
    case pending = "pending"
    case reviewing = "reviewing"
    case resolved = "resolved"
    case dismissed = "dismissed"
}

enum ModeratorAction: String {
    case contentRemoved = "content_removed"
    case contentApproved = "content_approved"
    case userWarned = "user_warned"
    case userBanned = "user_banned"
    case noAction = "no_action"
}
```

## 3. Firestore Schema Updates

### 3.1 Collections Structure
```
/routines/
  - {routineId}
    - All routine fields
    - communityMetadata (subcollection)
    - reports (subcollection)

/users/
  - {userId}
    - User fields
    - creatorProfile (document)
    - blockedUsers (array)
    - customRoutines/ (existing)

/reports/
  - {reportId}
    - Full report details
    - Indexed by contentId, reporterId, status

/moderation/
  - queue/ (pending items)
  - history/ (resolved items)
  - bannedUsers/ (banned user list)

/communityStats/
  - routineStats/ (download counts, ratings)
  - creatorStats/ (creator metrics)
```

### 3.2 Security Rules Updates
```javascript
// Community routine creation
match /routines/{routineId} {
  allow read: if request.auth != null;
  allow create: if request.auth != null 
    && request.resource.data.createdBy == request.auth.uid
    && request.resource.data.isCustom == true
    && request.resource.data.shareWithCommunity == true
    && !exists(/databases/$(database)/documents/moderation/bannedUsers/$(request.auth.uid));
  allow update: if request.auth.uid == resource.data.createdBy
    && !exists(/databases/$(database)/documents/moderation/bannedUsers/$(request.auth.uid));
}

// Reporting system
match /reports/{reportId} {
  allow read: if request.auth.uid == resource.data.reporterId 
    || request.auth.token.admin == true;
  allow create: if request.auth != null
    && request.resource.data.reporterId == request.auth.uid;
}

// User blocking
match /users/{userId} {
  allow update: if request.auth.uid == userId
    && (!request.resource.data.diff(resource.data).affectedKeys()
        .hasAny(['blockedUsers']));
}
```

## 4. Feature Implementation Plan

### 4.1 Phase 1: Foundation (Week 1-2)
1. **Data Model Updates**
   - Update User model with creator profile
   - Add community metadata to Routine model
   - Create reporting data models
   - Update Firestore schema

2. **Creator Profile System**
   - Username validation and uniqueness
   - Profile creation flow
   - Display name and bio
   - Creator statistics tracking

### 4.2 Phase 2: Sharing & Discovery (Week 3-4)
1. **Routine Sharing**
   - Update CreateCustomRoutineView with enhanced sharing toggle
   - Add creator attribution
   - Implement version control
   - Add tags and categories

2. **Browse Community Routines**
   - Add "Community" tab to BrowseRoutinesView
   - Implement sorting (newest, popular, top-rated)
   - Creator info display on routine cards
   - Search by creator or tags

### 4.3 Phase 3: Safety & Moderation (Week 5-6)
1. **Reporting System**
   - Report button on routine detail view
   - Report reason selection sheet
   - Report submission and tracking
   - User notification system

2. **Blocking System**
   - Block user functionality
   - Hide content from blocked users
   - Manage blocked users list
   - Sync across devices

### 4.4 Phase 4: Admin Tools (Week 7-8)
1. **Moderation Dashboard (Web)**
   - Report queue management
   - Content review interface
   - User management (warn/ban)
   - Analytics dashboard

2. **Auto-Moderation**
   - Profanity filter
   - Spam detection
   - Suspicious pattern detection
   - Rate limiting

## 5. UI/UX Updates

### 5.1 Community Routines Browse
```swift
// BrowseRoutinesView updates
enum RoutineCategory {
    case all
    case featured
    case beginner
    case intermediate
    case advanced
    case custom
    case community // New
}

// Community routine card additions
- Creator username badge
- Download count
- Rating stars
- "Community" label
- Report button (3-dot menu)
```

### 5.2 Routine Detail View Updates
```swift
// Additional UI elements
- Creator profile section
  - Username, avatar
  - "View Profile" button
  - Total routines shared
  - Average rating
- Action buttons
  - Download/Save
  - Rate
  - Share
  - Report (in menu)
- Community stats
  - Downloads
  - Rating
  - Last updated
```

### 5.3 Reporting Flow
```swift
// Report sheet design
1. Select reason (radio buttons)
2. Optional details (text field)
3. Submit button
4. Confirmation message
```

### 5.4 Creator Profile View
```swift
// New view: CreatorProfileView
- Header with avatar, name, bio
- Statistics (routines, downloads, rating)
- List of shared routines
- Follow button (future feature)
- Block user option (3-dot menu)
```

## 6. Firebase Functions

### 6.1 Required Cloud Functions
```javascript
// Content moderation
exports.moderateContent = functions.firestore
  .document('routines/{routineId}')
  .onCreate(async (snap, context) => {
    // Auto-moderation checks
    // Profanity filter
    // Spam detection
    // Flag for manual review if needed
  });

// Report processing
exports.processReport = functions.firestore
  .document('reports/{reportId}')
  .onCreate(async (snap, context) => {
    // Increment report count
    // Auto-hide if threshold reached
    // Notify moderators
    // Add to moderation queue
  });

// User blocking
exports.syncBlockedContent = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    // Update content visibility
    // Sync across user's devices
  });

// Statistics tracking
exports.updateCreatorStats = functions.firestore
  .document('routines/{routineId}')
  .onCreate/onUpdate(async (change, context) => {
    // Update creator statistics
    // Update routine rankings
  });
```

### 6.2 Admin SDK Functions
```javascript
// Admin-only functions
exports.banUser = functions.https.onCall(async (data, context) => {
  // Verify admin privileges
  // Ban user
  // Remove all content
  // Send notification
});

exports.moderateContent = functions.https.onCall(async (data, context) => {
  // Verify moderator privileges
  // Approve/reject content
  // Update moderation status
  // Notify creator
});
```

## 7. Safety Features

### 7.1 Content Guidelines
```markdown
# Community Content Guidelines

## Acceptable Content
- Workout routines based on app methods
- Helpful descriptions and tips
- Progression-focused programs

## Prohibited Content
- Inappropriate or offensive language
- Misleading health claims
- Spam or promotional content
- Copyright violations
- Personal information
- Harmful advice

## Consequences
- First violation: Warning
- Second violation: Temporary suspension
- Third violation: Permanent ban
```

### 7.2 Age Gating
- Require age verification (17+)
- Filter content based on age
- Parental controls option

### 7.3 Privacy Protection
- Optional anonymous sharing
- Hide personal information
- Secure messaging (future)

## 8. Analytics & Monitoring

### 8.1 Key Metrics
- Daily active creators
- Routines shared per day
- Download rates
- Report rates
- Moderation queue size
- Resolution times

### 8.2 Dashboards
- Creator dashboard (in-app)
- Moderator dashboard (web)
- Admin analytics (web)

## 9. Testing Strategy

### 9.1 Unit Tests
- Report submission
- Content filtering
- User blocking
- Statistics calculation

### 9.2 Integration Tests
- End-to-end sharing flow
- Report to resolution flow
- Cross-device sync

### 9.3 Security Tests
- Permission validation
- SQL injection prevention
- Rate limiting

## 10. Rollout Strategy

### 10.1 Beta Testing
1. Internal testing with team
2. Closed beta with 50 users
3. Open beta with 500 users
4. Full release

### 10.2 Feature Flags
```swift
enum FeatureFlag {
    case communitySharing
    case communityBrowsing
    case reportingSystem
    case creatorProfiles
}
```

### 10.3 Gradual Rollout
- Week 1: 10% of users
- Week 2: 25% of users
- Week 3: 50% of users
- Week 4: 100% of users

## 11. Legal Considerations

### 11.1 Terms of Service Updates
- User-generated content rights
- Content moderation policies
- DMCA compliance
- User responsibilities

### 11.2 Privacy Policy Updates
- Data collection for UGC
- Moderation data retention
- Third-party sharing

## 12. Success Criteria

### 12.1 Launch Metrics
- 100+ community routines in first month
- < 5% report rate
- < 24hr moderation response time
- 90%+ user satisfaction

### 12.2 Long-term Goals
- 1000+ active creators
- 10,000+ community routines
- < 1% harmful content rate
- Self-sustaining community

## 13. Risk Mitigation

### 13.1 Content Risks
- Automated pre-moderation
- Quick response team
- Clear guidelines
- User education

### 13.2 Technical Risks
- Rate limiting
- Caching strategy
- CDN for media
- Backup systems

### 13.3 Legal Risks
- Legal review of all features
- DMCA process
- User agreements
- Insurance coverage

## Implementation Priority

### Must Have (MVP)
1. ✅ Basic sharing toggle
2. Community browse tab
3. Report content button
4. Block user functionality
5. Basic moderation queue
6. Creator attribution

### Should Have
1. Creator profiles
2. Download tracking
3. Auto-moderation
4. Admin dashboard
5. Email notifications

### Nice to Have
1. Ratings system
2. Creator verification
3. Advanced analytics
4. In-app creator dashboard
5. Social features

## Next Steps

1. Review and approve plan
2. Create technical design documents
3. Set up development environment
4. Begin Phase 1 implementation
5. Weekly progress reviews