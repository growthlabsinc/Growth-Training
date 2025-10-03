# Firebase Logging Configuration

## Overview
This document explains how to control Firebase verbose logging in the Xcode console.

## Methods to Disable Firebase Logging

### 1. Code-Based Configuration (Already Implemented)
The app now disables verbose Firebase logging programmatically:
- In `GrowthAppApp.swift`: Sets the Firebase logger level to `.error`
- In `FirebaseClient.swift`: Configures Firestore settings after Firebase initialization

```swift
FirebaseConfiguration.shared.setLoggerLevel(.error)
```
This will only show error-level logs, filtering out all the verbose debug information.

**Important**: The Firestore-specific settings must be configured AFTER Firebase is initialized to avoid crashes.

### 2. Xcode Scheme Environment Variables
For more granular control, you can add these environment variables to your Xcode scheme:

1. Open your project in Xcode
2. Select Product → Scheme → Edit Scheme
3. Select the "Run" action
4. Go to the "Arguments" tab
5. Add these environment variables under "Environment Variables":

```
FIRDebugDisabled = 1
FIRAnalyticsDebugEnabled = 0
FirebaseDebugLogging = 0
```

### 3. Specific Component Control
You can also disable logging for specific Firebase components:

```
FIRFirestoreLoggingEnabled = 0
FIRAuthLoggingEnabled = 0
FIRMessagingDebugLoggingEnabled = 0
```

### 4. Temporary Console Filtering
In Xcode's console, you can filter out Firebase logs:
1. Click the filter icon at the bottom of the console
2. Add a filter to exclude messages containing "Firebase"

## Log Levels
Firebase supports these log levels (from most to least verbose):
- `.debug` - All messages
- `.info` - Informational messages and above
- `.warning` - Warnings and above
- `.error` - Only errors
- `.none` - No logging

## Testing
After making these changes:
1. Clean Build Folder (Shift+Cmd+K)
2. Build and run the app
3. Verify that Firebase verbose logs no longer appear in the console

## Reverting Changes
To re-enable verbose logging for debugging:
1. Change `.error` to `.debug` in the code
2. Remove or disable the environment variables
3. Or set `FIRDebugEnabled = 1` in environment variables