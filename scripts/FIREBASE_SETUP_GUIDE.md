# Firebase Service Account Setup Guide

## Prerequisites
- Access to Firebase Console for the Growth project
- Node.js installed (for running the upload script)

## Steps to Get Service Account Key

1. **Open Firebase Console**
   - Go to https://console.firebase.google.com
   - Select your Growth project

2. **Navigate to Service Accounts**
   - Click on the gear icon (⚙️) next to "Project Overview"
   - Select "Project settings"
   - Click on the "Service accounts" tab

3. **Generate Private Key**
   - Click "Generate new private key" button
   - Confirm by clicking "Generate key"
   - The JSON file will download automatically

4. **Save the Key File**
   - Rename the downloaded file to `service-account-key.json`
   - Move it to the `/scripts` directory:
   ```bash
   mv ~/Downloads/*.json /Users/tradeflowj/Desktop/Dev/growth-training/scripts/service-account-key.json
   ```

5. **Verify File Placement**
   ```bash
   ls -la /Users/tradeflowj/Desktop/Dev/growth-training/scripts/service-account-key.json
   ```

## Install Dependencies

```bash
cd /Users/tradeflowj/Desktop/Dev/growth-training/scripts
npm install firebase-admin
```

## Upload PE Exercises to Firebase

```bash
# Upload all 33 PE exercises
node upload_pe_exercises_to_firebase.js upload

# Verify the upload
node upload_pe_exercises_to_firebase.js verify

# If needed, delete PE exercises
node upload_pe_exercises_to_firebase.js delete
```

## Security Note
⚠️ **IMPORTANT**: Never commit the `service-account-key.json` file to Git. It's already in `.gitignore` to prevent accidental commits.