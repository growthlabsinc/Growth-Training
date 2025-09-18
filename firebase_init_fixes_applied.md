# Firebase Initialization Fixes Applied

## Problem
The error "The default Firebase app has not yet been configured" was appearing at app startup because various services were trying to access Firebase before it was configured in AppDelegate.

## Root Causes Identified and Fixed

### 1. AuthService in AuthViewModel
**Issue**: AuthViewModel is created as @StateObject in the @main struct, and it creates AuthService with a default parameter. AuthService was doing:
```swift
private let auth = Auth.auth()  // Immediate initialization
```

**Fix Applied**:
- Changed to lazy initialization: `private lazy var auth = Auth.auth()`
- Delayed setupAuthStateListener to run async after Firebase configuration

### 2. Direct Firestore Initialization in Services
**Issue**: Multiple services had direct Firestore initialization:
```swift
private let db = Firestore.firestore()
```

**Services Fixed** (changed to lazy var):
- UserService
- FirestoreService  
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

### 3. AICoachService Functions Initialization
**Issue**: Had Functions in init parameters
**Fix**: Made functions a lazy property instead

### 4. AppDelegate Service Initialization
**Issue**: Services were initialized immediately in didFinishLaunchingWithOptions
**Fix**: Moved Firebase-dependent services to DispatchQueue.main.async block

## Key Changes Summary

1. **All Firebase/Firestore access changed to lazy initialization**
   ```swift
   // Before:
   private let db = Firestore.firestore()
   private let auth = Auth.auth()
   
   // After:
   private lazy var db = Firestore.firestore()
   private lazy var auth = Auth.auth()
   ```

2. **AuthService init delayed auth listener setup**
   ```swift
   init() {
       // Delay auth listener setup to ensure Firebase is configured
       DispatchQueue.main.async { [weak self] in
           self?.setupAuthStateListener()
       }
   }
   ```

3. **AppDelegate delays service initialization**
   ```swift
   DispatchQueue.main.async {
       // Initialize Firebase-dependent services
       _ = NotificationsManager.shared
       _ = StreakTracker.shared
       // etc.
   }
   ```

## Testing
After these changes, Firebase should only be accessed after it's properly configured in AppDelegate, eliminating the startup warning.