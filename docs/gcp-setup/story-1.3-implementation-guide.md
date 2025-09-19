# Story 1.3 Implementation Guide: Google Cloud Project Setup

## Overview
This guide provides step-by-step instructions for configuring Google Cloud Platform services for the Growth Training app, specifically enabling Vertex AI for the AI Coach feature.

## Prerequisites
- Firebase project: growth-training-app (completed in Story 1.1)
- Owner access: jon@growthlabs.coach
- Blaze billing plan active

## Console Access URLs
- Google Cloud Console: https://console.cloud.google.com
- Firebase Console: https://console.firebase.google.com/project/growth-training-app

---

## Task 1: Access Google Cloud Console

### Steps:
1. **Navigate to GCP Console**
   - Go to: https://console.cloud.google.com
   - Sign in with: jon@growthlabs.coach

2. **Verify Project Access**
   - Look for "growth-training-app" in the project selector (top bar)
   - If not visible, click the dropdown and search for it
   - Select the project

3. **Confirm Firebase Link**
   - The project should show as linked to Firebase
   - Project ID: growth-training-app
   - Project Number: 997901246801

### Verification:
✅ Project "growth-training-app" is selected
✅ You have Owner role (check IAM & Admin → IAM)

---

## Task 2: Link Firebase and GCP Projects

### Steps:
1. **Access Service Accounts**
   - Option A: From Firebase Console
     - Go to: https://console.firebase.google.com/project/growth-training-app/settings/serviceaccounts/adminsdk
     - Click "Manage service account permissions"
   - Option B: From GCP Console
     - Navigate to: IAM & Admin → Service accounts

2. **Verify Default Service Account**
   - Look for: firebase-adminsdk-[random]@growth-training-app.iam.gserviceaccount.com
   - This is automatically created with Firebase

3. **Note Service Account Details**
   ```
   Default Firebase Admin SDK Service Account:
   firebase-adminsdk-xxxxx@growth-training-app.iam.gserviceaccount.com
   ```

### Verification:
✅ Firebase service account exists
✅ Service account has Firebase Admin SDK role

---

## Task 3: Enable Vertex AI API

### Steps:
1. **Navigate to API Library**
   - In GCP Console, go to: APIs & Services → Library
   - Or direct URL: https://console.cloud.google.com/apis/library?project=growth-training-app

2. **Search and Enable**
   - Search for: "Vertex AI API"
   - Click on the Vertex AI API result
   - Click "ENABLE" button
   - Wait 1-2 minutes for activation

3. **Verify Activation**
   - Go to: APIs & Services → Enabled APIs
   - Confirm "Vertex AI API" appears in the list

### Verification:
✅ Vertex AI API shows as "Enabled"
✅ API appears in enabled APIs list

---

## Task 4: Configure IAM Permissions for Vertex AI

### Steps:
1. **Access IAM**
   - Navigate to: IAM & Admin → IAM
   - Or: https://console.cloud.google.com/iam-admin/iam?project=growth-training-app

2. **Find Firebase Functions Service Account**
   - Look for: [project-id]@appspot.gserviceaccount.com
   - Or: firebase-adminsdk-xxxxx@growth-training-app.iam.gserviceaccount.com

3. **Add Required Roles**
   - Click the pencil icon to edit
   - Add these roles:
     - `Vertex AI User`
     - `Service Account Token Creator` (if not present)
   - Click "Save"

4. **Document Service Account**
   ```yaml
   Firebase Functions Service Account:
   Email: growth-training-app@appspot.gserviceaccount.com
   Roles:
   - Vertex AI User
   - Service Account Token Creator
   - Cloud Functions Service Agent
   ```

### Verification:
✅ Service account has Vertex AI User role
✅ Service account has Token Creator role

---

## Task 5: Create AI-specific Service Account

### Steps:
1. **Navigate to Service Accounts**
   - Go to: IAM & Admin → Service Accounts
   - Click "CREATE SERVICE ACCOUNT"

2. **Create New Service Account**
   ```yaml
   Service Account Details:
   - Name: vertex-ai-integration
   - ID: vertex-ai-integration (auto-generated)
   - Description: Service account for Vertex AI integration in Cloud Functions
   ```

3. **Grant Roles**
   - Add roles:
     - `Vertex AI User`
     - `Cloud Functions Invoker`
   - Click "Continue"

4. **Complete Creation**
   - Skip optional user access grants
   - Click "Done"

5. **Optional: Generate Key for Local Testing**
   - Click on the new service account
   - Go to "Keys" tab
   - Add Key → Create new key → JSON
   - **IMPORTANT**: Store securely, never commit to repo

### Verification:
✅ Service account "vertex-ai-integration" created
✅ Roles assigned correctly

---

## Task 6: Configure Billing and Quotas

### Budget Alerts Setup:
1. **Access Billing**
   - Navigate to: Billing → Budgets & alerts
   - Or: https://console.cloud.google.com/billing/budgets

