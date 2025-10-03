# Fix: Service Account Key Creation Restricted

## The Problem
Your organization (growthlabs.coach) has a security policy that prevents creating downloadable service account keys. This is the error:
> "Key creation is not allowed on this service account. Please check if service account key creation is restricted by organization policies."

## Solutions (In Order of Preference)

### Solution 1: Use Application Default Credentials (Recommended)
**No key file needed!** Use your personal Google account for local development.

```bash
# Step 1: Login with your personal Google account
gcloud auth application-default login

# Step 2: Set quota project
gcloud auth application-default set-quota-project growth-training-app

# Step 3: In your Firebase Functions code, initialize without a key:
```

```javascript
// functions/index.js
const admin = require('firebase-admin');

// No service account key needed!
admin.initializeApp({
  projectId: 'growth-training-app'
});

// Your Firestore, Auth, etc. will work automatically
const db = admin.firestore();
```

### Solution 2: Use Firebase CLI Authentication
The Firebase CLI can provide authentication for local development:

```bash
# Ensure you're logged in to Firebase
firebase login

# List your projects to verify access
firebase projects:list

# Use the project
firebase use growth-training-app

# When running functions locally, use:
firebase functions:shell
# or
firebase serve --only functions
```

### Solution 3: Create Service Account WITHOUT Downloading Key
Use the service account without creating a downloadable key by using Workload Identity Federation:

```bash
# For local development on Mac/Linux:
export GOOGLE_APPLICATION_CREDENTIALS=""
export GOOGLE_CLOUD_PROJECT="growth-training-app"

# Then use gcloud to authenticate
gcloud auth application-default login --project=growth-training-app
```

### Solution 4: Request Policy Exception (If Absolutely Necessary)
If you're the organization admin or can contact them:

1. **Go to Google Cloud Console**:
   ```
   https://console.cloud.google.com/iam-admin/orgpolicies
   ```

2. **Find the Policy**:
   - Search for: `iam.disableServiceAccountKeyCreation`
   - Click on it

3. **Create an Exception**:
   - Click "Manage Policy"
   - Add an exception for project: `growth-training-app`
   - Or disable the constraint entirely (not recommended)

4. **Via gcloud CLI** (if you have org admin permissions):
   ```bash
   # Get your organization ID
   gcloud organizations list

   # Create exception for this project
   gcloud resource-manager org-policies set-policy \
     --project=growth-training-app policy.yaml
   ```

   Create `policy.yaml`:
   ```yaml
   constraint: iam.disableServiceAccountKeyCreation
   listPolicy:
     allowedValues:
       - projects/growth-training-app
   ```

### Solution 5: Use Impersonation (Advanced)
If you have the right permissions, you can impersonate the service account:

```bash
# Grant yourself impersonation permission
gcloud iam service-accounts add-iam-policy-binding \
  firebase-adminsdk-xxxxx@growth-training-app.iam.gserviceaccount.com \
  --member="user:jon@growthlabs.coach" \
  --role="roles/iam.serviceAccountTokenCreator"

# Then in your code:
gcloud auth application-default login \
  --impersonate-service-account=firebase-adminsdk-xxxxx@growth-training-app.iam.gserviceaccount.com
```

## Immediate Workaround for Development

### For Firebase Functions Development:
```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Check if running locally
if (process.env.FUNCTIONS_EMULATOR || process.env.NODE_ENV === 'development') {
  // Local development - use application default credentials
  admin.initializeApp({
    projectId: 'growth-training-app',
  });
} else {
  // Production - uses default service account automatically
  admin.initializeApp();
}

exports.yourFunction = functions.https.onRequest((req, res) => {
  // Your function code
});
```

### For Running Functions Locally:
```bash
# Option 1: Use Firebase serve
firebase serve --only functions --project growth-training-app

# Option 2: Use Firebase shell
firebase functions:shell

# Option 3: Use npm script with environment variables
NODE_ENV=development npm run start
```

## Testing Your Setup

### Test Script
Create `test-auth.js`:
```javascript
const admin = require('firebase-admin');

// Initialize without service account key
admin.initializeApp({
  projectId: 'growth-training-app'
});

// Test Firestore access
async function testFirestore() {
  try {
    const db = admin.firestore();
    const test = await db.collection('test').add({
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      message: 'Auth test successful'
    });
    console.log('✅ Firestore write successful:', test.id);
  } catch (error) {
    console.error('❌ Firestore error:', error.message);
  }
}

testFirestore();
```

Run it:
```bash
node test-auth.js
```

## Why This Restriction Exists
- **Security**: Downloadable keys can be leaked, stolen, or mishandled
- **Best Practice**: Google recommends using Workload Identity instead of keys
- **Compliance**: Many organizations require this for SOC2, ISO27001, etc.

## Production Deployment (No Changes Needed)
When you deploy to Firebase, everything works automatically:
```bash
firebase deploy --only functions
```
The deployed functions use the default service account with no key needed.

## Next Steps
1. Use `gcloud auth application-default login` for local development
2. Update your function initialization code as shown above
3. Test locally with `firebase serve --only functions`
4. Deploy normally with `firebase deploy`

This approach is actually MORE SECURE than using downloaded keys!