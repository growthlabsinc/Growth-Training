# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **native iOS Swift/SwiftUI application** with comprehensive Firebase backend integration. The app focuses on timer functionality with sophisticated **Live Activities** and **Dynamic Island** support. Built with **iOS 16.0+ minimum target** using **Swift 5.10+**.

### CRITICAL: Project Status
**This is a 100% functional brownfield project.** All features are fully implemented and working. When working in this codebase:
- **DO NOT** change any UI functionality or behavior
- **DO NOT** modify core app logic or features
- **DO NOT** refactor working code unless explicitly requested
- **ONLY** update Firebase configuration, API keys, and environment settings when needed
- **ONLY** update content, branding, and text when requested
- The app is production-ready and live - preserve all existing functionality

### Key Technologies
- **SwiftUI** with **Combine** for reactive programming
- **ActivityKit** for Live Activities and Dynamic Island
- **Firebase SDK 10.15.0+** for backend services
- **Swift Package Manager** for dependency management
- **Node.js 20** for Firebase Functions

## Core Architecture

### Modular Feature-Based Structure
- **Feature modules** in `Growth/Features/` organized by functionality (Authentication, Timer, Dashboard, Progress)
- **Core services** in `Growth/Core/` providing shared functionality across features
- **MVVM pattern** throughout with SwiftUI and Combine reactive programming
- **Service-oriented architecture** with protocol-based dependency injection

### Multi-Environment Configuration
```swift
enum FirebaseEnvironment: String {
    case development = "dev"
    case staging = "staging"
    case production = "prod"
}
```
- Each environment has its own GoogleService-Info.plist in `Growth/Resources/Plist/`
- Environment switching handled by `FirebaseClient.swift`

## Development Commands

### Build & Compilation
```bash
# Open project in Xcode
open Growth.xcodeproj

# Clean build folder in Xcode: ⌘+Shift+K
# Build project in Xcode: ⌘+B
# Run on simulator: ⌘+R

# Command line build verification (use sparingly)
xcodebuild -project Growth.xcodeproj -scheme Growth -configuration Debug build

# Deep clean when build cache issues occur
rm -rf ~/Library/Developer/Xcode/DerivedData
# or use the script:
./XCODE_DEEP_CLEAN.sh
```

### Testing
- **⌘+U** to run unit tests in Xcode
- **XCTest** framework for unit and integration tests
- Firebase emulator for local development testing
- Use `./test_pause_functionality.sh` for Live Activity testing

### Diagnostics and Debugging
```bash
# App Check debug token management
./diagnose_app_check.sh
./fix_app_check_debug_token.sh

# Live Activity debugging
./debug_live_activity.sh
./debug_widget_crash.sh

# Firebase connection testing
./test_firebase_connection.js
```

### Firebase Functions (Node.js 20)
```bash
cd functions
npm install

# Start emulators for local testing
npm run serve

# Deploy all functions to production
npm run deploy

# Deploy specific functions
firebase deploy --only functions:functionName

# Deploy only the AI Coach function
firebase deploy --only functions:generateAIResponse

# View function logs
npm run logs
# or for specific function
firebase functions:log --only generateAIResponse

# Deploy knowledge base content
node deployPelvicFloorKnowledge.js  # or other deployment scripts
```

## Live Activity Architecture

### Core Components
- **`TimerActivityAttributes.swift`** - Live Activity data model with ContentState
- **`LiveActivityManager.swift`** - Activity lifecycle management
- **`LiveActivityPushService.swift`** - Push notification integration for updates
- **Widget Extension** in `GrowthTimerWidget/` directory

### Key Implementation Patterns
- Use **`Text(timerInterval:)`** for efficient native timer displays (avoids constant updates)
- **startedAt/pausedAt pattern** for pause/resume functionality
- **App Intents** (iOS 17.0+) for Dynamic Island user interactions
- **Darwin notifications** for cross-process communication between main app and widget

