# App Check SSL Error Fix

## Problem
Getting App Check attestation errors:
- Error: "App attestation failed" with HTTP 403
- URL: `https://firebaseappcheck.googleapis.com/v1/projects/growth-70a85/apps/1:645068839446:ios:c49ec579111e8a65fc3337:exchangeDeviceCheckToken`

## Root Cause
The app is trying to use DeviceCheck provider instead of Debug provider. This happens because:
1. App Check provider factory must be set BEFORE `FirebaseApp.configure()`
2. The simulator requires Debug provider, not DeviceCheck

## Solution Applied

### Code Changes Made
1. **Fixed initialization order** in `FirebaseClient.swift`:
   - Moved `configureAppCheck()` BEFORE `FirebaseApp.configure()`
   - This ensures the debug provider is set before Firebase initializes

2. **Enhanced simulator detection**:
   - Added `targetEnvironment(simulator)` check
   - Ensures debug provider is always used in simulator

3. **Improved token retrieval**:
   - Delayed token retrieval until after Firebase initialization
   - Better error messages and instructions

### Steps to Complete Setup

#### Step 1: Clean Build
1. Product → Clean Build Folder (⇧⌘K)
2. Delete the app from simulator
3. Close and restart Xcode

#### Step 2: Run the App
1. Product → Run (⌘R)
2. Look for this in console:
   ```
   🔐 Firebase App Check configured with DEBUG provider (Simulator)
   ```

#### Step 3: Get Debug Token
After ~2 seconds, you'll see:
```
========================================
🔑 App Check Debug Token:
[YOUR-TOKEN-HERE]
========================================
```

#### Step 4: Add to Firebase Console
1. Go to: https://console.firebase.google.com/project/growth-70a85/appcheck/apps
2. Click on your iOS app (com.growthlabs.growthmethod)
3. Click the three dots menu (⋮) → "Manage debug tokens"
4. Click "Add debug token"
5. Enter:
   - Name: "Xcode Simulator"
   - Value: The debug token from console
6. Click "Done"

#### Step 5: Restart App
Stop and run the app again. App Check should now work properly.

## Verification
After setup, you should see:
- "🔐 Firebase App Check configured with DEBUG provider"
- "✅ App Check debug token refreshed successfully"
- No more 403 errors
- Successful Firebase operations

## Important Notes
- Each simulator needs its own debug token
- Debug tokens are only for development
- Production builds on real devices use DeviceCheck automatically
- If you still see DeviceCheck errors, ensure you're running in Debug configuration