2. **Create Vertex AI Budget**
   ```yaml
   Budget Configuration:
   - Name: Vertex AI Usage
   - Projects: growth-training-app
   - Services: Vertex AI API
   - Budget amount: $500
   - Alert thresholds:
     - 10% ($50)
     - 20% ($100)
     - 100% ($500)
   - Email notifications: jon@growthlabs.coach
   ```

### Quota Check:
1. **Navigate to Quotas**
   - Go to: IAM & Admin → Quotas
   - Filter by: "Vertex AI"

2. **Note Default Quotas**
   ```yaml
   Vertex AI Quotas (defaults):
   - Requests per minute: 60
   - Prediction requests per minute: 10
   - Online predictions per model: 100
   ```

3. **Request Increases (if needed)**
   - Click on quota name
   - Click "EDIT QUOTAS"
   - Enter new limit and justification

### Verification:
✅ Budget alerts configured
✅ Quotas documented
✅ Blaze plan confirmed active

---

## Task 7: Enable Additional Required APIs

### APIs to Enable:
1. **Cloud Resource Manager API**
   - Search in API Library
   - Click Enable

2. **Cloud Billing API**
   - Search in API Library
   - Click Enable

3. **Identity and Access Management (IAM) API**
   - Search in API Library
   - Click Enable

4. **Service Usage API**
   - Search in API Library
   - Click Enable

### Quick Enable Links:
```bash
# Or use gcloud CLI if available:
gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable cloudbilling.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable serviceusage.googleapis.com
```

### Verification:
✅ All 4 additional APIs enabled
✅ APIs appear in Enabled APIs list

---

## Task 8: Verify and Document Configuration

### Test Vertex AI Access:
1. **Open Cloud Shell**
   - Click the terminal icon in top right of GCP Console
   - Or: https://shell.cloud.google.com

2. **Run Test Command**
   ```bash
   # Set project
   gcloud config set project growth-training-app

   # List AI models (should return empty list or models)
   gcloud ai models list --region=us-central1

   # If error, check API is enabled
   gcloud services list --enabled | grep aiplatform
   ```

3. **Expected Output**
   - Should either show empty list or available models
   - No permission errors

### Create Documentation File:
Create `/docs/gcp-config.md` with complete configuration details (see next section).

---

## Configuration Documentation

Create the following file at `/docs/gcp-config.md`:

```markdown
# Google Cloud Platform Configuration

## Project Information
- **Project ID**: growth-training-app
- **Project Number**: 997901246801
- **Region**: us-central1
- **Billing**: Blaze plan (shared with Firebase)

## Enabled APIs
1. Vertex AI API
2. Cloud Resource Manager API
3. Cloud Billing API
4. Identity and Access Management (IAM) API
5. Service Usage API
6. Firebase-related APIs (auto-enabled):
   - Cloud Firestore API
   - Firebase Rules API
   - Cloud Storage API
   - Firebase Installations API

## Service Accounts

### Default Firebase Admin SDK
- **Email**: firebase-adminsdk-[random]@growth-training-app.iam.gserviceaccount.com
- **Roles**:
  - Firebase Admin SDK Administrator Service Agent
  - Vertex AI User
  - Service Account Token Creator

### App Engine Default
- **Email**: growth-training-app@appspot.gserviceaccount.com
- **Roles**:
  - Cloud Functions Service Agent
  - Vertex AI User

### Vertex AI Integration (Custom)
- **Email**: vertex-ai-integration@growth-training-app.iam.gserviceaccount.com
- **Roles**:
  - Vertex AI User
  - Cloud Functions Invoker

## Billing Configuration
- **Plan**: Blaze (Pay as you go)
- **Budget Alerts**:
  - Vertex AI: $50, $100, $500
  - Overall project: $100, $500, $1000 (from Story 1.1)

## Vertex AI Quotas
- **Requests per minute**: 60 (default)
- **Prediction requests per minute**: 10 (default)
- **Online predictions per model**: 100 (default)
- **Note**: Request increases before production launch if needed

## Security Configuration
- **Audit Logging**: Enabled for data access
- **Least Privilege**: Service accounts have minimal required permissions
- **Key Management**: No service account keys in repository

## Testing Commands
```bash
# Verify Vertex AI access
gcloud ai models list --region=us-central1

# Check enabled APIs
gcloud services list --enabled

# View service accounts
gcloud iam service-accounts list
```

## Next Steps
- Story 1.4: Configure APNS certificates
- Story 1.5: Generate environment configurations
- Deploy Firebase Functions with Vertex AI integration
```

---

## Completion Checklist

- [ ] GCP Console access verified
- [ ] Firebase-GCP link confirmed
- [ ] Vertex AI API enabled
- [ ] IAM permissions configured
- [ ] Custom service account created
- [ ] Billing alerts set up
- [ ] Additional APIs enabled
- [ ] Configuration tested via Cloud Shell
- [ ] Documentation created at `/docs/gcp-config.md`

## Important Notes

1. **Security**: Never commit service account keys to the repository
2. **Costs**: Monitor Vertex AI usage closely - costs can accumulate
3. **Quotas**: Default quotas may need increases for production
4. **Region**: us-central1 is used for all services
5. **Testing**: Always test in Cloud Shell before Functions deployment