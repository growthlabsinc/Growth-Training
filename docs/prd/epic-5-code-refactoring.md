# Epic 5: Codebase Refactoring

## Epic Overview
Update all code references, bundle identifiers, and internal naming to Growth Training

**Priority**: P0 - Critical
**Estimated Effort**: 4 days
**Dependencies**: Epic 1 (Infrastructure), Epic 2 (Content)
**Owner**: Development Team

## Epic Goals
- Update bundle identifiers and app configuration
- Replace all hardcoded strings and references
- Update Firebase configuration integration
- Refactor method/class names where needed
- Ensure Live Activities work with new identifiers

## Acceptance Criteria
- [ ] All bundle identifiers updated
- [ ] Firebase configuration integrated
- [ ] 600+ Swift files updated
- [ ] Live Activities functional
- [ ] No compilation errors
- [ ] All tests passing

## User Stories

### Story 5.1: Update Bundle Identifiers
**As a** developer
**I want to** update all bundle identifiers
**So that** the app has new identity

**Tasks:**
- Update main app bundle ID to com.growthlabs.growthtraining
- Update widget extension bundle ID
- Update app group identifier
- Update keychain access group
- Update entitlements files

**File Updates:**
```
Growth.xcodeproj/project.pbxproj
├── PRODUCT_BUNDLE_IDENTIFIER = com.growthlabs.growthtraining
├── APP_GROUP = group.com.growthlabs.growthtraining
└── KEYCHAIN_GROUP = com.growthlabs.growthtraining

Info.plist files:
├── Growth/Info.plist
├── GrowthTimerWidget/Info.plist
└── Widget Intent/Info.plist
```

**Acceptance Criteria:**
- Bundle IDs updated
- App group functional
- Keychain access working
- Widget communication intact

---

### Story 5.2: Integrate Firebase Configuration
**As a** developer
**I want to** integrate new Firebase config
**So that** app connects to new backend

**Tasks:**
- Replace GoogleService-Info.plist files
- Update FirebaseClient.swift with new project IDs
- Update environment configurations
- Test Firebase connectivity
- Update App Check configuration

**Configuration Updates:**
```swift
// FirebaseClient.swift
private static let projectConfigs = [
    .development: "growth-training-dev",
    .staging: "growth-training-staging",
    .production: "growth-training"
]
```

**Acceptance Criteria:**
- Firebase connecting successfully
- All environments configured
- App Check working
- Push notifications functional

---

### Story 5.3: Update Model Layer
**As a** developer
**I want to** update data models
**So that** they reflect new terminology

**Tasks:**
- Rename GrowthMethod to TrainingProtocol
- Update method properties
- Refactor related ViewModels
- Update Firestore field mappings
- Maintain backward compatibility

**Model Changes:**
```swift
// Old
struct GrowthMethod {
    let methodDescription: String
    let categories: [String] // ["Angion"]
}

// New
struct TrainingProtocol {
    let protocolDescription: String
    let categories: [String] // ["Length", "Girth", "EQ"]
}
```

**Acceptance Criteria:**
- Models updated
- Firestore mapping correct
- No data loss
- Migration path clear

---

### Story 5.4: Update View Layer
**As a** developer
**I want to** update all SwiftUI views
**So that** UI shows new terminology

**Tasks:**
- Update view titles and labels
- Replace hardcoded strings
- Update navigation titles
- Refresh button labels
- Update accessibility labels

**Key Files:**
- HomeView.swift
- TimerView.swift
- MethodSelectionView.swift → ProtocolSelectionView.swift
- ProgressDashboard.swift
- SettingsView.swift

**String Updates:**
```swift
// Localization updates
"method.title" = "Training Protocol"
"session.start" = "Start Training"
"progress.title" = "Training Progress"
"coach.greeting" = "Welcome to Growth Training"
```

**Acceptance Criteria:**
- All views updated
- No hardcoded strings
- Accessibility maintained
- Localization complete

---

### Story 5.5: Update Service Layer
**As a** developer
**I want to** update service classes
**So that** business logic uses new terminology

**Tasks:**
- Update TimerService terminology
- Refactor MethodService → ProtocolService
- Update SessionLogService
- Modify NotificationService content
- Update AnalyticsService events

