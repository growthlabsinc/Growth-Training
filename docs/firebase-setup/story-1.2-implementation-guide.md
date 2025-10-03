# Story 1.2 Implementation Guide: Configure Firebase Services

## Firebase Console Access
Project URL: https://console.firebase.google.com/project/growth-training-app/overview

## Task 1: Enable Firebase Authentication

### Steps to Complete:

1. **Navigate to Authentication**
   - Go to: https://console.firebase.google.com/project/growth-training-app/authentication
   - Click "Get started" if not already enabled

2. **Enable Email/Password Provider**
   - Go to "Sign-in method" tab
   - Click on "Email/Password"
   - Toggle "Enable" switch ON
   - Keep "Email link (passwordless sign-in)" OFF for now
   - Click "Save"

3. **Enable Google Provider**
   - In "Sign-in method" tab, click "Add new provider"
   - Select "Google"
   - Toggle "Enable" switch ON
   - Set public-facing name: "Growth Training"
   - Set support email: jon@growthlabs.coach
   - Expand "Web SDK configuration"
   - Note the Web client ID (will be needed for iOS config)
   - Click "Save"

4. **Enable Anonymous Authentication**
   - In "Sign-in method" tab, find "Anonymous"
   - Toggle "Enable" switch ON
   - Click "Save"

5. **Configure Authorized Domains**
   - Go to "Settings" tab
   - Under "Authorized domains"
   - Add: growthlabs.coach
   - Add: growth-training-app.firebaseapp.com (should be auto-added)

### Verification:
✅ Email/Password shows "Enabled"
✅ Google shows "Enabled"
✅ Anonymous shows "Enabled"
✅ growthlabs.coach in authorized domains

---

## Task 2: Set up Firestore Database

### Steps to Complete:

1. **Create Database**
   - Go to: https://console.firebase.google.com/project/growth-training-app/firestore
   - Click "Create database"
   - Select "Start in production mode"
   - Click "Next"

2. **Choose Location**
   - Select "nam5 (United States)" for multi-region
   - This provides good coverage for US users
   - Click "Enable"

3. **Initial Security Rules**
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       // Allow authenticated users to read/write their own data
       match /users/{userId} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }

       // AI Coach knowledge base - read only for authenticated users
       match /ai_coach_knowledge/{document=**} {
         allow read: if request.auth != null;
         allow write: if false; // Admin only via console
       }

       // Session logs - users can read/write their own
       match /session_logs/{userId}/{document=**} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }

       // App configuration - read only for all authenticated users
       match /app_config/{document=**} {
         allow read: if request.auth != null;
         allow write: if false; // Admin only
       }
     }
   }
   ```

4. **Create Required Indexes**
   - Go to "Indexes" tab
   - Add composite index for session_logs:
     - Collection: session_logs
     - Fields: userId (Ascending), createdAt (Descending)
   - Add index for ai_coach_knowledge:
     - Collection: ai_coach_knowledge
     - Fields: category (Ascending), priority (Descending)

### Verification:
✅ Firestore shows as enabled
✅ Location set to nam5
✅ Security rules configured
✅ Indexes created

---

## Task 3: Configure Cloud Functions

### Steps to Complete:

1. **Verify Blaze Plan**
   - Go to: https://console.firebase.google.com/project/growth-training-app/functions
   - Should see Functions dashboard (requires Blaze plan)
   - If not enabled, upgrade to Blaze plan first

2. **Note Configuration**
   - Functions will be deployed from local `/functions` directory
   - Default region: us-central1
   - Runtime: Node.js 20

3. **Document Endpoints**
   - Base URL: https://us-central1-growth-training-app.cloudfunctions.net
   - Key functions:
     - /generateAIResponse - AI Coach
     - /updateLiveActivity - Live Activity updates
     - /processAnalytics - Analytics processing

### Verification:
✅ Functions dashboard accessible
✅ Blaze plan active
✅ Endpoint URLs documented

---

## Task 4: Enable Analytics & Crashlytics

### Analytics Setup:

1. **Enable Google Analytics**
   - Go to: https://console.firebase.google.com/project/growth-training-app/analytics
   - Should already be enabled from project creation
   - If not, click "Enable Google Analytics"

2. **Configure Settings**
   - Go to "Settings" (gear icon)
   - Set data retention to "14 months"
   - Enable "Reset analytics data on app reinstall"
   - Enable "Google signals" for demographics

### Crashlytics Setup:

1. **Enable Crashlytics**
   - Go to: https://console.firebase.google.com/project/growth-training-app/crashlytics
   - Click "Enable Crashlytics"
   - Note: Full integration requires SDK in app (already configured)

2. **Configure Alerts**
   - Set up velocity alerts for crash rate increases
   - Configure email notifications to: jon@growthlabs.coach

### Verification:
✅ Analytics enabled with 14-month retention
✅ Crashlytics enabled
✅ Alert notifications configured

---

## Task 5: Set up Cloud Messaging

### Steps to Complete:

1. **Access Cloud Messaging**
   - Go to: https://console.firebase.google.com/project/growth-training-app/messaging

2. **Note Configuration Details**
   - Server Key: [Will be displayed in console]
   - Sender ID: 997901246801 (from project number)

3. **iOS Configuration Prep**
   - APNs certificates will be added in Story 1.4
   - For now, note that FCM is enabled

4. **Document FCM Details**
   ```yaml
   FCM Configuration:
   - Project ID: growth-training-app
   - Sender ID: 997901246801
   - Server Key: [Copy from console]
   - iOS Bundle ID: com.growthlabs.growthtraining
   ```

### Verification:
✅ Cloud Messaging enabled
✅ Server Key documented
✅ Ready for APNs configuration

---

## Task 6: Configure App Check

### Steps to Complete:

1. **Enable App Check**
   - Go to: https://console.firebase.google.com/project/growth-training-app/appcheck
   - Click "Get started"

2. **Register iOS App**
   - Click "Register" under iOS apps
   - Select "App Attest" as provider
   - Enter bundle ID: com.growthlabs.growthtraining

3. **Configure Service Enforcement (Monitor Mode)**

   For each service, start in MONITOR mode:

   **Firestore:**
   - Click on Firestore Database
   - Select "Monitor mode"
   - This logs violations without blocking

   **Authentication:**
   - Click on Authentication
   - Select "Monitor mode"

   **Cloud Functions:**
   - Click on Cloud Functions
   - Select "Monitor mode"

   **Cloud Storage:**
   - Click on Cloud Storage (if visible)
   - Select "Monitor mode"

4. **Debug Token Setup**
   - Go to "Apps" tab
   - Click on the iOS app
   - Go to "Debug tokens"
   - Note: Debug tokens will be generated from app
   - Document process for developers

### Debug Token Process:
```swift
// In AppCheckDebugView.swift:
// 1. Run app in debug mode
// 2. Go to Settings → Development Tools → App Check Debug
// 3. Copy generated token
// 4. Register in Firebase Console → App Check → Apps → Debug tokens
```

### Verification:
✅ App Check enabled
✅ iOS app registered with App Attest
✅ All services in Monitor mode
✅ Debug token process documented

---

## Task 7: Configure Security Rules

### Firestore Rules (Production Ready):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    // User profiles
    match /users/{userId} {
      allow read: if isOwner(userId);
      allow create: if isOwner(userId);
      allow update: if isOwner(userId);
      allow delete: if false; // Soft delete only
    }

    // AI Coach knowledge base - read only
    match /ai_coach_knowledge/{document=**} {
      allow read: if isAuthenticated();
      allow write: if false; // Admin console only
    }

    // User session logs
    match /session_logs/{userId}/{document=**} {
      allow read: if isOwner(userId);
      allow create: if isOwner(userId);
      allow update: if isOwner(userId) &&
        request.resource.data.userId == userId;
      allow delete: if false; // Preserve history
    }

    // AI Coach conversations
    match /ai_conversations/{userId}/{document=**} {
      allow read: if isOwner(userId);
      allow create: if isOwner(userId);
      allow update: if isOwner(userId);
      allow delete: if isOwner(userId); // GDPR compliance
    }

    // App configuration
    match /app_config/{document=**} {
      allow read: if true; // Public config
      allow write: if false; // Admin only
    }

    // Feature flags
    match /feature_flags/{document=**} {
      allow read: if isAuthenticated();
      allow write: if false; // Admin only
    }
  }
}
```

