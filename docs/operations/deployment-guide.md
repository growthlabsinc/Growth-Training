# Deployment & Operations Guide
<!-- Powered by BMAD™ Core -->

## Overview

This guide covers deployment procedures, monitoring, and operational tasks for the Growth Training App across all environments.

## Environment Structure

### Available Environments

| Environment | Purpose | Firebase Project | Bundle ID |
|------------|---------|------------------|-----------|
| Development | Active development | growth-training-dev | com.growthlabs.growth.dev |
| Staging | Pre-production testing | growth-training-staging | com.growthlabs.growth.staging |
| Production | Live app | growth-training-app | com.growthlabs.growth |

## iOS App Deployment

### Pre-Deployment Checklist

#### Code Preparation
- [ ] All tests passing (`⌘+U` in Xcode)
- [ ] No compiler warnings
- [ ] Version number updated
- [ ] Build number incremented
- [ ] CHANGELOG.md updated

#### Firebase Verification
- [ ] Functions deployed successfully
- [ ] Firestore indexes created
- [ ] Remote Config updated
- [ ] App Check configured

#### Assets Verification
- [ ] App icons present for all sizes
- [ ] Launch screen configured
- [ ] Screenshots updated (if needed)

### Build Process

#### 1. Development Build
```bash
# Select Development scheme in Xcode
# Build and run (⌘+R)
# Automatic dev environment configuration
```

#### 2. TestFlight Build
```bash
# Select Release scheme
# Archive (Product → Archive)
# Upload to App Store Connect
# Add to TestFlight group
```

#### 3. Production Release
```bash
# Ensure all TestFlight feedback addressed
# Submit for App Review
# Monitor review status
# Release when approved
```

### Troubleshooting Build Issues

#### Common Problems
1. **Signing Errors**
   ```bash
   ./fix_archive_distribution.sh
   ```

2. **DerivedData Corruption**
   ```bash
   ./XCODE_DEEP_CLEAN.sh
   ```

3. **Widget Extension Errors**
   - Verify entitlements match
   - Check file memberships
   - Clean build folder

## Firebase Functions Deployment

### Prerequisites
```bash
cd functions
npm install
firebase login
firebase use growth-training-app  # or appropriate project
```

### Deployment Commands

#### Deploy All Functions
```bash
npm run deploy
# or
firebase deploy --only functions
```

#### Deploy Specific Functions
```bash
# AI Coach function
firebase deploy --only functions:generateAIResponse

# Live Activity updates
firebase deploy --only functions:updateLiveActivity

# User management
firebase deploy --only functions:deleteUserData
```

### Function Configuration

#### Environment Variables
```bash
# Set secrets
firebase functions:secrets:set APNS_AUTH_KEY_753L48DY45

# List secrets
firebase functions:secrets:list

# Grant secret access
firebase functions:secrets:access APNS_AUTH_KEY_753L48DY45
```

#### Memory and Timeout Settings
```javascript
// In function definitions
exports.generateAIResponse = functions
    .runWith({
        memory: '1GB',
        timeoutSeconds: 60,
        minInstances: 1  // Prevent cold starts
    })
    .https.onCall(/* ... */);
```

## Database Management

### Firestore Operations

#### Backup Procedures
```bash
# Export Firestore data
gcloud firestore export gs://growth-training-backups/$(date +%Y%m%d)

# Import Firestore data
gcloud firestore import gs://growth-training-backups/20250101
```

#### Index Management
```bash
# Deploy indexes
firebase deploy --only firestore:indexes

# List current indexes
firebase firestore:indexes
```

#### Security Rules
```bash
# Deploy security rules
firebase deploy --only firestore:rules

# Test rules locally
npm run test:rules
```

### Data Migration

#### User Data Migration
```javascript
// Migration script example
const admin = require('firebase-admin');
admin.initializeApp();

async function migrateUsers() {
    const users = await admin.firestore()
        .collection('users')
        .get();

    const batch = admin.firestore().batch();

    users.forEach(doc => {
        // Migration logic
        batch.update(doc.ref, {
            migrationVersion: 2,
            // New fields
        });
    });

    await batch.commit();
}
```

## Monitoring & Alerts

### Firebase Monitoring

#### Key Metrics
1. **Function Performance**
   - Execution time (P50, P95, P99)
   - Error rate
   - Cold start frequency

2. **Database Metrics**
   - Read/write operations
   - Storage usage
   - Index performance

3. **Authentication**
   - Daily active users
   - Sign-up rate
   - Authentication failures