### Live Activity Best Practices
- Always implement both **Lock Screen** and **Dynamic Island** presentations
- Handle **push-to-start** functionality for iOS 17.2+
- Use **Firebase Cloud Functions** for server-side Live Activity push updates
- Minimize data in ContentState - keep it under 4KB
- **Critical**: Live Activities require physical device testing - simulator support is limited
- Use **startedAt/pausedAt pattern** for pause/resume functionality (inspired by expo-live-activity-timer)
- **Darwin notifications** enable cross-process communication between main app and widget extension
- **App Group** (`group.com.growthlabs.growthmethod`) stores shared timer state

## Firebase Integration

### Services Used
```swift
// Core Firebase stack
FirebaseAuth          // Authentication with Google Sign-In
FirebaseFirestore     // Primary database
FirebaseFunctions     // AI Coach, Live Activity updates
FirebaseAnalytics     // User behavior tracking
FirebaseCrashlytics   // Crash reporting
FirebaseAppCheck      // App integrity verification
FirebaseMessaging     // Push notifications
```

### Firebase Functions (Node.js 20)
Located in `/functions/` directory:
- **AI Coach** with Vertex AI integration (uses `vertexAiProxy/index.js` for knowledge base search)
- **Live Activity push notifications** via APNS
- **User data management** and sync
- **Analytics processing** and reporting

### AI Coach Knowledge Base
- Knowledge stored in Firestore collection `ai_coach_knowledge`
- Deploy new knowledge: `node deployPelvicFloorKnowledge.js` or similar scripts
- Knowledge base search enhanced in `vertexAiProxy/knowledgeBaseSearch.js`
- System prompts in `vertexAiProxy/index.js` control response behavior

### App Check Configuration
- **Debug tokens** required for development
- Use `AppCheckDebugView.swift` in Settings → Development Tools for token management
- Environment variable: `FIRAAppCheckDebugToken` (note the extra 'A')
- Register debug tokens at: https://console.firebase.google.com/project/growth-70a85/appcheck/apps

## State Management

### Primary Patterns
- **@StateObject/@ObservableObject** for ViewModels
- **@Published** properties for reactive UI updates
- **Combine framework** for async operations and data binding
- **NotificationCenter** for cross-component communication

### Key State Managers
- **`AuthViewModel`** - Authentication state
- **`TimerService`** - Timer state and Live Activity management
- **`ThemeManager`** - App theming and UI customization
- **`BiometricAuthService`** - Face ID/Touch ID authentication
- **`SubscriptionStateManager`** - In-app purchase management

## Authentication Architecture

### Supported Methods
- **Email/Password** with Firebase Auth
- **Google Sign-In** integration
- **Anonymous authentication** for guest users
- **Biometric authentication** (Face ID/Touch ID) for app access

### Security Implementation
- **Keychain storage** for sensitive data
- **Token refresh mechanisms** with automatic retry
- **GDPR compliance** with user data deletion
- **App Check** integration for app integrity verification

## Development Workflows

### Environment Switching
The app automatically uses the appropriate Firebase configuration based on build scheme:
- **Development** → `dev.GoogleService-Info.plist`
- **Staging** → `staging.GoogleService-Info.plist`
- **Production** → `GoogleService-Info.plist`

### Testing Patterns
- **Mock services** for Firebase dependencies
- **XCUITest** for UI automation
- **Combine testing** with expectation patterns
- **Live Activity testing** requires physical device for full functionality

### Code Style
- **SwiftUI-native** implementation patterns
- **Protocol-oriented programming** for service abstractions
- **Combine publishers** for reactive data flow
- **Swift concurrency** (async/await) where appropriate

## Common Development Tasks

