# Security Setup and Credential Management

## Overview
This document outlines the secure credential management system for the Growth Training app. All sensitive credentials have been removed from the codebase and must now be configured through environment variables or Firebase secrets.

## Required Credentials

### 1. Firebase API Keys
Firebase API keys are now managed through environment variables. Never commit actual API keys to the repository.

**Setup:**
1. Copy `.env.example` to `.env` in the project root
2. Fill in your Firebase credentials
3. Ensure `.env` is in `.gitignore` (already configured)

### 2. APNS Authentication Keys
Apple Push Notification Service keys are required for Live Activities.

**Setup for Development:**
```bash
# Store APNS key securely
mkdir -p keys
cp /path/to/your/AuthKey_XXXXX.p8 keys/
chmod 600 keys/*.p8

# Set environment variables
export APNS_KEY_PATH=./keys/AuthKey_XXXXX.p8
export APNS_KEY_ID=YOUR_KEY_ID
export APNS_TEAM_ID=62T6J77P6R
```

**Setup for Production (Firebase Functions):**
```bash
# Set secrets using Firebase CLI
firebase functions:secrets:set APNS_TEAM_ID
firebase functions:secrets:set APNS_KEY_ID
firebase functions:secrets:set APNS_AUTH_KEY < keys/AuthKey_XXXXX.p8
```

### 3. Service Account Keys
For Firebase Admin SDK operations, service account keys are needed for local development only.

**Setup:**
1. Download service account key from Firebase Console
2. Save as `service-account-key.json` in project root
3. Set environment variable: `export GOOGLE_APPLICATION_CREDENTIALS=./service-account-key.json`
4. Never commit this file (already in `.gitignore`)

## Environment Configuration Files

### Root Directory
- `.env.example` - Template for environment variables (safe to commit)
- `.env` - Actual environment variables (never commit)

### Functions Directory
- `functions/.env.example` - Template for Firebase Functions (safe to commit)
- `functions/.env.local` - Local development variables (never commit)
- `functions/.env.production` - Production variables (never commit)

## Security Checklist

### Before Every Commit
- [ ] No hardcoded API keys in code
- [ ] No hardcoded private keys in code
- [ ] No `.p8` files in repository
- [ ] No `.env` files (except `.env.example`)
- [ ] No service account JSON files

### Initial Setup
- [ ] Configure Firebase API keys in `.env`
- [ ] Set up APNS keys as Firebase secrets
- [ ] Configure service account for local development
- [ ] Verify `.gitignore` includes all sensitive file patterns

### Production Deployment
- [ ] All secrets configured in Firebase Functions
- [ ] API keys restricted in Firebase Console
- [ ] App Check enabled for all APIs
- [ ] Security rules reviewed and restrictive

## Firebase Console Configuration

### API Key Restrictions
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Project Settings → General → Web API Key
3. Click "Edit API key" in Google Cloud Console
4. Add Application restrictions:
   - iOS apps: `com.growthlabs.growthmethod`
5. Add API restrictions:
   - Only enable required Firebase services

### App Check Setup
1. Firebase Console → App Check
2. Register your app with App Check
3. Choose attestation provider (DeviceCheck for iOS)
4. Enable enforcement for all Firebase services

## Scripts Usage

All scripts now use centralized configuration:

```bash
# Scripts automatically load from firebase-config.js
cd scripts
node add-legal-documents-client.js

# APNS scripts use environment variables
export APNS_KEY_PATH=./keys/AuthKey_DQ46FN4PQU.p8
./update-apns-key-DQ46FN4PQU.sh
```

## Troubleshooting

### Missing Credentials Error
If you see "Firebase API key not set", ensure:
1. `.env` file exists with correct values
2. Environment variables are loaded
3. Running from correct directory

### APNS Key Not Found
If APNS key file not found:
1. Check `APNS_KEY_PATH` environment variable
2. Ensure `.p8` file exists in specified location
3. Verify file permissions (should be 600)

### Firebase Functions Secrets
List configured secrets:
```bash
firebase functions:secrets:access
```

Update a secret:
```bash
firebase functions:secrets:set SECRET_NAME
```

## Security Best Practices

1. **Never commit credentials** - Use environment variables
2. **Rotate keys regularly** - Especially after any potential exposure
3. **Use least privilege** - Restrict API keys to minimum required permissions
4. **Monitor usage** - Set up alerts for unusual API activity
5. **Secure local files** - Use proper file permissions for sensitive files
6. **Use secrets management** - Firebase secrets for production, env files for development

## Emergency Response

If credentials are exposed:
1. **Immediately revoke** compromised credentials
2. **Generate new** credentials
3. **Update** all environments with new credentials
4. **Audit** logs for unauthorized access
5. **Notify** team and users if necessary

## Support

For security concerns or questions:
- Review Firebase Security documentation
- Check Apple Developer documentation for APNS
- File issues in private repository (not public)