**Service Updates:**
```swift
// TimerService.swift
class TimerService {
    func startTrainingSession() // was: startMethodSession()
    func completeProtocol() // was: completeMethod()
}

// Analytics Events
"training_started" // was: "angion_started"
"protocol_completed" // was: "method_completed"
```

**Acceptance Criteria:**
- Services refactored
- Analytics updated
- Notifications rebranded
- No functionality lost

---

### Story 5.6: Update Live Activities
**As a** developer
**I want to** update Live Activity configuration
**So that** they work with new bundle IDs

**Tasks:**
- Update activity attributes
- Modify push token configuration
- Update activity content
- Test on physical device
- Verify Dynamic Island

**Live Activity Updates:**
```swift
// TimerActivityAttributes.swift
struct ContentState {
    let protocolName: String // was: methodName
    let sessionType: String = "Training Session"
}

// Info.plist
NSUserActivityTypes: ["com.growthlabs.growthtraining.timer"]
```

**Acceptance Criteria:**
- Live Activities starting
- Push updates working
- Dynamic Island functional
- Lock screen display correct

---

### Story 5.7: Update Tests
**As a** developer
**I want to** update unit tests
**So that** test coverage maintained

**Tasks:**
- Update test class names
- Modify test expectations
- Update mock data
- Fix test assertions
- Add migration tests

**Test Updates:**
```swift
// Tests to update
GrowthMethodTests → TrainingProtocolTests
AngionServiceTests → ProtocolServiceTests
TimerServiceTests (update assertions)
```

**Acceptance Criteria:**
- All tests passing
- Coverage maintained
- New tests added
- CI/CD green

---

### Story 5.8: Clean Up Legacy Code
**As a** developer
**I want to** remove deprecated code
**So that** codebase is clean

**Tasks:**
- Remove Angion-specific utilities
- Delete unused assets
- Clean up comments
- Remove debug code
- Archive deprecated files

**Cleanup Targets:**
- Deprecated methods
- Unused imports
- Dead code paths
- Old configuration
- Obsolete documentation

**Acceptance Criteria:**
- No dead code
- Comments updated
- Clean build
- Reduced binary size

---

## File Update Summary

### High Priority Files (Immediate)
1. `FirebaseClient.swift` - Firebase configuration
2. `AppGroupConstants.swift` - Shared data
3. `Info.plist` files - Bundle configuration
4. `TimerService.swift` - Core functionality
5. `LiveActivityManager.swift` - Live Activities

### Medium Priority Files (Day 2)
1. All View files (600+)
2. ViewModel classes
3. Service classes
4. Model definitions
5. Extension files

### Low Priority Files (Day 3)
1. Test files
2. Documentation
3. Comments
4. Debug utilities
5. Scripts

## Migration Strategy

### Data Migration
```swift
// Temporary compatibility layer
extension TrainingProtocol {
    init(from legacy: GrowthMethod) {
        // Map old structure to new
    }
}
```

### User Data Preservation
- Maintain session history
- Preserve user preferences
- Keep subscription status
- Retain progress data

## Search & Replace Operations

### Global Replacements
```bash
# Terminal commands for bulk updates
find . -name "*.swift" -exec sed -i '' 's/Angion Method/Growth Training/g' {} \;
find . -name "*.swift" -exec sed -i '' 's/GrowthMethod/TrainingProtocol/g' {} \;
find . -name "*.swift" -exec sed -i '' 's/methodName/protocolName/g' {} \;
```

### Manual Review Required
- Complex logic changes
- UI layout adjustments
- Test modifications
- Documentation updates

## Risks & Mitigations
- **Risk**: Breaking changes in production
  - **Mitigation**: Comprehensive testing, staged rollout
- **Risk**: Live Activity failures
  - **Mitigation**: Physical device testing, fallback handling
- **Risk**: Data migration issues
  - **Mitigation**: Compatibility layer, data validation

## Definition of Done
- [ ] All bundle IDs updated
- [ ] Firebase fully integrated
- [ ] No compilation warnings
- [ ] All tests passing
- [ ] Live Activities functional
- [ ] Code review completed
- [ ] Documentation updated