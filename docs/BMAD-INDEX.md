# BMAD Documentation Index - Growth Training App (Rebrand)
<!-- Powered by BMAD™ Core -->

## Project Overview
**Type**: Brownfield iOS Native Application (Rebrand Project)
**Current State**: Angion Method App → Growth Training App
**Status**: 100% Functional - Rebranding in Progress
**Platform**: iOS 16.0+ (Swift 5.10 + SwiftUI)
**Backend**: Firebase (Functions, Firestore, Auth)
**Target Communities**: r/ScienceofPE, r/GettingBigger

## Quick Navigation

### 📋 Product Documentation (PRD)
- **[Main PRD - Rebrand](./prd/growth-training-rebrand-prd.md)** - Complete rebranding requirements
- **Rebrand Epics**:
  - [Epic 1: Infrastructure](./prd/epic-1-infrastructure.md) - Firebase & GCloud setup
  - [Epic 2: Content Migration](./prd/epic-2-content-migration.md) - PE content replacement
  - [Epic 3: AI Coach](./prd/epic-3-ai-coach.md) - Safe PE guidance system
  - [Epic 4: UI Branding](./prd/epic-4-ui-branding.md) - Visual updates
  - [Epic 5: Code Refactoring](./prd/epic-5-code-refactoring.md) - Terminology updates
  - [Epic 6: Testing](./prd/epic-6-testing-validation.md) - QA and launch

### 🏗 Architecture Documentation
- **[Architecture Overview](./architecture/architecture-main.md)** - System design and components
- **[Technical Stack](./architecture/tech-stack.md)** - Technologies and frameworks
- **[Coding Standards](./architecture/coding-standards.md)** - Development guidelines
- **[Source Tree](./architecture/source-tree.md)** - Project structure

### 🚀 Operations & Deployment
- **[Deployment Guide](./operations/deployment-guide.md)** - Release procedures
- **[Firebase Setup](./firebase-setup/)** - Backend configuration
- **[Monitoring Guide](./operations/monitoring.md)** - Observability setup

### 📝 Story Management
- **[Current Stories](./stories/)** - Active development work
- **[Epic 3: AI Coach](./stories/3.*.md)** - AI implementation stories
- **[Epic 4: UI Updates](./stories/4.*.md)** - Design system updates

## Key Components

### iOS Application
```
Growth/
├── Features/          # Feature modules (Timer, Auth, etc.)
├── Core/             # Shared services and utilities
├── Resources/        # Assets and configurations
└── Application/      # App lifecycle and setup
```

### Firebase Functions
```
functions/
├── vertexAiProxy/    # AI Coach implementation
├── liveActivityUpdates.js  # APNS integration
└── userManagement.js       # User operations
```

### Widget Extension
```
GrowthTimerWidget/
├── LiveActivity/     # Live Activity views
└── AppIntents/       # Dynamic Island actions
```

## Critical Files Reference

### Configuration
- **[CLAUDE.md](../CLAUDE.md)** - AI assistant instructions
- **[.bmad-core/core-config.yaml](../.bmad-core/core-config.yaml)** - BMAD configuration
- **[firebase.json](../firebase.json)** - Firebase project config

### Implementation
- **[TimerService.swift](../Growth/Features/Timer/Services/TimerService.swift)** - Core timer logic
- **[LiveActivityManager.swift](../Growth/Features/Timer/LiveActivity/LiveActivityManager.swift)** - Live Activities
- **[SimplifiedEntitlementManagerWithTrial.swift](../Growth/Core/Services/SimplifiedEntitlementManagerWithTrial.swift)** - Subscription management
- **[vertexAiProxy/index.js](../functions/vertexAiProxy/index.js)** - AI Coach handler

## Development Workflows

### Common Tasks

#### 1. Start Development
```bash
# Open project
open Growth.xcodeproj

# Start Firebase emulators (optional)
cd functions && npm run serve
```

#### 2. Deploy Changes
```bash
# iOS: Archive in Xcode → Upload to TestFlight

# Firebase Functions
cd functions
npm run deploy
```

#### 3. Debug Issues
```bash
# Live Activity issues
./debug_live_activity.sh

# App Check issues
./diagnose_app_check.sh

# Build issues
./XCODE_DEEP_CLEAN.sh
```

### Environment Management

| Environment | Use Case | Activation |
|------------|----------|------------|
| Development | Local testing | Xcode Development scheme |
| Staging | QA testing | Xcode Staging scheme |
| Production | Live users | Xcode Release scheme |

## BMAD Agent Commands

### Available Agents
- `*agent dev` - Development tasks
- `*agent pm` - Project management
- `*agent qa` - Quality assurance
- `*agent architect` - Architecture decisions

### Useful Workflows
- `*workflow brownfield-fullstack` - Full-stack feature development
- `*task create-next-story` - Generate new story
- `*checklist story-dod-checklist` - Story completion check

## Project Status - Rebrand Progress

### ✅ Completed (Pre-Rebrand)
- Core timer functionality with Live Activities
- Firebase backend integration (old project)
- AI Coach with Vertex AI (Angion content)
- Subscription system with 3-day trial
- Progress tracking and analytics

### 🚧 Rebrand In Progress
- **Epic 3**: AI Coach transformation to PE focus
  - Story 3.5: Knowledge deployment scripts ✅
  - Story 3.6: Response filtering (active)
  - Story 3.7: Conversation templates (active)
- **Epic 4**: UI/UX Updates
  - Story 4.1: Color palette updates ✅

### 📅 Rebrand Remaining
- Complete Firebase migration to new project
- Update all bundle identifiers
- Replace remaining Angion references
- Deploy PE-focused knowledge base
- Final testing and App Store submission

## Support & Resources

### Internal
- [Emergency Contacts](./operations/emergency-contacts.md)
- [Security Protocols](./operations/security.md)
- [Troubleshooting Guide](./operations/troubleshooting.md)

### External
- [Firebase Console](https://console.firebase.google.com/project/growth-training-app)
- [App Store Connect](https://appstoreconnect.apple.com)
- [Apple Developer Portal](https://developer.apple.com)

---

**Last Updated**: 2025-10-03
**Maintained By**: Growth Labs Inc. Development Team
**BMAD Version**: 5.0