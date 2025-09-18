# iOS Development Workflow Rules for Growth App

## Overview

This document defines comprehensive iOS development workflow rules to ensure clean code, proper testing, and robust development practices for the Growth SwiftUI application. These rules are based on enterprise-level iOS development standards and the specific architecture patterns used in this codebase.

## 1. Clean Code Standards

### 1.1 SwiftUI Architecture Patterns

#### MVVM Implementation
```swift
// ✅ Good: Proper MVVM separation
class TimerViewModel: ObservableObject {
    @Published var timerState: TimerState = .idle
    @Published var remainingTime: TimeInterval = 0
    
    private let timerService: TimerServiceProtocol
    
    init(timerService: TimerServiceProtocol = TimerService.shared) {
        self.timerService = timerService
    }
}

// ❌ Bad: Business logic in View
struct TimerView: View {
    @State private var timer: Timer?
    
    var body: some View {
        Button("Start") {
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                // Business logic should not be here
            }
        }
    }
}
```

#### Service-Oriented Architecture
```swift
// ✅ Good: Protocol-based dependency injection
protocol TimerServiceProtocol {
    func startTimer(duration: TimeInterval)
    func pauseTimer()
    func stopTimer()
}

class TimerService: TimerServiceProtocol {
    static let shared = TimerService()
    // Implementation
}

// ✅ Good: Dependency injection in ViewModels
class TimerViewModel: ObservableObject {
    private let timerService: TimerServiceProtocol
    
    init(timerService: TimerServiceProtocol = TimerService.shared) {
        self.timerService = timerService
    }
}
```

### 1.2 Error Handling Standards

#### Result Type Usage
```swift
// ✅ Good: Proper Result type handling with explicit capturing
func fetchUser(userId: String, completion: @escaping (Result<User, Error>) -> Void) {
    userService.fetchUser(userId: userId) { result in
        // Capture result before dispatching to avoid memory issues
        let capturedResult = result
        
        DispatchQueue.main.async {
            switch capturedResult {
            case .success(let user):
                completion(.success(user))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
```

#### Defensive Programming
```swift
// ✅ Good: Defensive initialization with validation
init?(document: DocumentSnapshot) {
    guard let data = document.data() else {
        Logger.error("User init: No data in document")
        return nil
    }
    
    do {
        // Validate required fields
        let userId = data["userId"] as? String ?? document.documentID
        guard !userId.isEmpty else {
            Logger.error("User init: Empty userId")
            return nil
        }
        
        self.id = userId
        // Continue initialization...
    } catch {
        Logger.error("User init: Exception - \(error.localizedDescription)")
        return nil
    }
}
```

### 1.3 Firebase Integration Standards

#### Firestore Document Parsing
```swift
// ✅ Good: Safe document parsing with fallbacks
init?(document: DocumentSnapshot) {
    guard let data = document.data() else { return nil }
    
    // Use multiple field name fallbacks for compatibility
    let creationTimestamp = data["creationDate"] as? Timestamp ?? data["createdAt"] as? Timestamp
    let lastLoginTimestamp = data["lastLogin"] as? Timestamp ?? data["updatedAt"] as? Timestamp
    
    self.creationDate = creationTimestamp?.dateValue() ?? Date()
    self.lastLogin = lastLoginTimestamp?.dateValue() ?? Date()
}
```

#### App Check Integration
```swift
// ✅ Good: Environment-specific App Check configuration
class FirebaseClient {
    static func configureAppCheck() {
        #if DEBUG
        let providerFactory = AppCheckDebugProviderFactory()
        #else
        let providerFactory = DeviceCheckProviderFactory()
        #endif
        AppCheck.setAppCheckProviderFactory(providerFactory)
    }
}
```

### 1.4 Live Activity Implementation

#### ActivityKit Best Practices
```swift
// ✅ Good: Efficient timer display without constant updates
struct TimerLiveActivityView: View {
    let state: TimerActivityAttributes.ContentState
    
    var body: some View {
        if let startedAt = state.startedAt, state.pausedAt == nil {
            Text(timerInterval: startedAt..<(startedAt.addingTimeInterval(state.duration)))
        } else {
            Text(formatTime(state.remainingTime))
        }
    }
}

// ✅ Good: startedAt/pausedAt pattern for pause/resume
struct TimerActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let startedAt: Date?
        let pausedAt: Date?
        let duration: TimeInterval
        let remainingTime: TimeInterval
    }
}
```

## 2. Testing Protocols

### 2.1 Unit Testing Standards

