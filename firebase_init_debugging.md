# Firebase Initialization Debugging

## Issue
The error "The default Firebase app has not yet been configured" appears at startup before Firebase is properly configured.

## Root Cause Analysis
The issue occurs because multiple services were using direct initialization of Firestore:

1. **Direct Firestore Initialization**:
   Many services had this pattern:
   ```swift
   private let db = Firestore.firestore()
   ```
   This causes Firestore to be accessed when the singleton is created, which can happen before Firebase is configured.

2. **Services with this issue**:
   - UserService
   - GrowthMethodService
   - RoutineService
   - GainsService
   - LegalDocumentService
   - OnboardingRetentionService
   - RoutineAdherenceService
   - UserDataDeletionService
   - AppTourService
   - AuthService
   - OnboardingService
   - AICoachService (Functions.functions() in init)

3. **AppDelegate initialization order**:
   Services were being initialized before Firebase configuration completed.

## Debug Statements Added

1. **FirestoreService.swift**: Added lazy initialization with debug logging
2. **ComplianceConfigurationService.swift**: Added init debug logging
3. **FirebaseClient.swift**: Added init and configure debug logging
4. **NotificationsManager.swift**: Added init debug logging
5. **StreakTracker.swift**: Added init debug logging

## Solution Applied
Fixed the Firebase initialization order issue by:

1. **Changed all direct Firestore initialization to lazy**:
   ```swift
   // Before:
   private let db = Firestore.firestore()
   
   // After:
   private lazy var db = Firestore.firestore()
   ```

2. **Updated AppDelegate to delay service initialization**:
   Services that depend on Firebase are now initialized in a DispatchQueue.main.async block.

3. **Fixed AICoachService**:
   Removed Functions parameter from init and made it a lazy property.

## Recommended Fix
Move service initialization to after Firebase configuration in AppDelegate:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    // Configure Firebase first
    let firebaseConfigured = FirebaseClient.shared.configure(for: .development)
    
    if !firebaseConfigured {
        print("WARNING: Firebase configuration failed!")
    }
    
    // Only initialize Firebase-dependent services after configuration
    DispatchQueue.main.async {
        // Set up Firebase Messaging delegate
        Messaging.messaging().delegate = self
        
        // Initialize services that depend on Firebase
        _ = NotificationsManager.shared
        _ = StreakTracker.shared
        
        // Load compliance configuration
        ComplianceConfigurationService.shared.loadComplianceConfiguration()
        
        // Register for remote notifications
        application.registerForRemoteNotifications()
    }
    
    // Set up UNUserNotificationCenter delegate (doesn't need Firebase)
    UNUserNotificationCenter.current().delegate = self
    
    // Request notification authorization
    requestNotificationAuthorization(application)
    
    return true
}
```

This ensures Firebase is fully configured before any service tries to access it.