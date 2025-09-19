# Firebase Configuration - Growth Training

## Project Details
- **Project Name**: Growth Training
- **Project ID**: growth-training-app
- **Project Number**: 997901246801
- **Parent Organization**: growthlabs.coach
- **Web API Key**: AIzaSyC8ZuIdw6ITfno5m2p0RK7qIrQmY2X7LPU
- **Console URL**: https://console.firebase.google.com/project/growth-training-app
- **Created Date**: November 7, 2024
- **Created By**: Current user
- **Owner**: jon@growthlabs.coach (accepted - has full admin access)

## Billing Configuration
- **Plan**: Blaze (Pay as you go)
- **Billing Account**: [Linked during setup]
- **Budget Alerts**:
  - First threshold: $100
  - Second threshold: $500
  - Third threshold: $1000
- **Alert Notifications**: Email notifications enabled

## Enabled Services (Story 1.2 - Completed)

### Authentication
- **Status**: ✅ Enabled
- **Providers**:
  - Email/Password: Enabled
  - Google Sign-In: Enabled
  - Anonymous: Enabled
- **Authorized Domains**:
  - growthlabs.coach
  - growth-training-app.firebaseapp.com

### Firestore Database
- **Status**: ✅ Enabled
- **Location**: nam5 (United States)
- **Mode**: Production (with security rules)
- **Collections configured**:
  - users
  - ai_coach_knowledge
  - session_logs
  - ai_conversations
  - app_config
  - feature_flags

### Cloud Functions
- **Status**: ✅ Ready for deployment
- **Region**: us-central1
- **Runtime**: Node.js 20
- **Base URL**: https://us-central1-growth-training-app.cloudfunctions.net

### Analytics
- **Status**: ✅ Enabled
- **Data retention**: 14 months
- **Google Signals**: Enabled

### Crashlytics
- **Status**: ✅ Enabled
- **Alerts**: Configured for jon@growthlabs.coach

### Cloud Messaging
- **Status**: ✅ Enabled
- **Sender ID**: 997901246801
- **Note**: Awaiting APNs certificates (Story 1.4)

### App Check
- **Status**: ✅ Enabled (Monitor Mode)
- **Provider**: App Attest (iOS)
- **Bundle ID**: com.growthlabs.growthtraining
- **Enforcement**: Monitor only (all services)

## Next Steps
The following services need to be configured in subsequent stories:

1. **Story 1.3**: Set Up Google Cloud Project
   - Link GCP project
   - Enable Vertex AI API
   - Configure IAM
   - Set up service accounts

2. **Story 1.4**: Configure APNS
   - Generate certificates
   - Upload to Firebase
   - Test push notifications

## Environment Configuration
This project will support three environments:
- **Development** (dev)
- **Staging** (staging)
- **Production** (prod)

Each will have its own GoogleService-Info.plist file generated in Story 1.5.

## Important Notes
- This is a brownfield project - preserve all existing functionality
- The app currently uses Firebase project: growth-70a85 (to be migrated)
- DO NOT modify core app logic or UI functionality
- ONLY update Firebase configuration and environment settings