### Debugging Live Activities
1. Use **Console.app** to monitor widget logs
2. Check **Darwin notification** delivery
3. Verify **Firebase Functions logs** for push delivery
4. Test on **physical device** (Live Activities don't work in simulator)

### Firebase Functions Development
```bash
cd functions
npm install

# Start emulators for local testing
npm run serve

# Deploy all functions to production
npm run deploy

# Deploy specific functions
firebase deploy --only functions:functionName

# Deploy only the AI Coach function
firebase deploy --only functions:generateAIResponse

# View function logs
npm run logs
# or for specific function
firebase functions:log --only generateAIResponse

# Deploy knowledge base content
node deployPelvicFloorKnowledge.js  # or other deployment scripts
```

### Timer System Architecture
- **TimerService** (`TimerService.swift`) - Main timer logic with Live Activity integration
- **TimerCoordinator** - Manages multiple timer instances and prevents conflicts
- **BackgroundTimerTracker** - Handles timer persistence across app backgrounding
- **QuickPracticeTimerService** - Lightweight timer for quick practice sessions
- Three timer modes: **stopwatch**, **countdown**, and **interval**

### App Check Token Issues
1. Navigate to Settings → Development Tools → App Check Debug
2. Use **"🧹 Clear Cache & Regenerate"** to get fresh token
3. Register new token in Firebase Console
4. Restart app to use new token

### Common Build Issues
- **Widget Extension** compilation requires all Live Activity files to be properly referenced
- **Multi-environment** plist files must have correct Bundle ID
- **App Check tokens** must be registered for each environment
- **Signing issues**: Use `./fix_archive_distribution.sh` for certificate/profile mismatches
- **DerivedData corruption**: Use `./XCODE_DEEP_CLEAN.sh` to reset build cache
- **Live Activity compilation errors**: Ensure `GrowthTimerWidgetExtension.entitlements` is properly configured

## AI Coach Integration

### Architecture
- **Vertex AI** integration via Firebase Functions
- **RAG (Retrieval-Augmented Generation)** with knowledge base in Firestore
- **Conversation history** with GDPR-compliant deletion
- **Real-time streaming** responses using Firebase Functions

### Key Components
- **`AICoachService.swift`** - Client-side AI interaction
- **`ConversationManager.swift`** - Chat history management
- **Firebase Functions** - Server-side AI processing with Vertex AI

## Project Management

### Development Workflow
- Use **feature-based branching** with descriptive branch names
- **Debug speed multiplier** available in TimerService for testing (`TimerService.debugSpeedMultiplier`)
- Extensive **diagnostic scripts** in root directory for troubleshooting
- **Multi-environment setup** supports development, staging, and production Firebase projects

### Key Directories to Know
- `Growth/Features/Timer/` - Timer functionality and Live Activities
- `Growth/Core/Networking/` - Firebase client and App Check configuration
- `GrowthTimerWidget/` - Widget extension for Live Activities
- `functions/` - Firebase Cloud Functions (Node.js)
- `scripts/` - Utility scripts for various development tasks

### Important Files
- `FirebaseClient.swift` - Handles multi-environment Firebase initialization
- `TimerService.swift` - Core timer logic with Live Activity integration
- `LiveActivityManager.swift` - Simplified Live Activity management
- `AppGroupConstants.swift` - Shared data between app and widget
- `package.json` (functions/) - Firebase Functions dependencies

This codebase represents enterprise-level iOS development with sophisticated Live Activity implementation, comprehensive Firebase integration, and modern SwiftUI architecture patterns.

## Critical Workflow Notes

### Xcode Project Structure
- Main target: **Growth** (iOS app)
- Widget Extension: **GrowthTimerWidgetExtension** (Live Activities)
- Both targets share files via target membership, not file duplication
- Live Activity intent files require membership in both app and widget targets

### Data Flow Architecture
- **User Authentication** → Firebase Auth → AuthViewModel → UI State
- **Timer State** → TimerService → Live Activity Manager → Widget Extension
- **Progress Tracking** → SessionLog (Firestore) → ProgressViewModel → Charts/Stats
- **AI Coach** → User Query → Firebase Function → Vertex AI + Knowledge Base → Response

### Key Architectural Decisions
- **No duplicate files**: Use Xcode target membership for shared code between app and widget
- **Darwin Notifications**: Removed in favor of direct Live Activity updates via push
- **Knowledge Base RAG**: AI Coach searches Firestore before generating responses
- **Routine Adherence**: Counts ANY session before routine selection date as valid adherence