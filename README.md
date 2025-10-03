# Growth iOS App

An iOS application designed to help users track and improve their personal growth journey.

## Project Structure

The Growth app follows a feature-based architecture with a shared core of UI components, networking, and utilities. The app is built using:

- Swift 5.10+
- SwiftUI for UI development
- Firebase for backend services (Auth, Firestore, Functions, Analytics, Crashlytics)
- iOS 16.0 as minimum target version

## Directory Structure

```
GrowthApp/
├── Application/             // App entry point, delegates
├── Core/                    // Shared functionality
│   ├── Authentication/      // Auth services
│   ├── Data/                // Models, persistence
│   ├── Networking/          // Firebase client
│   ├── UI/                  // Shared UI components
│   ├── Utilities/           // Helpers, extensions
│   └── Routing/             // Navigation logic
├── Features/                // Feature modules
│   ├── Onboarding/          // User onboarding
│   ├── GrowthMethods/       // Method listings
│   ├── SessionLogging/      // Progress tracking
│   └── ...                  // Other features
└── Resources/               // Assets, plists, etc.
```

## Setup Instructions

### Prerequisites

- Xcode 15.0+
- Swift Package Manager (SPM) or CocoaPods

### Quick Setup (Recommended)

We've provided a setup script that will configure all the necessary dependencies for you:

```bash
# Make the script executable if needed
chmod +x scripts/setup-dependencies.sh

# Run the setup script
./scripts/setup-dependencies.sh
```

The script will:
1. Ask whether you want to use Swift Package Manager (recommended) or CocoaPods
2. Set up all required Firebase dependencies
3. Guide you through the next steps

### Firebase Configuration

1. Create three Firebase projects (Development, Staging, Production)
2. Add iOS app to each project with the respective Bundle IDs:
   - Development: `com.growth.dev`
   - Staging: `com.growth.staging`
   - Production: `com.growth`
3. Download the `GoogleService-Info.plist` file for each environment and place them in the following locations:
   - Dev: `Growth/Resources/Plist/dev.GoogleService-Info.plist`
   - Staging: `Growth/Resources/Plist/staging.GoogleService-Info.plist`
   - Prod: `Growth/Resources/Plist/GoogleService-Info.plist`

### Manual Dependency Installation

#### Using Swift Package Manager (Recommended)

1. Open `Growth.xcodeproj` in Xcode
2. Go to File > Add Packages
3. Enter the Firebase SDK URL: `https://github.com/firebase/firebase-ios-sdk.git`
4. Select the following Firebase products:
   - FirebaseAuth
   - FirebaseFirestore
   - FirebaseFunctions
   - FirebaseAnalytics
   - FirebaseCrashlytics
   - FirebaseRemoteConfig
5. Click "Add Package"

#### Using CocoaPods

1. If CocoaPods is not installed, install it:
   ```bash
   sudo gem install cocoapods
   ```

2. Run the following command in the project root directory:
   ```bash
   pod install
   ```

3. Open `Growth.xcworkspace` (not the `.xcodeproj` file) in Xcode

### Running the App

1. Open the appropriate Xcode project/workspace file:
   - For SPM: `Growth.xcodeproj`
   - For CocoaPods: `Growth.xcworkspace`
2. Select the desired scheme (Development, Staging, or Production)
3. Choose a simulator or connected device
4. Build and run (⌘+R)

## Environment Configuration

The app supports three environments:

- **Development**: For active development work, connects to dev Firebase project
- **Staging**: For QA and pre-release testing, connects to staging Firebase project
- **Production**: The release version, connects to production Firebase project

The environment is configured in the `AppDelegate.swift` file using the `FirebaseClient.shared.configure(for:)` method.

## Features

- Tab-based navigation with six main sections:
  - Dashboard: Overview of user's progress
  - Methods: Growth method library
  - Progress: Tracking and analytics
  - Coach: AI coaching interface
  - Resources: Educational content
  - Settings: User preferences and account management

## Testing

- Run unit tests with ⌘+U
- Test Firebase connection using the built-in test methods in `FirebaseClient`

## Deployment

[Include specific deployment instructions for this project]

## Contributors

- [Your Name] - Initial work

## Documentation

- [Firebase Warnings](docs/firebase/warnings.md) - Information about Firebase-related console warnings and how to handle them 