### Testing Rules:

1. **Use Rules Simulator**
   - Go to Firestore → Rules → Rules playground
   - Test authenticated user access to own data
   - Test cross-user access (should fail)
   - Test knowledge base read access

2. **Test Cases:**
   - ✅ User can read/write own profile
   - ❌ User cannot read other's profile
   - ✅ Authenticated user can read knowledge base
   - ❌ User cannot write to knowledge base
   - ✅ User can create session logs
   - ❌ User cannot delete session logs

### Verification:
✅ Rules deployed successfully
✅ All test cases pass in simulator
✅ Production-ready security

---

## Task 8: Document Service Configuration

### Update firebase-config.md:

```markdown
## Enabled Services (Story 1.2 - Completed)

### Authentication
- Status: ✅ Enabled
- Providers:
  - Email/Password: Enabled
  - Google Sign-In: Enabled
  - Anonymous: Enabled
- Authorized Domains:
  - growthlabs.coach
  - growth-training-app.firebaseapp.com

### Firestore Database
- Status: ✅ Enabled
- Location: nam5 (United States)
- Mode: Production (with security rules)
- Collections configured:
  - users
  - ai_coach_knowledge
  - session_logs
  - ai_conversations
  - app_config
  - feature_flags

### Cloud Functions
- Status: ✅ Ready for deployment
- Region: us-central1
- Runtime: Node.js 20
- Endpoints documented

### Analytics
- Status: ✅ Enabled
- Data retention: 14 months
- Google Signals: Enabled

### Crashlytics
- Status: ✅ Enabled
- Alerts configured

### Cloud Messaging
- Status: ✅ Enabled
- Sender ID: 997901246801
- Awaiting APNs certificates (Story 1.4)

### App Check
- Status: ✅ Enabled (Monitor Mode)
- Provider: App Attest (iOS)
- Enforcement: Monitor only (all services)
```

---

## Completion Checklist

- [ ] **Authentication**: All 3 providers enabled
- [ ] **Firestore**: Database created with rules
- [ ] **Functions**: Dashboard accessible
- [ ] **Analytics**: Configured with retention
- [ ] **Crashlytics**: Enabled with alerts
- [ ] **Messaging**: Configuration documented
- [ ] **App Check**: Monitor mode for all services
- [ ] **Security Rules**: Deployed and tested
- [ ] **Documentation**: firebase-config.md updated

## Next Steps

After completing all tasks:
1. Test authentication flow in Firebase Console
2. Verify Firestore rules in simulator
3. Check App Check monitoring dashboard
4. Proceed to Story 1.3: Set Up Google Cloud Project