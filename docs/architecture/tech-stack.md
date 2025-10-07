# Growth Training Technology Stack
<!-- Powered by BMAD™ Core -->

## Overview
Technology stack for the Growth Training app rebrand (formerly Angion Method), targeting r/ScienceofPE and r/GettingBigger communities.

## Technology Choices

| Category             | Technology              | Version / Details | Description / Purpose                   | Justification |
| :------------------- | :---------------------- | :---------------- | :-------------------------------------- | :------------ |
| **Languages**        | Swift                   | 5.10+             | Primary iOS app development language    | Native performance, SwiftUI support |
|                      | JavaScript              | ES2020            | Firebase Cloud Functions                | Node.js ecosystem, Firebase SDK |
|                      | TypeScript              | 5.x               | Type-safe Firebase Functions (optional) | Better maintainability |
| **iOS Platform**     | iOS                     | 16.0+ minimum     | Target platform                         | Live Activities require iOS 16.1+ |
|                      | SwiftUI                 | 4.0+              | UI framework                            | Modern declarative UI |
|                      | UIKit                   | Legacy support    | Some components still use UIKit         | Gradual migration |
| **Frameworks**       | Combine                 | Latest            | Reactive programming                    | Native Apple solution |
|                      | ActivityKit             | iOS 16.1+         | Live Activities & Dynamic Island        | Real-time timer updates |
|                      | StoreKit 2              | iOS 15+           | In-app purchases                        | Modern subscription API |
| **Backend Platform** | Firebase                | 10.15.0+          | Complete backend solution               | Comprehensive BaaS |
| **Firebase Services**| Authentication          | Latest            | User authentication                     | Multiple auth providers |
|                      | Firestore               | Latest            | NoSQL database                          | Real-time sync, offline support |
|                      | Cloud Functions         | v2                | Serverless backend logic                | Auto-scaling, cost-effective |
|                      | Cloud Storage           | Latest            | File storage                            | User uploads, assets |
|                      | Remote Config           | Latest            | Feature flags & configuration           | A/B testing, gradual rollouts |
|                      | Analytics               | Latest            | User behavior tracking                  | Insights and metrics |
|                      | Crashlytics             | Latest            | Crash reporting                         | Stability monitoring |
|                      | App Check               | Latest            | API security                            | Prevent abuse |
| **AI/ML**            | Vertex AI               | Latest            | AI Coach implementation                 | Google's unified AI platform |
|                      | Gemini Pro              | 1.5               | LLM for PE guidance                     | Safety-focused responses |
| **Cloud Platform**   | Google Cloud Platform   | N/A               | Infrastructure provider                 | Firebase integration |
| **Cloud Services**   | Secret Manager          | Latest            | Secure credential storage               | APNS keys, API keys |
|                      | Cloud Logging           | Latest            | Centralized logging                     | Debugging, monitoring |
|                      | IAM                     | Latest            | Access control                          | Security best practices |
| **Push Notifications**| APNS                   | HTTP/2            | iOS push notifications                  | Live Activity updates |
|                      | FCM                     | Latest            | Firebase Cloud Messaging                | Standard notifications |
| **Development Tools**| Xcode                  | 15.0+             | iOS development IDE                     | Required for iOS development |
|                      | VS Code                 | Latest            | Firebase Functions development          | JavaScript/TypeScript |
|                      | npm/yarn                | Latest            | Package management                      | Node.js dependencies |
| **Testing**          | XCTest                  | Latest            | iOS unit/integration testing            | Native Apple testing |
|                      | XCUITest                | Latest            | iOS UI testing                          | Automated UI tests |
|                      | Firebase Test Lab       | Latest            | Cloud device testing                    | Real device testing |
| **CI/CD**            | GitHub Actions          | N/A               | Continuous Integration                  | Automation workflows |
|                      | TestFlight              | N/A               | Beta distribution                       | Apple's beta platform |
|                      | App Store Connect       | N/A               | Production deployment                   | Official distribution |
| **Monitoring**       | Firebase Performance    | Latest            | App performance monitoring              | Performance insights |
|                      | Firebase Crashlytics    | Latest            | Crash reporting & diagnostics           | Stability tracking |
| **Version Control**  | Git                     | Latest            | Source control                          | Industry standard |
|                      | GitHub                  | N/A               | Repository hosting                      | Collaboration platform |

## Rebrand-Specific Technology Considerations

### Bundle ID Migration
- **From**: com.growthlabs.growthmethod
- **To**: com.growthlabs.growthtraining
- **Impact**: Affects StoreKit, APNS, Keychain, App Groups

### Firebase Project Migration
- **From**: growth-training-app
- **To**: growth-training
- **Services**: All Firebase services need reconfiguration

### Knowledge Base Technology
- **Storage**: Firestore collection (ai_coach_knowledge)
- **Search**: Vector embeddings for RAG
- **Safety**: Response filtering for PE content

### Subscription Products (StoreKit)
- **Weekly**: $4.99 (com.growthlabs.growthmethod.subscription.premium.weekly)
- **3-Month**: $29.99 (com.growthlabs.growthmethod.subscription.premium.quarterly)
- **Yearly**: $49.99 (com.growthlabs.growthmethod.subscription.premium.yearly)
- **Note**: Product IDs to be updated post-migration

## Third-Party Dependencies

### iOS (Swift Package Manager)
- Firebase iOS SDK (10.15.0+)
- Other minimal dependencies to reduce app size

### Firebase Functions (npm)
- firebase-admin (latest)
- firebase-functions (v2)
- @google-cloud/aiplatform (Vertex AI)
- node-fetch (HTTP requests)
- express (optional, for complex routing)

## Security Stack
- **App Check**: API attestation
- **Keychain Services**: Secure credential storage
- **Biometric Authentication**: Face ID/Touch ID
- **TLS 1.3**: All network communications
- **Secret Manager**: Server-side secrets

## Performance Optimizations
- **SwiftUI Lazy Loading**: Views loaded on demand
- **Firestore Offline Persistence**: Local cache
- **Image Optimization**: Multiple resolutions
- **Live Activity Efficiency**: Native timer displays
- **Function Cold Start Mitigation**: Minimum instances

## Change Log

| Change        | Date       | Version | Description                                    | Author |
| ------------- | ---------- | ------- | ---------------------------------------------- | ------ |
| Initial draft | 2025-10-03 | 1.0     | Complete tech stack for Growth Training rebrand | BMad Orchestrator |
| Bundle update | 2025-10-03 | 1.1     | Added subscription tier details from StoreKit  | BMad Orchestrator |

---

## Related Documentation
- [Architecture Overview](./architecture-main.md)
- [Coding Standards](./coding-standards.md)
- [Growth Training Rebrand PRD](../prd/growth-training-rebrand-prd.md)