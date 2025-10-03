# HIPAA/GDPR Compliance Configuration

**Status:** Draft - To be completed in Story 10.5

## Overview

This document outlines the configuration settings and processes implemented in the Growth app's backend infrastructure (Google Cloud Platform and Firebase) to support compliance with healthcare privacy regulations (HIPAA) and data protection regulations (GDPR). 

## HIPAA Compliance Configuration

### Business Associate Agreement (BAA)

Google Cloud BAA **Status:** _Initiated_

- Signed via Google Cloud Console > IAM & Admin > Legal Agreements on 2025-05-10
- Covers the following Firebase services used by Growth MVP:
  - Firebase Authentication
  - Cloud Firestore
  - Cloud Functions (triggered background tasks)
  - Cloud Storage (user-uploaded images)
- PDF copy stored in internal shared drive (`/Compliance/BAA/Google-BAA-Growth-2025.pdf`).

### Covered Firebase/GCP Services

| Service | HIPAA Eligible | Included in BAA |
|---------|---------------|-----------------|
| Firebase Authentication | ✅ | ✅ |
| Cloud Firestore | ✅ | ✅ |
| Cloud Functions | ✅ | ✅ |
| Cloud Storage | ✅ | ✅ |
| Firebase Analytics | ⚠️ | Not used for PHI; event parameters are de-identified |
| Firebase Crashlytics | ✅ | Covered but only crash traces (no PHI) |

### PHI Data Classification

| Collection / Data | PHI | Notes |
|-------------------|-----|-------|
| `users` – profile (name, email) | ✅ | Personal identifiers |
| `sessionLogs` – mindfulness logs | ✅ | Can reveal mental health data |
| `progressionEvents` | ✅ | Indicates treatment adherence |
| Push tokens | ❌ | Device identifiers only |

### Access Controls and Authentication

• IAM roles follow least-privilege principle.

| Role | Members | Permissions |
|------|---------|-------------|
| `growth-read-only` | Data analyst svc acct | `datastore.databases.get`, `firestore.documents.get` |
| `growth-operations` | Backend Cloud Function svc acct | CRUD on PHI collections |
| `growth-admin` | CTO account | Full project owner |

• Multi-factor authentication enforced on all human Google accounts.

• Firebase Authentication only accessible over TLS 1.2+.

### Audit Logging and Monitoring

• Cloud Audit Logs enabled for **Admin Read**, **Data Write**, **Data Read**.
• Logs routed to BigQuery sink `growth_auditlog_eu` (EU region) with 365-day retention.
• Alerting:
  - Slack channel `#sec-audit` when IAM policy changes.
  - PagerDuty alert on high-severity log entries (detects IAM permission denied, auth deletion, etc.).

## GDPR Compliance Configuration

### Data Processing Agreements

DPA accepted in Google Cloud Console (2025-05-10). Covers all Google Cloud services. ID: `DPA-EU-2025-05`.

### Data Storage Location and Residency

• Primary Firestore location: `europe-west3` (Frankfurt) to keep EU resident data in-region.
• Cloud Functions set to `europe-west3`.
• Cloud Storage bucket `growth-eu-uploads` in `eu` multi-region.

**FIREBASE_REGION** environment variable set to `europe-west3` for client.

### User Consent Management

• Explicit opt-in obtained during onboarding screen (Story 2.3). Consent stored in `users/{uid}/consent` document.
• `LegalDocumentService` verifies latest versions (Story 10.3).

• Analytics collection disabled (`Analytics.setAnalyticsCollectionEnabled(false)`) until user opts in.

### Data Subject Rights Implementation

| Right | Implementation |
|-------|----------------|
| Access | Export via Cloud Function `exportUserData` (generates JSON, emails link). |
| Rectification | User can update profile in Settings > Account. |
| Erasure | User triggers deletion (Story 10.2) via `UserDataDeletionService`. |
| Portability | Same export JSON downloadable. |
| Restrict Processing | Toggle analytics switch in Settings. |

## Technical Implementation Details

### Firebase Security Rules

• Rules enforce `request.auth != null` for PHI collections.
• Users can only read/write their own documents (`resource.data.userId == request.auth.uid`).

### IAM Role Configuration

See Access Controls section.

### Encryption Configuration

• Google-managed encryption at rest enabled by default.
• Customer-managed encryption keys (CMEK) not required for MVP; evaluate post-launch.

### Audit Logging Setup

See Audit Logging section.

## Compliance Maintenance Procedures

### Regular Review Process

Quarterly security review checklist stored in Notion workspace.

### Incident Response Plan

Refer to `docs/incident-response.md` (to be drafted) – includes 72-hour breach notification SLA.

### Compliance Testing Procedures

• Annual penetration test by accredited vendor.
• Automated security rules unit tests run in CI.

## References

- [Google Cloud HIPAA Compliance](https://cloud.google.com/security/compliance/hipaa)
- [Google Cloud GDPR Resource Center](https://cloud.google.com/security/gdpr)
- [Firebase Security Documentation](https://firebase.google.com/docs/rules)
- Story 10.1: Data Encryption Implementation
- Story 10.2: User Data Deletion Request Handling
- Story 10.3: Legal Documentation
- Story 10.4: App Store Compliance Review

## Change Log

| Date       | Version | Description                       | Author |
|------------|---------|-----------------------------------|--------|
| YYYY-MM-DD | 0.1     | Initial skeleton document created | -      | 