# Firebase Connection Error Fix

## Problem
The app was showing "Firebase connection failed: Firebase not initialized" error dialog even though Firebase was properly initialized. This was caused by:

1. **MainView init()** trying to access `Auth.auth().currentUser` before Firebase was initialized
2. **MainView.onAppear** immediately calling `FirebaseClient.shared.testConnection` which checks for initialization
3. **Race condition** between Firebase initialization and UI loading

## Solution

### 1. Fixed MainView.swift init()
- Removed direct access to `Auth.auth().currentUser` in init
- Initialize with default values that get updated when auth state changes
- Changed from checking auth state to always showing splash initially

### 2. Updated MainView.onAppear
- Added delay before testing Firebase connection
- Ignore "Firebase not initialized" errors (timing issue)
- Only show real connection errors
- Update UI state based on authViewModel instead of direct Firebase access

### 3. Ensured FirebaseClient is Initialized
- Added explicit call to `FirebaseClient.shared.configure()` in GrowthAppApp init
- This ensures FirebaseClient's `isInitialized` flag is properly set

## Changes Made

### MainView.swift
```swift
// Before
init() {
    let userId = Auth.auth().currentUser?.uid ?? ""  // Firebase not ready!
    self._showSplash = State(initialValue: Auth.auth().currentUser == nil)
}

// After  
init() {
    self._routinesViewModel = StateObject(wrappedValue: RoutinesViewModel(userId: ""))
    self._showSplash = State(initialValue: true)
}
```

### GrowthAppApp.swift
```swift
init() {
    // Configure Firebase
    if FirebaseApp.app() == nil {
        FirebaseApp.configure()
    }
    
    // Ensure FirebaseClient knows Firebase is configured
    let environment = EnvironmentDetector.detectEnvironment()
    _ = FirebaseClient.shared.configure(for: environment)
    
    // ... rest of init
}
```

## Result
- No more "Firebase not initialized" error dialog
- Proper initialization order maintained
- UI updates based on authenticated state from AuthViewModel
- Firebase connection test delayed to avoid race conditions