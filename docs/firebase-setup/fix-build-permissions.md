# Fix Cloud Build Service Account Permissions

## The Issue
The functions deployment failed with:
> "Could not build the function due to a missing permission on the build service account"

This is caused by organization policies restricting the Cloud Build service account.

## Solution

### Step 1: Grant Necessary Permissions to Cloud Build Service Account

The Cloud Build service account needs specific roles. Run these commands or do it in the Console:

```bash
# Get the project number
PROJECT_NUMBER=997901246801

# The Cloud Build service account
BUILD_SERVICE_ACCOUNT="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"

# Grant necessary roles
gcloud projects add-iam-policy-binding growth-training-app \
  --member="serviceAccount:${BUILD_SERVICE_ACCOUNT}" \
  --role="roles/cloudfunctions.developer"

gcloud projects add-iam-policy-binding growth-training-app \
  --member="serviceAccount:${BUILD_SERVICE_ACCOUNT}" \
  --role="roles/artifactregistry.writer"

gcloud projects add-iam-policy-binding growth-training-app \
  --member="serviceAccount:${BUILD_SERVICE_ACCOUNT}" \
  --role="roles/storage.objectAdmin"
```

### Step 2: Via Google Cloud Console (Alternative)

1. Go to: https://console.cloud.google.com/iam-admin/iam?project=growth-training-app

2. Find the service account: `997901246801@cloudbuild.gserviceaccount.com`

3. Click the pencil icon to edit

4. Add these roles:
   - Cloud Functions Developer
   - Artifact Registry Writer
   - Storage Object Admin

5. Save changes

### Step 3: Check Organization Policies

1. Go to: https://console.cloud.google.com/iam-admin/orgpolicies?project=growth-training-app

2. Look for any policies that might restrict:
   - Service account usage
   - Cloud Build permissions
   - Storage access

3. If found, create exceptions for the `growth-training-app` project

### Step 4: Enable Required APIs (if not already)

```bash
gcloud services enable artifactregistry.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable cloudscheduler.googleapis.com
gcloud services enable eventarc.googleapis.com
gcloud services enable run.googleapis.com
```

### Step 5: Retry Deployment

After fixing permissions, retry:

```bash
firebase deploy --only functions --project growth-training-app
```

## If Still Failing

### Option 1: Deploy Specific Functions
Try deploying one function at a time:

```bash
# Deploy only the AI function
firebase deploy --only functions:generateAIResponse --project growth-training-app
```

### Option 2: Check Build Logs
View the detailed error at the provided URLs, for example:
https://console.cloud.google.com/cloud-build/builds;region=us-central1

### Option 3: Use Service Account Impersonation
If organization policies are too restrictive:

```bash
# Use a different service account with permissions
gcloud auth application-default login \
  --impersonate-service-account=firebase-adminsdk-xxxxx@growth-training-app.iam.gserviceaccount.com
```

## Organization Policy Override

If you're blocked by organization policies and have admin access:

1. **Identify the blocking policy**:
```bash
gcloud resource-manager org-policies list --project=growth-training-app
```

2. **Create an exception**:
Create `policy.yaml`:
```yaml
constraint: constraints/iam.allowServiceAccountCredentialLifetimeExtension
listPolicy:
  allowedValues:
    - projects/growth-training-app
```

Apply it:
```bash
gcloud resource-manager org-policies set-policy policy.yaml --project=growth-training-app
```

## Workaround: Deploy Without Building

If build permissions can't be fixed, you could:

1. Build locally and upload pre-built functions
2. Use Cloud Run directly instead of Cloud Functions
3. Request organization admin to create exceptions

## Contact Organization Admin

If you can't resolve this yourself, contact your Google Cloud Organization admin and request:

1. Exception for project `growth-training-app` from restrictive policies
2. Or grant your account Organization Policy Administrator role temporarily
3. Or have them run the deployment for you

The specific error suggests this is an organization-level restriction that may need admin intervention.