#### Setting Up Alerts
```javascript
// Firebase Console → Monitoring → Create Alert
{
    metric: "function/execution_time",
    condition: "P95 > 3000ms",
    notification: "email/slack"
}
```

### Crashlytics

#### Integration Check
```swift
// In AppDelegate or App struct
FirebaseApp.configure()
Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
```

#### Custom Logging
```swift
// Log custom events
Crashlytics.crashlytics().log("Timer started: \(mode)")

// Set user properties
Crashlytics.crashlytics().setUserID(userId)
Crashlytics.crashlytics().setCustomValue(subscriptionTier, forKey: "subscription_tier")
```

### Performance Monitoring

#### App Performance
```swift
// Trace custom operations
let trace = Performance.startTrace(name: "timer_session")
// ... operation ...
trace?.stop()
```

#### Function Performance
```javascript
// Monitor function execution
const performance = require('firebase-functions/v2/performance');

exports.generateAIResponse = functions
    .runWith({
        monitoring: true  // Enable detailed monitoring
    })
    .https.onCall(/* ... */);
```

## Emergency Procedures

### Rollback Procedures

#### iOS App Rollback
1. Remove current version from sale
2. Expedite review for previous version
3. Notify users via push notification

#### Firebase Functions Rollback
```bash
# List function versions
gcloud functions list --project growth-training-app

# Rollback to previous version
firebase functions:delete FUNCTION_NAME
firebase deploy --only functions:FUNCTION_NAME
```

### Incident Response

#### Severity Levels
- **P1**: Complete service outage
- **P2**: Major feature broken
- **P3**: Minor feature issue
- **P4**: Cosmetic issue

#### Response Times
- **P1**: Immediate (within 1 hour)
- **P2**: Same day
- **P3**: Next business day
- **P4**: Next release

### Data Recovery

#### User Data Recovery
```bash
# Restore specific collection
gcloud firestore import gs://growth-training-backups/20250101 \
    --collection-ids=users
```

#### Transaction Recovery
```javascript
// Replay failed transactions
const failedTransactions = await getFailedTransactions();
for (const tx of failedTransactions) {
    await replayTransaction(tx);
}
```

## Security Operations

### API Key Rotation

#### Rotating APNS Keys
1. Generate new key in Apple Developer Portal
2. Update Secret Manager
3. Deploy functions with new key
4. Verify push notifications work
5. Remove old key

#### Rotating Firebase Service Account
```bash
# Create new key
gcloud iam service-accounts keys create key.json \
    --iam-account=SERVICE_ACCOUNT_EMAIL

# Update functions
firebase functions:config:set service_account="$(< key.json)"

# Deploy
firebase deploy --only functions
```

### Security Audits

#### Monthly Checklist
- [ ] Review Firebase Security Rules
- [ ] Check API key restrictions
- [ ] Audit admin access
- [ ] Review function logs for anomalies
- [ ] Update dependencies

## Maintenance Windows

### Scheduled Maintenance

#### Planning
1. Schedule during low-traffic hours (2-4 AM EST)
2. Notify users 48 hours in advance
3. Prepare rollback plan
4. Test in staging first

#### Communication
- In-app notification
- Email to affected users
- Status page update
- Social media announcement

### Database Maintenance

#### Index Optimization
```bash
# Analyze slow queries
firebase firestore:queries

# Create composite indexes
firebase deploy --only firestore:indexes
```

#### Data Cleanup
```javascript
// Remove old sessions
const cutoffDate = new Date();
cutoffDate.setDate(cutoffDate.getDate() - 90);

await admin.firestore()
    .collection('sessions')
    .where('createdAt', '<', cutoffDate)
    .delete();
```

## Scaling Procedures

### Vertical Scaling

#### Function Memory
```javascript
// Increase memory for heavy operations
exports.processVideo = functions
    .runWith({ memory: '2GB' })
    .https.onCall(/* ... */);
```

#### Database Limits
```javascript
// Implement pagination
const PAGE_SIZE = 100;
let lastDoc = null;

const query = firestore.collection('items')
    .orderBy('createdAt')
    .limit(PAGE_SIZE);

if (lastDoc) {
    query = query.startAfter(lastDoc);
}
```

### Horizontal Scaling

#### Function Instances
```javascript
// Set minimum instances
exports.criticalFunction = functions
    .runWith({ minInstances: 2 })
    .https.onCall(/* ... */);
```

#### Load Distribution
- Use Firebase's automatic scaling
- Implement caching where appropriate
- Consider CDN for static assets

---

## Related Documentation
- [Emergency Contacts](./emergency-contacts.md)
- [Monitoring Dashboard](./monitoring.md)
- [Security Protocols](./security.md)