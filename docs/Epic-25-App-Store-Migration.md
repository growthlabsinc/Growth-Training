# Epic 25: App Store Connect Migration & Production Release Preparation

## Overview
Prepare and migrate the Growth app from development environment to App Store Connect for production release. This epic covers all necessary steps to ensure the app is ready for submission, review, and distribution on the App Store.

## Business Goals
- **Go-to-Market Readiness**: Prepare app for public release
- **Quality Assurance**: Ensure production-ready build with no critical issues
- **Compliance**: Meet all App Store requirements and guidelines
- **Infrastructure**: Set up production environment and monitoring

## Current State
- ✅ App functional in development environment
- ✅ Firebase development/staging environments configured
- ✅ Core features implemented (routines, methods, timer, progress tracking)
- ✅ Subscription infrastructure backend ready (Epic 23)
- ✅ App metadata prepared (Story 10.4)
- ✅ Bundle ID configured: `com.growthlabs.growthmethod`
- ✅ Development Team ID: 62T6J77P6R
- ❌ No production build configuration
- ❌ No App Store Connect app record
- ❌ Missing production certificates/profiles
- ❌ Missing some privacy usage descriptions
- ❌ No app icon for App Store (1024x1024)
- ❌ No app screenshots prepared

## Prerequisites
- Apple Developer Program membership active
- App Store Connect access configured
- Production Firebase project ready
- Domain/website for privacy policy and support

## Epic Scope

### 1. App Store Connect Setup
- Create new app record in App Store Connect
- Configure app information and metadata
- Set up app pricing (free with in-app purchases)
- Configure in-app purchase products
- Set up TestFlight for beta testing

### 2. Production Build Configuration
- Create production build configuration in Xcode
- Configure production bundle identifier
- Set up production code signing
- Update Firebase configuration for production
- Remove debug code and logging

### 3. App Metadata & Assets
- App name and subtitle
- App description (from existing metadata)
- Keywords for App Store search
- App icon (1024x1024)
- Screenshots for all required device sizes
- Privacy policy URL
- Support URL

### 4. Legal & Compliance
- Privacy policy document
- Terms of service
- Medical disclaimer (already in app)
- Age rating questionnaire (17+)
- Export compliance
- Content rights declaration

### 5. Production Environment Setup
- Production Firebase configuration
- Production push notification certificates
- App Store Server notifications endpoint
- Analytics and crash reporting
- App Check enforcement
- Security rules hardening

### 6. Testing & Quality Assurance
- Complete QA checklist
- Performance testing
- Memory leak detection
- Crash-free rate validation
- Accessibility compliance
- Device compatibility testing

### 7. Beta Testing Phase
- Internal TestFlight testing
- External TestFlight beta
- Beta feedback collection
- Critical bug fixes
- Performance optimization

## User Stories

### Story 25.1: App Store Connect Configuration
**As a** product owner  
**I want to** create and configure the app in App Store Connect  
**So that** we can submit builds and manage releases  

**Acceptance Criteria:**
- App record created with bundle ID `com.growthlabs.growthmethod`
- Basic information filled out
- In-app purchases configured ($4.99, $9.99, $19.99 tiers)
- TestFlight enabled

### Story 25.2: Production Build Setup
**As a** developer  
**I want to** configure production build settings  
**So that** we can create release-ready builds  

**Acceptance Criteria:**
- Production scheme created
- Code signing configured
- Firebase prod config integrated
- Debug code stripped
- Build uploads successfully

### Story 25.3: App Store Assets
**As a** marketing team  
**I want to** prepare all required App Store assets  
**So that** the app listing looks professional  

