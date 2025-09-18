# Firebase Configuration Issues to Fix

## 1. App Check Debug Token Registration (CRITICAL)

**Current Error:** App attestation failed (403 PERMISSION_DENIED)

**Debug Token to Register:** `2FD85673-2A8A-42F9-88D4-7A393DBD5872`

### Steps to Fix:
1. Go to Firebase Console: https://console.firebase.google.com/project/growth-70a85/appcheck/apps
2. Select your iOS app (com.growthlabs.growthmethod)
3. Click "Manage debug tokens"
4. Add new token: `2FD85673-2A8A-42F9-88D4-7A393DBD5872`
5. Save changes

This will fix:
- Firebase Functions calls (AI Coach, subscription validation)
- App Check validation errors
- Server-side receipt validation

## 2. Firestore Security Rules

**Current Error:** Missing or insufficient permissions

### Update Firestore Rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow authenticated users to read/write their sessions
    match /users/{userId}/sessions/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow authenticated users to read/write their routines
    match /users/{userId}/routines/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow authenticated users to read educational resources
    match /educational_resources/{document=**} {
      allow read: if request.auth != null;
    }
    
    // Allow authenticated users to read growth methods
    match /growth_methods/{document=**} {
      allow read: if request.auth != null;
    }
    
    // Allow reading legal documents
    match /legal_documents/{document=**} {
      allow read: if true;
    }
    
    // Allow analytics writes for authenticated users
    match /analytics/{document=**} {
      allow write: if request.auth != null;
      allow read: if request.auth != null && request.auth.uid == resource.data.userId;
    }
    
    // Allow webhook data for subscriptions
    match /webhook_events/{document=**} {
      allow read: if request.auth != null && request.auth.uid == resource.data.userId;
    }
  }
}
```

### Steps to Update:
1. Go to: https://console.firebase.google.com/project/growth-70a85/firestore/rules
2. Replace existing rules with above
3. Click "Publish"

## 3. Subscription Server Validation

**Current Issue:** Server validation returning INTERNAL error

### This is likely caused by:
1. App Check token not registered (fix #1 above)
2. Firebase Functions not configured properly

### Verify Firebase Functions:
```bash
cd functions
npm install
firebase deploy --only functions:validateSubscriptionReceipt
```

## 4. Test After Fixes

After implementing above fixes:
1. Restart the app
2. Test subscription purchase
3. Verify no more permission errors
4. Check that server validation works

## Summary of What's Working ✅

Despite the errors, the following IS working:
- ✅ All 3 subscription products loading correctly
- ✅ Purchase flow completing successfully
- ✅ Premium access being granted after purchase
- ✅ StoreKit 2 integration functioning properly
- ✅ Sandbox environment detection working

## What Needs Fixing ❌

1. App Check debug token registration (causes Functions to fail)
2. Firestore security rules (causes permission errors)
3. Server-side receipt validation (depends on #1)

Once these are fixed, the app will be fully ready for App Store submission.