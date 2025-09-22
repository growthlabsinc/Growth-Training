# Firebase Authentication Solutions

## Error: Service Account Key Creation Restricted

Your organization has policies preventing service account key creation. This is a security measure set at the Google Cloud Organization level.

## Solutions (In Order of Preference)

### 1. Use Application Default Credentials (ADC)
If you're authenticated with gcloud CLI:
```bash
# Install Google Cloud SDK if not already installed
brew install --cask google-cloud-sdk

# Authenticate with your Google account
gcloud auth login

# Set the project
gcloud config set project growth-training-app

# Set application default credentials
gcloud auth application-default login
```

Then modify the upload script to use ADC instead of service account key.

### 2. Request Policy Exception
Contact your Google Cloud Organization administrator to:
- Grant you the `iam.serviceAccountKeyAdmin` role
- Or create an exception for the growth-training-app project
- Or temporarily disable the constraint `iam.disableServiceAccountKeyCreation`

### 3. Use Existing Service Account Key
Check if there's an existing key:
- Ask team members if they have a service account key
- Check your project's secure storage/vault
- Look in CI/CD configuration for existing keys

### 4. Use Firebase Admin SDK with OAuth
Authenticate using your personal Google account OAuth:
```bash
# This requires you to be a project owner/editor
firebase login
```

### 5. Use Firebase REST API
Upload directly using Firebase REST API with your Firebase Auth token:
- Authenticate in Firebase Console
- Use browser developer tools to get auth token
- Make direct REST API calls to Firestore

## Organization Policy Details

The restriction is likely due to:
- **Policy**: `constraints/iam.disableServiceAccountKeyCreation`
- **Scope**: Organization or Project level
- **Purpose**: Prevent key sprawl and security risks

## To Check Your Permissions

```bash
# Check your IAM roles
gcloud projects get-iam-policy growth-training-app \
  --flatten="bindings[].members" \
  --format="table(bindings.role)" \
  --filter="bindings.members:YOUR_EMAIL"

# Check organization policies
gcloud resource-manager org-policies list --project=growth-training-app
```

## Recommended Action

1. **First**, try using Application Default Credentials (Solution #1)
2. **If that fails**, contact your organization admin with this message:

---

**Subject: Service Account Key Required for Firebase Development**

Hi [Admin],

I need to create a service account key for the Firebase project `growth-training-app` to upload content to Firestore.

The organization policy `constraints/iam.disableServiceAccountKeyCreation` is currently blocking this.

Could you please either:
1. Grant me the `iam.serviceAccountKeyAdmin` role for this project
2. Create a service account key for me
3. Temporarily disable the constraint for this specific project

This is needed for deploying PE exercise content to our production Firebase database.

Thanks,
[Your Name]

---

## Alternative: Use Firebase CLI

If you have Firebase CLI access, you can potentially upload using:
```bash
# Login to Firebase
firebase login

# Use Firebase CLI to interact with Firestore
firebase firestore:delete --all-collections
firebase firestore:import ./data
```

However, this requires the data to be in a specific format.