**Acceptance Criteria:**
- All screenshots captured (6.7", 6.5", 5.5", iPad)
- App icon finalized (1024x1024)
- Descriptions formatted
- Keywords optimized

### Story 25.4: Legal Documentation
**As a** legal compliance officer  
**I want to** ensure all legal requirements are met  
**So that** the app complies with regulations  

**Acceptance Criteria:**
- Privacy policy published
- Terms of service available
- Medical disclaimers verified
- Age rating accurate (17+)
- GDPR compliance documented

### Story 25.5: Production Infrastructure
**As a** DevOps engineer  
**I want to** set up production infrastructure  
**So that** the app runs reliably at scale  

**Acceptance Criteria:**
- Firebase production configured
- Push certificates uploaded
- Monitoring enabled
- Security rules production-ready
- Webhook endpoints configured

### Story 25.6: Beta Testing Program
**As a** QA lead  
**I want to** run a comprehensive beta test  
**So that** we catch issues before public release  

**Acceptance Criteria:**
- 50+ beta testers recruited
- Feedback system in place
- Critical bugs fixed
- Performance validated
- Crash rate < 0.1%

## Technical Requirements

### Build Configuration
```swift
// Production build settings
PRODUCT_BUNDLE_IDENTIFIER = com.growthlabs.growthmethod
MARKETING_VERSION = 1.0.0
CURRENT_PROJECT_VERSION = 1
SWIFT_ACTIVE_COMPILATION_CONDITIONS = RELEASE
DEBUG_INFORMATION_FORMAT = dwarf-with-dsym
```

### Required Info.plist Updates
```xml
<!-- User Tracking -->
<key>NSUserTrackingUsageDescription</key>
<string>This allows us to provide you with a personalized experience and improve our services</string>

<!-- Push Notifications -->
<key>NSUserNotificationUsageDescription</key>
<string>Receive reminders for your training sessions and important updates</string>
```

### App Store Screenshot Requirements
- iPhone 6.9" Display (1320 x 2868) - iPhone 15 Pro Max
- iPhone 6.5" Display (1284 x 2778) - iPhone 14 Plus
- iPhone 5.5" Display (1242 x 2208) - iPhone 8 Plus
- iPad Pro 12.9" Display (2048 x 2732)

### In-App Purchase Configuration
1. **Basic Tier**
   - Product ID: `com.growthlabs.growthmethod.basic_monthly`
   - Price: $4.99/month
   - Features: Core features + 10 methods

2. **Premium Tier**
   - Product ID: `com.growthlabs.growthmethod.premium_monthly`
   - Price: $9.99/month
   - Features: All methods + AI Coach

3. **Elite Tier**
   - Product ID: `com.growthlabs.growthmethod.elite_monthly`
   - Price: $19.99/month
   - Features: Everything + Priority support

## Implementation Timeline

### Week 1: Foundation
- [ ] Create App Store Connect record
- [ ] Configure production Firebase
- [ ] Set up production build scheme
- [ ] Create provisioning profiles
- [ ] Update Info.plist with privacy descriptions

### Week 2: Assets & Content
- [ ] Create 1024x1024 app icon
- [ ] Capture all screenshots
- [ ] Format app descriptions
- [ ] Prepare legal documents
- [ ] Configure in-app purchases

### Week 3: Build & Infrastructure
- [ ] Configure production build
- [ ] Set up monitoring
- [ ] Deploy webhook endpoints
- [ ] Security audit
- [ ] Remove debug code

### Week 4: Testing
- [ ] Internal testing
- [ ] TestFlight beta launch
- [ ] Collect feedback
- [ ] Fix critical issues
- [ ] Performance optimization

### Week 5: Submission
- [ ] Final build preparation
- [ ] App Store listing review
- [ ] Submit for review
- [ ] Monitor review status
- [ ] Prepare for launch

## Success Metrics
- **Build Success**: Production build compiles without warnings
- **Crash-Free Rate**: >99.5% in beta testing
- **Beta Feedback**: Average rating >4.0
- **Review Approval**: Approved within 2 attempts
- **Infrastructure**: <200ms API response time
- **Security**: No critical vulnerabilities

## Risks & Mitigations

### Risk: App Store Rejection
**Reasons:**
- Medical/health content concerns
- Subscription implementation issues
- Privacy policy incomplete

**Mitigation:**
- Review guidelines thoroughly
- Emphasize educational nature
- Test subscription flows extensively
- Complete privacy documentation

### Risk: Production Firebase Issues
**Mitigation:**
- Test in staging first
- Gradual rollout
- Monitoring alerts
- Rollback plan ready

### Risk: Subscription Configuration Problems
**Mitigation:**
- Sandbox testing
- Receipt validation testing
- Clear documentation
- Support team prepared

## Post-Launch Checklist
- [ ] Monitor crash reports
- [ ] Track user analytics
- [ ] Respond to reviews
- [ ] Plan version 1.1
- [ ] Monitor subscription metrics
- [ ] Gather feature requests

## Dependencies
- Apple Developer account (62T6J77P6R)
- Firebase production project
- App Store Connect access
- Privacy policy website
- Support email configured

## Definition of Done
- App approved by App Store review
- Successfully published to App Store
- No critical bugs in production
- All subscription tiers working
- Monitoring active and stable
- Documentation complete

## Next Epic
After successful App Store launch, proceed with **Epic 24: Subscription Paywall & Trial Implementation** to add:
- 5-day free trial
- Signup paywall flow
- Feature gating
- Trial expiration handling