#### XCTest Implementation
```swift
// ✅ Good: Comprehensive unit test structure
class TimerServiceTests: XCTestCase {
    var sut: TimerService!
    var mockLiveActivityManager: MockLiveActivityManager!
    
    override func setUp() {
        super.setUp()
        mockLiveActivityManager = MockLiveActivityManager()
        sut = TimerService(liveActivityManager: mockLiveActivityManager)
    }
    
    override func tearDown() {
        sut = nil
        mockLiveActivityManager = nil
        super.tearDown()
    }
    
    func testStartTimer_UpdatesStateCorrectly() {
        // Given
        let duration: TimeInterval = 300
        let expectation = XCTestExpectation(description: "Timer starts")
        
        // When
        sut.startTimer(duration: duration)
        
        // Then
        XCTAssertEqual(sut.currentState, .running)
        XCTAssertEqual(sut.totalDuration, duration)
        expectation.fulfill()
        
        wait(for: [expectation], timeout: 1.0)
    }
}
```

#### Mock Services
```swift
// ✅ Good: Protocol-based mock implementations
class MockUserService: UserServiceProtocol {
    var shouldReturnError = false
    var mockUser: User?
    
    func fetchUser(userId: String, completion: @escaping (Result<User, Error>) -> Void) {
        if shouldReturnError {
            completion(.failure(MockError.fetchFailed))
        } else if let user = mockUser {
            completion(.success(user))
        } else {
            completion(.failure(MockError.userNotFound))
        }
    }
}
```

### 2.2 UI Testing Standards

#### XCUITest Implementation
```swift
// ✅ Good: UI test with accessibility identifiers
class TimerUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launch()
    }
    
    func testTimerFlow_CompletesSuccessfully() {
        // Navigate to timer
        app.tabBars.buttons["Timer"].tap()
        
        // Start timer
        app.buttons["start_timer_button"].tap()
        
        // Verify timer is running
        XCTAssertTrue(app.staticTexts["timer_display"].exists)
        XCTAssertTrue(app.buttons["pause_timer_button"].exists)
    }
}
```

### 2.3 Live Activity Testing

#### Physical Device Testing Protocol
```bash
# Live Activity testing requires physical device
# Use debug build with timer speed multiplier for testing
./test_pause_functionality.sh

# Verify Live Activity appears on Lock Screen
# Test Dynamic Island interactions
# Validate push notification updates
```

## 3. Build Automation and Validation

### 3.1 Pre-commit Hooks

#### Setup Pre-commit Validation
```bash
#!/bin/bash
# .git/hooks/pre-commit

echo "Running pre-commit validation..."

# Run SwiftLint
if which swiftlint >/dev/null; then
    swiftlint
    if [ $? -ne 0 ]; then
        echo "SwiftLint failed. Fix issues before committing."
        exit 1
    fi
else
    echo "Warning: SwiftLint not installed"
fi

# Run unit tests
echo "Running unit tests..."
xcodebuild test -scheme Growth -destination 'platform=iOS Simulator,name=iPhone 15,OS=18.0' -quiet
if [ $? -ne 0 ]; then
    echo "Unit tests failed. Fix tests before committing."
    exit 1
fi

# Check for TODO comments in production code
echo "Checking for TODO comments..."
TODO_COUNT=$(grep -r "TODO\|FIXME" Growth --exclude-dir=Tests | wc -l)
if [ $TODO_COUNT -gt 0 ]; then
    echo "Warning: Found $TODO_COUNT TODO/FIXME comments"
    grep -r "TODO\|FIXME" Growth --exclude-dir=Tests
fi

echo "Pre-commit validation passed ✅"
```

### 3.2 Build Scripts Enhancement

#### Enhanced Build Validation
```bash
#!/bin/bash
# enhanced_build_validation.sh

set -e

echo "🏗️ Starting enhanced build validation..."

# Clean build
echo "Cleaning build artifacts..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Growth-*
xcodebuild clean -project Growth.xcodeproj -scheme Growth

# Build for device
echo "Building for device..."
xcodebuild build -project Growth.xcodeproj -scheme Growth -destination 'generic/platform=iOS'

# Build for simulator
echo "Building for simulator..."
xcodebuild build -project Growth.xcodeproj -scheme Growth -destination 'platform=iOS Simulator,name=iPhone 15,OS=18.0'

# Run static analysis
echo "Running static analysis..."
xcodebuild analyze -project Growth.xcodeproj -scheme Growth -destination 'platform=iOS Simulator,name=iPhone 15,OS=18.0'

# Validate Info.plist
echo "Validating Info.plist..."
plutil -lint Growth/Info.plist

# Check code signing
echo "Checking code signing..."
codesign --verify --verbose Growth.app 2>/dev/null || echo "Code signing check skipped (no .app found)"

echo "✅ Enhanced build validation completed successfully"
```

### 3.3 Continuous Integration Setup

