# Epic 1: Infrastructure & Platform Setup

## Epic Overview
Set up new Firebase and Google Cloud infrastructure for Growth Training app

**Priority**: P0 - Critical
**Estimated Effort**: 3 days
**Dependencies**: None
**Owner**: DevOps/Platform Team

## Epic Goals
- Establish new Firebase project with multi-environment setup
- Configure all required Firebase services
- Set up Google Cloud project with necessary APIs
- Generate and integrate new configuration files

## Acceptance Criteria
- [ ] New Firebase project created and configured
- [ ] Google Cloud project linked and billing enabled
- [ ] All Firebase services activated and configured
- [ ] Configuration files generated for all environments
- [ ] APNS certificates uploaded and configured
- [ ] App Check configured with debug tokens

## User Stories

### Story 1.1: Create Firebase Project
**As a** platform engineer
**I want to** create a new Firebase project
**So that** we have isolated infrastructure for Growth Training

**Tasks:**
- Create Firebase project "growth-training"
- Add jon@growthlabs.coach as owner
- Configure project settings
- Set up billing alerts

**Acceptance Criteria:**
- Project accessible at console.firebase.google.com
- Owner has full admin access
- Billing configured

---

### Story 1.2: Configure Firebase Services
**As a** developer
**I want to** enable all required Firebase services
**So that** the app has full backend functionality

**Tasks:**
- Enable Firebase Authentication
- Set up Firestore Database
- Configure Cloud Functions
- Enable Analytics & Crashlytics
- Set up Cloud Messaging
- Configure App Check

**Acceptance Criteria:**
- All services showing "enabled" status
- Initial security rules configured
- Database indexes created

---

### Story 1.3: Set Up Google Cloud Project
**As a** platform engineer
**I want to** configure Google Cloud services
**So that** advanced features like AI are available

**Tasks:**
- Create GCP project linked to Firebase
- Enable Vertex AI API
- Configure IAM permissions
- Set up service accounts
- Configure billing

**Acceptance Criteria:**
- GCP project linked to Firebase
- Vertex AI API enabled
- Service accounts created
- Billing account attached

---

### Story 1.4: Configure APNS for Push Notifications
**As a** iOS developer
**I want to** set up push notification certificates
**So that** Live Activities and notifications work

**Tasks:**
- Generate APNS certificates in Apple Developer Portal
- Upload certificates to Firebase
- Configure push notification settings
- Test push delivery

**Acceptance Criteria:**
- APNS certificates uploaded
- Push notifications delivering to test devices
- Live Activity push updates working

---

### Story 1.5: Generate Environment Configurations
**As a** developer
**I want to** create environment-specific config files
**So that** the app can connect to Firebase

**Tasks:**
- Generate dev.GoogleService-Info.plist
- Generate staging.GoogleService-Info.plist
- Generate GoogleService-Info.plist (production)
- Update bundle identifiers in each file
- Document configuration differences

**Acceptance Criteria:**
- All plist files generated
- Bundle IDs match new scheme
- Files contain correct project IDs

---

### Story 1.6: Configure App Check
**As a** security engineer
**I want to** set up App Check
**So that** the backend is protected from abuse

**Tasks:**
- Enable App Check in Firebase Console
- Configure debug token provisioning
- Set up App Check for each environment
- Document debug token process
- Test App Check validation

**Acceptance Criteria:**
- App Check enabled for all services
- Debug tokens registered
- Validation working in test app

---

### Story 1.7: Set Up Multi-Environment Architecture
**As a** DevOps engineer
**I want to** configure multiple environments
**So that** we have proper dev/staging/prod separation

**Tasks:**
- Create development environment configuration
- Create staging environment configuration
- Create production environment configuration
- Set up environment-specific security rules
- Configure environment variables

**Acceptance Criteria:**
- Three separate environments configured
- Each environment isolated
- Security rules appropriate per environment
- Environment switching documented

---

## Technical Notes

### Firebase Project Structure
```
growth-training/
├── development/
│   ├── auth
│   ├── firestore
│   └── functions
├── staging/
│   ├── auth
│   ├── firestore
│   └── functions
└── production/
    ├── auth
    ├── firestore
    └── functions
```

### Required APIs
- Firebase Auth API
- Firestore API
- Cloud Functions API
- Cloud Messaging API
- Vertex AI API
- Cloud Billing API

### Security Considerations
- Enable audit logging
- Configure least-privilege IAM
- Set up monitoring alerts
- Enable DDoS protection

## Risks & Mitigations
- **Risk**: Service quotas exceeded
  - **Mitigation**: Request quota increases proactively
- **Risk**: Configuration mismatch
  - **Mitigation**: Automated validation scripts
- **Risk**: Migration downtime
  - **Mitigation**: Parallel infrastructure until cutover

## Definition of Done
- [ ] All services operational in Firebase Console
- [ ] Configuration files integrated in Xcode project
- [ ] Push notifications tested on physical device
- [ ] App Check validation passing
- [ ] Documentation updated
- [ ] Team trained on new infrastructure