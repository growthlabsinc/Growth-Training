# Creating Firebase Admin SDK Service Account Key

## Automated Method (if gcloud is properly authenticated)

```bash
# List service accounts
gcloud iam service-accounts list --project=growth-training-app

# Create key for Firebase Admin SDK service account
gcloud iam service-accounts keys create \
  ./keys/firebase-admin-sdk.json \
  --iam-account=firebase-adminsdk-xxxxx@growth-training-app.iam.gserviceaccount.com
```

## Manual Method (Recommended - via Firebase Console)

### Step 1: Access Firebase Service Accounts
1. Go to Firebase Console: https://console.firebase.google.com/project/growth-training-app/settings/serviceaccounts/adminsdk
2. You'll see the Firebase Admin SDK configuration page

### Step 2: Generate New Private Key
1. Click on "Generate new private key" button
2. A dialog will appear warning about keeping the key secure
3. Click "Generate key"
4. The JSON file will download to your computer

### Step 3: Move Key to Project
1. Rename the downloaded file to: `firebase-admin-sdk.json`
2. Move it to: `/Users/tradeflowj/Desktop/Dev/growth-training/keys/firebase-admin-sdk.json`

### Step 4: Verify Key Structure
The key file should have this structure:
```json
{
  "type": "service_account",
  "project_id": "growth-training-app",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@growth-training-app.iam.gserviceaccount.com",
  "client_id": "...",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "..."
}
```

## Using the Service Account Key

### For Local Development
```javascript
// In your Firebase Functions or Node.js code
const admin = require('firebase-admin');
const serviceAccount = require('../keys/firebase-admin-sdk.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'growth-training-app'
});
```

### Environment Variable Method
```bash
# Set environment variable
export GOOGLE_APPLICATION_CREDENTIALS="/Users/tradeflowj/Desktop/Dev/growth-training/keys/firebase-admin-sdk.json"

# Then in code, simply initialize without specifying credentials
admin.initializeApp();
```

### For Firebase Functions Deployment
Firebase Functions automatically use the default service account when deployed, so you don't need to include the key file in your deployment.

## Security Best Practices

1. **NEVER commit the key file to Git**
   - The `keys/` directory is already in `.gitignore`
   - Double-check before committing: `git status`

2. **Restrict Key Permissions**
   ```bash
   chmod 600 keys/firebase-admin-sdk.json
   ```

3. **Rotate Keys Regularly**
   - Delete old keys from Firebase Console
   - Generate new keys every 90 days

4. **Use Application Default Credentials in Production**
   - Don't deploy key files to production
   - Use workload identity or managed service accounts

## Troubleshooting

### Permission Denied Error
If you get permission errors when using the key:
1. Verify the service account has the necessary roles in IAM
2. Check that the key file is valid JSON
3. Ensure the project_id matches "growth-training-app"

### Key Not Found Error
1. Check the file path is correct
2. Verify the file exists: `ls -la keys/`
3. Check file permissions: `ls -la keys/firebase-admin-sdk.json`

## Alternative: Using Firebase CLI for Local Testing

For local development without a service account key:
```bash
# Login to Firebase
firebase login

# Use Firebase emulators for local development
firebase emulators:start
```

This avoids the need for service account keys during development.