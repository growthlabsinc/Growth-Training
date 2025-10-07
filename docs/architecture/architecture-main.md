# Growth Training App - Architecture Document
<!-- Powered by BMAD™ Core -->

## Document Version
- **Version**: 6.0
- **Last Updated**: 2025-10-03
- **Status**: Living Document - Rebrand Architecture
- **Type**: Brownfield Architecture (Rebrand from Angion Method)
- **Owner**: jon@growthlabs.coach

## System Overview

The Growth Training App is a comprehensive rebranding of the Angion Method application, transitioning from ED-focused exercises to PE training protocols for the r/ScienceofPE and r/GettingBigger communities. This is a **100% functional brownfield iOS application** with a sophisticated Firebase backend, requiring only content and branding updates while maintaining all existing architecture and functionality.

### Rebrand Context
- **Previous**: Angion Method (r/AngionMethod - ED exercises)
- **Current**: Growth Training (r/ScienceofPE, r/GettingBigger - PE protocols)
- **Firebase Migration**: growth-training-app → growth-training
- **Bundle ID Change**: com.growthlabs.growthmethod → com.growthlabs.growthtraining

### Architecture Principles (Maintained During Rebrand)
1. **Modular Feature-Based Structure**: Each feature is self-contained with its own models, views, and services
2. **MVVM + Combine**: Reactive architecture with SwiftUI and Combine framework
3. **Protocol-Oriented Design**: Heavy use of protocols for abstraction and testability
4. **Service Layer Pattern**: Business logic separated from UI layer
5. **Multi-Environment Support**: Dev, Staging, Production configurations

### Rebrand Architectural Constraints
- **Preserve Core Functionality**: Timer system, Live Activities, Dynamic Island remain unchanged
- **Minimal UI Impact**: Only subtle color adjustments, no structural changes
- **Content Layer Separation**: Exercise content cleanly separated from app logic
- **Safety-First Design**: Enhanced safety warnings and medical disclaimers for PE content
- **Knowledge Base Migration**: Complete replacement while maintaining AI Coach architecture

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         iOS App                              │
├─────────────────────────────────────────────────────────────┤
│  Presentation Layer (SwiftUI Views)                         │
│  ├── Feature Modules                                        │
│  │   ├── Timer (with Live Activities)                      │
│  │   ├── Authentication                                     │
│  │   ├── Dashboard                                         │
│  │   ├── Progress                                          │
│  │   └── AI Coach                                         │
│  └── Shared Components                                      │
├─────────────────────────────────────────────────────────────┤
│  Business Logic Layer                                       │
│  ├── ViewModels (ObservableObject)                         │
│  ├── Services (TimerService, AuthService, etc.)           │
│  └── Managers (ThemeManager, SubscriptionManager)         │
├─────────────────────────────────────────────────────────────┤
│  Data Layer                                                │
│  ├── Firebase Client                                       │
│  ├── Repository Pattern                                    │
│  └── Local Storage (UserDefaults, Keychain)              │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    Firebase Backend                          │
├─────────────────────────────────────────────────────────────┤
│  Authentication (Firebase Auth)                             │
│  Database (Firestore)                                      │
│  Cloud Functions (Node.js 20)                             │
│  Cloud Storage                                            │
│  Remote Config                                            │
│  Analytics & Crashlytics                                  │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                  External Services                           │
├─────────────────────────────────────────────────────────────┤
│  Apple Push Notification Service (APNS)                    │
│  Vertex AI (via Firebase Functions)                        │
│  App Store Connect API                                     │
└─────────────────────────────────────────────────────────────┘
```

## Component Architecture

### iOS Application Components

#### 1. Feature Modules
Each feature follows a consistent structure:
```
Features/[FeatureName]/
├── Models/           # Data models and DTOs
├── Views/            # SwiftUI views
├── ViewModels/       # Observable view models
├── Services/         # Feature-specific services
└── Components/       # Reusable UI components
```

#### 2. Core Services
Shared services across the application:
- **FirebaseClient**: Multi-environment Firebase initialization
- **AuthenticationService**: User authentication management
- **TimerService**: Core timer logic with Live Activity support
- **SubscriptionService**: In-app purchase management
- **AICoachService**: AI interaction layer

#### 3. Live Activities Architecture
```
Main App ←→ Widget Extension
    ↓           ↓
  App Group   Push Updates
    ↓           ↓
Shared State  Activity Kit
```

### Firebase Backend Architecture

#### 1. Cloud Functions Structure
```
functions/
├── index.js                     # Function exports
├── vertexAiProxy/              # AI integration
│   ├── index.js                # Main AI handler
│   ├── knowledgeBaseSearch.js  # RAG implementation
│   ├── responseFilter.js       # Safety filtering
│   └── conversationTemplates.js # Template system
├── liveActivityUpdates.js      # APNS integration
├── userManagement.js            # User operations
└── subscriptionWebhooks.js     # IAP webhooks
```

#### 2. Firestore Data Model
```
firestore-root/
├── users/{userId}/
│   ├── profile
│   ├── settings
│   └── subscription
├── sessions/{sessionId}/
│   ├── metadata
│   └── metrics
├── routines/{routineId}/
│   ├── details
│   └── exercises
├── ai_conversations/{conversationId}/
│   └── messages/{messageId}
└── ai_coach_knowledge/{docId}/
    └── content
