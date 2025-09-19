# Product Requirements Document: Growth Training Rebrand

## Executive Summary

This PRD outlines the comprehensive rebranding of the existing iOS application from "Angion Method" (targeting erectile dysfunction exercises) to "Growth Training" (targeting the ScienceofPE and GettingBigger communities focused on length and girth gains). This is a brownfield project with 100% implementation complete, requiring strategic rebranding while maintaining core functionality.

## Project Overview

### Current State
- **Product Name**: Angion Method App
- **Target Community**: r/AngionMethod (ED exercises)
- **Firebase Project**: growth-70a85
- **Bundle ID**: com.growthlabs.growthmethod

### Target State
- **Product Name**: Growth Training App
- **Target Communities**: r/ScienceofPE, r/GettingBigger
- **Firebase Project**: growth-training (new)
- **Bundle ID**: com.growthlabs.growthtraining
- **Owner**: jon@growthlabs.coach

### Key Constraints
- Maintain existing app architecture and functionality
- Preserve Live Activities and Dynamic Island features
- Keep timer system intact
- Minimal UI changes (subtle color adjustments only)

## Business Objectives

1. **Market Repositioning**: Pivot from ED-focused exercises to PE training protocols
2. **Community Alignment**: Serve the ScienceofPE and GettingBigger communities
3. **Scientific Approach**: Emphasize evidence-based, safety-first training
4. **User Safety**: Implement comprehensive safety guidelines and injury prevention

## Success Metrics

- Successful deployment to App Store with new branding
- Zero functionality regression
- AI Coach provides accurate, safe PE guidance
- All Live Activities function with new bundle IDs
- Firebase integration fully operational

## User Personas

### Primary: The Scientific PE Practitioner
- Active in r/ScienceofPE community
- Values evidence-based approaches
- Prioritizes safety and measured progress
- Uses tracking tools and analytics

### Secondary: The Growth Seeker
- Active in r/GettingBigger community
- Focused on practical results
- Interested in both length and girth gains
- Appreciates structured routines

## Technical Requirements

### Infrastructure
- New Firebase project with multi-environment setup
- Google Cloud project with Vertex AI enabled
- APNS configuration for push notifications
- App Check integration for security

### Content
- Complete exercise library replacement
- New AI knowledge base focused on PE safety
- Updated educational resources
- Revised onboarding flow

### Branding
- Subtle color scheme updates
- New visual assets and icons
- Updated terminology throughout
- Consistent scientific language

## Epics Overview

### Epic 1: Infrastructure & Platform Setup
Setting up new Firebase and Google Cloud infrastructure

### Epic 2: Content & Knowledge Migration
Replacing all Angion Method content with PE-focused training

### Epic 3: AI Coach Transformation
Updating AI system for safe PE guidance

### Epic 4: Visual & UX Rebranding
Updating UI elements and visual assets

### Epic 5: Codebase Refactoring
Updating all code references and terminology

### Epic 6: Quality Assurance & Launch
Comprehensive testing and deployment

## Risk Assessment

### High Risk
- **Firebase Migration**: Potential connectivity issues
- **Bundle ID Changes**: May affect Live Activities
- **AI Safety**: Must ensure safe PE guidance

### Medium Risk
- **Asset Replacement**: 80+ images to update
- **Code Updates**: 600+ files to modify
- **App Store Review**: New focus may trigger review

### Mitigation Strategies
- Phased rollout with extensive testing
- Maintain backup of original configuration
- Comprehensive QA on physical devices
- Clear safety disclaimers in app

## Timeline

- **Week 1**: Infrastructure setup and content preparation
- **Week 2**: Implementation and code updates
- **Week 3**: Testing, refinement, and deployment
- **Total Duration**: 3 weeks (15 business days)

## Technical Architecture Impact

### Affected Systems
- Firebase Authentication
- Firestore Database
- Cloud Functions
- Live Activities
- Push Notifications
- AI Coach Integration

### Unchanged Systems
- Timer functionality
- Core app architecture
- MVVM structure
- SwiftUI implementation

## Compliance & Safety

### Key Requirements
- GDPR compliance maintained
- Medical disclaimer updates
- Safety warnings prominent
- Age verification (18+)
- Clear terms of service

## Rollback Plan

If critical issues arise:
1. Restore original GoogleService-Info.plist files
2. Revert bundle identifiers
3. Restore original Firebase project connection
4. Rollback knowledge base content
5. Restore original assets

## Approval & Sign-off

- **Product Owner**: jon@growthlabs.coach
- **Technical Lead**: _____________
- **QA Lead**: _____________
- **Approval Date**: _____________

---

## Appendix: Terminology Mapping

| Current Term | New Term |
|--------------|----------|
| Angion Method | Growth Training |
| Methods | Training Protocols |
| AM Session | Training Session |
| Vascular Development | Tissue Expansion |
| AM1.0, AM2.0, etc. | Progressive Training Levels |

## Next Steps

1. Review and approve this PRD
2. Create detailed epics and user stories
3. Set up new Firebase project
4. Begin implementation following epic priority

---
*Document Version*: 1.0
*Last Updated*: Current Date
*Status*: Draft