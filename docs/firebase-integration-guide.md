# Firebase Integration Guide

This guide provides steps to resolve common Firebase integration issues in the Growth iOS app.

## Common Issues

### "No such module 'Firebase'" Error

This error occurs when Xcode cannot find the Firebase modules. Here are several approaches to fix it:

## Method 1: Use the Fix Script (Recommended)

1. Run the provided fix script:
   ```bash
   chmod +x scripts/fix-firebase-dependencies.sh
   ./scripts/fix-firebase-dependencies.sh
   ```

2. After the script runs, open Xcode and do the following:
   - Go to File > Packages > Reset Package Caches
   - Go to File > Packages > Resolve Package Versions
   - Clean the build folder: Cmd+Shift+K
   - Build the project: Cmd+B

## Method 2: Manual Integration with Swift Package Manager

1. Close Xcode completely
2. Open the Growth project in Xcode:
   ```bash
   open Growth.xcodeproj
   ```
3. In Xcode:
   - Go to File > Add Packages...
   - Paste this URL: `https://github.com/firebase/firebase-ios-sdk.git`
   - Select the following Firebase products:
     - FirebaseAuth
     - FirebaseFirestore
     - FirebaseFunctions
     - FirebaseAnalytics
     - FirebaseCrashlytics
     - FirebaseRemoteConfig
   - Click "Add Package"
4. Wait for Xcode to resolve the dependencies (this might take several minutes)
5. Clean the build folder (Cmd+Shift+K) and build again (Cmd+B)

## Method 3: Fix Xcode Project Settings

1. In Xcode, select the Growth project in the Navigator
2. Go to the "Build Phases" tab
3. Expand "Link Binary With Libraries"
4. Click the "+" button and add the Firebase frameworks
5. Go to the "Build Settings" tab
6. Search for "Framework Search Paths" and ensure it includes the path to Firebase frameworks
7. Search for "Header Search Paths" and ensure it includes the path to Firebase headers
8. Clean and build the project

## Method 4: Fix GoogleService-Info.plist Files

Ensure that the Firebase configuration files are correctly placed:

1. Verify these files exist with the correct names:
   - Development: `Growth/Resources/Plist/dev.GoogleService-Info.plist`
   - Staging: `Growth/Resources/Plist/staging.GoogleService-Info.plist`
   - Production: `Growth/Resources/Plist/GoogleService-Info.plist`

2. Check that `FirebaseClient.swift` is using the correct file paths:
   ```swift
   var configFileName: String {
       switch self {
       case .development:
           return "dev.GoogleService-Info"
       case .staging:
           return "staging.GoogleService-Info"
       case .production:
           return "GoogleService-Info"
       }
   }
   ```

## Method 5: Clean DerivedData

1. Close Xcode
2. Remove the DerivedData folder:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```
3. Restart Xcode and build the project

## If All Else Fails

Try using CocoaPods instead of Swift Package Manager:

1. Run the setup script with CocoaPods option:
   ```bash
   ./scripts/setup-dependencies.sh
   # Select option 2 for CocoaPods when prompted
   ```

2. Open the workspace (not the project):
   ```bash
   open Growth.xcworkspace
   ```

3. Build the project

## Verification

To verify that Firebase is correctly integrated, check for these signs:

1. No compilation errors related to Firebase imports
2. Firebase initialization logs appear in the console when running the app
3. The test connection methods in `FirebaseClient` complete successfully 