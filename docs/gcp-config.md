# Google Cloud Platform Configuration

## Project Information
- **Project ID**: growth-training-app
- **Project Number**: 997901246801
- **Region**: us-central1
- **Billing**: Blaze plan (shared with Firebase)
- **Console URL**: https://console.cloud.google.com/home/dashboard?project=growth-training-app

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