```

## Data Flow Architecture

### 1. Authentication Flow
```
User Input → AuthViewModel → Firebase Auth → Token → Keychain
                ↓                              ↓
            UI Update                    Secure Storage
```

### 2. Timer State Management
```
Timer Controls → TimerService → State Updates → Live Activity
                      ↓              ↓               ↓
                 Firebase Log    UI Updates    Lock Screen
```

### 3. AI Coach Flow (PE-Focused Transformation)
```
User Query → AICoachService → Firebase Function → Vertex AI
                ↓                    ↓                ↓
           Local Cache        PE Knowledge Base    Response
                ↓                    ↓                ↓
            UI Update       Safety-First RAG     PE Safety Filter
                                    ↓
                          Medical Disclaimer Check
```

## Security Architecture

### 1. Authentication Layers
- **Firebase Auth**: Primary authentication
- **Biometric Auth**: Face ID/Touch ID for app access
- **Token Management**: Automatic refresh with retry logic
- **Session Management**: Secure token storage in Keychain

### 2. API Security
- **App Check**: Request attestation
- **Secret Manager**: Sensitive key storage
- **IAM Policies**: Function-level permissions
- **Rate Limiting**: Per-user quotas

### 3. Data Security
- **Encryption at Rest**: Firestore encryption
- **Encryption in Transit**: TLS 1.3
- **PII Handling**: GDPR-compliant deletion
- **Audit Logging**: Security event tracking

## Performance Architecture

### 1. Optimization Strategies
- **Lazy Loading**: Views and data loaded on demand
- **Caching**: Strategic caching of frequently accessed data
- **Image Optimization**: Compressed assets with multiple resolutions
- **Code Splitting**: Modular architecture for smaller initial load

### 2. Live Activity Optimization
- **Native Timer Display**: Using `Text(timerInterval:)` for efficiency
- **Minimal State Updates**: Only essential data in ContentState
- **Push Coalescing**: Batched updates to reduce battery impact

### 3. Network Optimization
- **Request Batching**: Combined Firestore queries
- **Offline Support**: Firestore offline persistence
- **CDN Usage**: Static assets served via CDN
- **Compression**: GZIP for API responses

## Deployment Architecture

### 1. Environment Strategy
```
Development (dev)
    ↓ Daily Builds
Staging (staging)
    ↓ Release Candidates
Production (prod)
    ↓ App Store
```

### 2. CI/CD Pipeline
- **Source Control**: GitHub with branch protection
- **Build System**: Xcode Cloud (planned)
- **Testing**: Unit, Integration, UI tests
- **Distribution**: TestFlight → App Store

### 3. Monitoring & Analytics
- **Crashlytics**: Crash reporting and diagnostics
- **Analytics**: User behavior tracking
- **Performance Monitoring**: App performance metrics
- **Cloud Logging**: Server-side logging

## Scalability Considerations

### 1. Database Scaling
- **Sharding Strategy**: User-based sharding
- **Index Optimization**: Composite indexes for queries
- **Read Replicas**: Planned for high traffic

### 2. Function Scaling
- **Auto-scaling**: Configured for all functions
- **Cold Start Mitigation**: Minimum instances for critical functions
- **Resource Limits**: CPU and memory limits defined

### 3. Client Scaling
- **Progressive Disclosure**: Features loaded as needed
- **Pagination**: Large data sets paginated
- **Resource Management**: Memory-efficient data structures

## Technical Debt & Future Improvements

### Rebrand-Specific Technical Tasks
1. **Bundle ID Migration**: Update all references from com.growthlabs.growthmethod to com.growthlabs.growthtraining
2. **Firebase Project Migration**: Transition from growth-training-app to growth-training
3. **Content References**: Replace all Angion Method terminology with Growth Training
4. **Knowledge Base**: Deploy PE-focused content to ai_coach_knowledge collection
5. **StoreKit Configuration**: Update subscription product IDs for new bundle
6. **APNS Certificates**: Regenerate for new bundle identifier

### Current Technical Debt
1. **Widget Extension Compilation**: Some Live Activity files need cleanup
2. **Test Coverage**: Integration tests need expansion
3. **Error Handling**: Some edge cases need better handling

### Planned Improvements (Post-Rebrand)
1. **Community Features**: Routine sharing for r/ScienceofPE and r/GettingBigger
2. **Safety Enhancements**: Advanced injury prevention tracking
3. **Scientific Metrics**: Evidence-based progress indicators
4. **Offline Mode**: Full offline capability with sync

---

## Related Documentation
- [Technical Stack Details](./tech-stack.md)
- [Coding Standards](./coding-standards.md)
- [Source Tree Structure](./source-tree.md)
- [Growth Training Rebrand PRD](../prd/growth-training-rebrand-prd.md)
- [Rebrand Epics](../prd/epic-*.md)