#### GitHub Actions Workflow
```yaml
# .github/workflows/ios-ci.yml
name: iOS CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Xcode
      uses: maxim-lobanov/setup-xcode@v1
      with:
        xcode-version: '15.0'
    
    - name: Cache derived data
      uses: actions/cache@v3
      with:
        path: ~/Library/Developer/Xcode/DerivedData
        key: ${{ runner.os }}-xcode-${{ hashFiles('**/*.xcodeproj') }}
    
    - name: Install SwiftLint
      run: brew install swiftlint
    
    - name: SwiftLint
      run: swiftlint lint --reporter github-actions-logging
    
    - name: Build and Test
      run: |
        xcodebuild clean build test \
          -project Growth.xcodeproj \
          -scheme Growth \
          -destination 'platform=iOS Simulator,name=iPhone 15,OS=18.0' \
          -enableCodeCoverage YES \
          CODE_SIGN_IDENTITY="" \
          CODE_SIGNING_REQUIRED=NO
    
    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        file: ./coverage.xml
```

## 4. Code Review Standards

### 4.1 Review Checklist

#### Architecture Review Points
- [ ] MVVM pattern correctly implemented
- [ ] Services use protocol-based dependency injection
- [ ] No business logic in Views
- [ ] Proper separation of concerns
- [ ] Firebase integration follows established patterns

#### Code Quality Review Points
- [ ] Error handling is comprehensive and defensive
- [ ] Result types are used correctly with proper capturing
- [ ] Logging is appropriate and informative
- [ ] Optional unwrapping is safe
- [ ] Memory management is correct (weak self, etc.)

#### Live Activity Review Points
- [ ] ActivityKit implementation follows best practices
- [ ] Uses `Text(timerInterval:)` for efficient timer displays
- [ ] Implements startedAt/pausedAt pattern for pause/resume
- [ ] ContentState is under 4KB limit
- [ ] Both Lock Screen and Dynamic Island presentations implemented

#### Testing Review Points
- [ ] Unit tests cover new functionality
- [ ] Mock services are used appropriately
- [ ] UI tests exist for user-facing features
- [ ] Live Activity testing protocol followed
- [ ] Edge cases are tested

### 4.2 Quality Gates

#### Automated Quality Checks
```bash
#!/bin/bash
# quality_gate_check.sh

echo "Running quality gate checks..."

# Code coverage threshold
COVERAGE_THRESHOLD=80
CURRENT_COVERAGE=$(xcodecov --scheme Growth | grep "Total coverage" | awk '{print $3}' | sed 's/%//')

if (( $(echo "$CURRENT_COVERAGE < $COVERAGE_THRESHOLD" | bc -l) )); then
    echo "❌ Code coverage ($CURRENT_COVERAGE%) below threshold ($COVERAGE_THRESHOLD%)"
    exit 1
fi

# Complexity check
COMPLEXITY_THRESHOLD=10
HIGH_COMPLEXITY_FILES=$(lizard Growth -l swift -C $COMPLEXITY_THRESHOLD | grep -c "\.swift")

if [ $HIGH_COMPLEXITY_FILES -gt 0 ]; then
    echo "⚠️ Found $HIGH_COMPLEXITY_FILES files with high complexity"
    lizard Growth -l swift -C $COMPLEXITY_THRESHOLD
fi

# Technical debt check
DEBT_THRESHOLD=5
TODO_COUNT=$(grep -r "TODO\|FIXME\|HACK" Growth --exclude-dir=Tests | wc -l)

if [ $TODO_COUNT -gt $DEBT_THRESHOLD ]; then
    echo "⚠️ Technical debt threshold exceeded: $TODO_COUNT items"
fi

echo "✅ Quality gate checks passed"
```

## 5. Development Environment Setup

### 5.1 Required Tools and Versions

#### Development Dependencies
```bash
# Install required tools
brew install swiftlint
brew install swiftformat
brew install lizard  # Complexity analysis
gem install xcpretty
```

#### Xcode Configuration
- Xcode 15.0+
- iOS 16.0+ deployment target
- Swift 5.10+
- SwiftUI framework

### 5.2 Environment Variables

#### Firebase Configuration
```bash
# Set App Check debug token (note the extra 'A')
export FIRAAppCheckDebugToken="your-debug-token-here"

# Firebase environment selection
export FIREBASE_ENV="development"  # development | staging | production
```

### 5.3 Local Development Workflow

#### Daily Development Process
1. **Start of Day**
   ```bash
   git pull origin develop
   ./clean_and_build.sh
   ./diagnose_app_check.sh  # Verify Firebase connection
   ```

2. **During Development**
   ```bash
   # Before making changes
   ./verify_build.sh
   
   # After making changes
   xcodebuild test -scheme Growth -destination 'platform=iOS Simulator,name=iPhone 15,OS=18.0'
   swiftlint autocorrect
   ```

3. **End of Day**
   ```bash
   # Run comprehensive tests
   ./test_compile.sh
   git add .
   git commit -m "feat: descriptive commit message"
   ```

