# Instructions to Add Legal Documents to Firestore

The app is trying to fetch legal documents but they don't exist in Firestore yet. Follow these steps to add them:

## Option 1: Using Firebase Console (Recommended)

1. Go to the Firebase Console: https://console.firebase.google.com/project/growth-70a85/firestore

2. Create a new collection called `legalDocuments` if it doesn't exist

3. Add three documents with the following IDs:
   - `privacy_policy`
   - `terms_of_use`
   - `disclaimer`

4. For each document, add these fields:
   - `title` (string): The document title
   - `version` (string): "1.0.0"
   - `lastUpdated` (timestamp): Current date
   - `content` (string): Copy the content from `scripts/legal-documents.json`

## Option 2: Using Firebase Admin SDK

1. Create a service account key:
   - Go to https://console.firebase.google.com/project/growth-70a85/settings/serviceaccounts/adminsdk
   - Click "Generate new private key"
   - Save the JSON file

2. Run the admin script:
   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS="path/to/service-account-key.json"
   node scripts/add-legal-documents-admin.js
   ```

## Option 3: Temporary Rule Change (Not Recommended for Production)

1. Temporarily update Firestore rules to allow write:
   ```
   match /legalDocuments/{documentId} {
     allow read: if true;
     allow write: if true; // TEMPORARY - REMOVE AFTER ADDING DOCS
   }
   ```

2. Run the client script:
   ```bash
   node scripts/add-legal-documents-client.js
   ```

3. **IMPORTANT**: Revert the rules immediately after adding documents

## Verification

After adding the documents, test in the app:
1. Go to Settings > Privacy Policy
2. Go to Settings > Terms of Use
3. Go to Settings > Medical Disclaimer

All documents should load without permission errors.