## 6. Debugging and Diagnostics

### 6.1 Live Activity Debugging

#### Debug Process
```bash
# Start Live Activity debugging
./debug_live_activity.sh

# Monitor widget logs
open /Applications/Utilities/Console.app
# Filter for: process:GrowthTimerWidgetExtension

# Test push notifications
./test_firebase_connection.js
```

#### Common Live Activity Issues
- **Widget not appearing**: Check App Group configuration
- **Timer not updating**: Verify `Text(timerInterval:)` usage
- **Push notifications failing**: Check Firebase Functions logs

### 6.2 Firebase Debugging

#### App Check Issues
```bash
# Fix App Check debug token
./fix_app_check_debug_token.sh

# Verify token registration
curl -X POST https://firebaseappcheck.googleapis.com/v1/projects/growth-70a85/apps/[APP_ID]:exchangeDebugToken
```

#### Firestore Connection Issues
```bash
# Test Firebase connection
./test_firebase_connection.js

# Check environment configuration
echo $FIREBASE_ENV
```

## 7. Performance Standards

### 7.1 App Performance Metrics

#### Target Performance Goals
- Launch time: < 2 seconds (cold start)
- Memory usage: < 150MB peak
- CPU usage: < 30% average
- Battery impact: Low/Very Low

#### Performance Testing
```swift
// Performance testing example
func testTimerPerformance() {
    measure {
        // Code to measure performance
        timerService.startTimer(duration: 300)
    }
}
```

### 7.2 Live Activity Performance

#### Optimization Guidelines
- Keep ContentState under 4KB
- Use `Text(timerInterval:)` for efficient timer displays
- Minimize update frequency from server
- Cache data appropriately

## 8. Security Standards

### 8.1 Data Protection

#### Keychain Storage
```swift
// ✅ Good: Secure storage for sensitive data
class SecureStorage {
    private let keychain = Keychain(service: "com.growthlabs.growthmethod")
    
    func store(key: String, value: String) throws {
        try keychain.set(value, key: key)
    }
    
    func retrieve(key: String) throws -> String? {
        return try keychain.get(key)
    }
}
```

#### App Check Implementation
```swift
// ✅ Good: App Check for API protection
class APIClient {
    func makeRequest() async throws {
        let appCheckToken = try await AppCheck.appCheck().token(forcingRefresh: false)
        // Include token in API requests
    }
}
```

### 8.2 Privacy Compliance

#### GDPR Compliance
- User data deletion capabilities
- Clear consent mechanisms
- Data export functionality
- Minimal data collection principles

## 9. Deployment Standards

### 9.1 Release Preparation

#### Pre-release Checklist
- [ ] All unit tests passing
- [ ] UI tests passing on multiple devices
- [ ] Live Activity testing completed on physical device
- [ ] Performance benchmarks met
- [ ] Security review completed
- [ ] Privacy compliance verified
- [ ] App Store guidelines compliance checked

#### Version Management
```bash
# Increment version numbers
agvtool new-marketing-version "1.2.0"
agvtool new-version -all "42"
```

### 9.2 Firebase Environment Management

#### Environment Switching
```swift
// Automatic environment selection based on build configuration
enum FirebaseEnvironment: String {
    case development = "dev"
    case staging = "staging"
    case production = "prod"
}

class FirebaseClient {
    static func configure() {
        #if DEBUG
        let environment = FirebaseEnvironment.development
        #elseif STAGING
        let environment = FirebaseEnvironment.staging
        #else
        let environment = FirebaseEnvironment.production
        #endif
        
        configureForEnvironment(environment)
    }
}
```

## 10. Documentation Standards

### 10.1 Code Documentation

#### Swift Documentation
```swift
/// Service responsible for managing timer functionality with Live Activity integration
/// 
/// This service handles timer state management, Live Activity updates, and
/// cross-process communication with the widget extension.
///
/// - Important: Live Activities require physical device testing
/// - Note: Uses startedAt/pausedAt pattern for pause/resume functionality
class TimerService {
    
    /// Starts a new timer with the specified duration
    /// - Parameter duration: Timer duration in seconds
    /// - Throws: TimerError if timer is already running
    func startTimer(duration: TimeInterval) throws {
        // Implementation
    }
}
```

### 10.2 Architecture Documentation

#### Update CLAUDE.md
Keep the project documentation current with:
- New feature implementations
- Architecture changes
- Development workflow updates
- Common issues and solutions

## Conclusion

These iOS development workflow rules ensure clean, maintainable, and robust code for the Growth SwiftUI application. By following these standards, we maintain high code quality, comprehensive testing coverage, and smooth development workflows while leveraging the sophisticated Live Activity and Firebase integration architecture.

Regular review and updates of these rules should occur with each major feature release or architectural change to ensure they remain relevant and effective.