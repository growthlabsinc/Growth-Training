#!/bin/bash

# Script to fix Firebase permissions and App Check issues

echo "🔥 Fixing Firebase Configuration Issues"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${RED}ISSUE 1: App Check Token Not Registered${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${YELLOW}Your debug token needs to be registered:${NC}"
echo -e "${CYAN}Token: CA9B6ADA-9EA6-45A5-A800-F2E973DF1C7C${NC}"
echo ""
echo "Steps to register:"
echo "1. Go to Firebase Console > App Check"
echo "2. Click on your iOS app"
echo "3. Click 'Manage debug tokens'"
echo "4. Add the token with a name like 'Development Simulator'"
echo ""

read -p "Do you want to open App Check settings now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    open "https://console.firebase.google.com/project/growth-training-app/appcheck/apps"
    echo -e "${GREEN}✅ App Check page opened${NC}"
    echo "Please add the debug token before continuing..."
    read -p "Press Enter when you've added the token..."
fi

echo ""
echo -e "${RED}ISSUE 2: Firestore Security Rules${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "The app is getting 'Missing or insufficient permissions' errors."
echo "This means Firestore security rules need to be updated."
echo ""
echo -e "${YELLOW}Current error locations:${NC}"
echo "• growth_exercises collection - Users can't read exercises"
echo "• Firebase Functions - UNAUTHENTICATED errors"
echo ""

cat > /tmp/firestore.rules << 'EOF'
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Allow authenticated users to read/write their own user document
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // Allow all authenticated users to read growth_exercises
    match /growth_exercises/{document=**} {
      allow read: if request.auth != null;
      allow write: if false; // Only admin can write
    }

    // Allow authenticated users to read/write their session logs
    match /sessionLogs/{document} {
      allow read: if request.auth != null && request.auth.uid == resource.data.userId;
      allow create: if request.auth != null && request.auth.uid == request.resource.data.userId;
      allow update: if request.auth != null && request.auth.uid == resource.data.userId;
      allow delete: if request.auth != null && request.auth.uid == resource.data.userId;
    }

    // Allow authenticated users to read educational resources
    match /educationalResources/{document=**} {
      allow read: if request.auth != null;
      allow write: if false; // Only admin can write
    }

    // Allow authenticated users to read/write their gains entries
    match /gains_entries/{userId}/entries/{entry} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // AI Coach knowledge base - read only for authenticated users
    match /ai_coach_knowledge/{document=**} {
      allow read: if request.auth != null;
      allow write: if false; // Only admin can write
    }

    // AI Coach conversations
    match /ai_coach_conversations/{userId}/messages/{message} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // Routines collection
    match /routines/{document=**} {
      allow read: if request.auth != null;
      allow write: if false; // Only admin can write initially
    }

    // User routines
    match /users/{userId}/routines/{routine} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // Legal documents
    match /legal_documents/{document} {
      allow read: if true; // Public access for legal docs
      allow write: if false;
    }

    // Device tokens for push notifications
    match /deviceTokens/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // Goals collection (if needed later)
    match /goals/{userId}/userGoals/{goal} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
EOF

echo -e "${GREEN}Generated Firestore rules saved to /tmp/firestore.rules${NC}"
echo ""
echo "To apply these rules:"
echo "1. Go to Firebase Console > Firestore Database > Rules"
echo "2. Copy and paste the rules from /tmp/firestore.rules"
echo "3. Click 'Publish'"
echo ""

read -p "Do you want to open Firestore Rules page now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    open "https://console.firebase.google.com/project/growth-training-app/firestore/rules"
    echo -e "${GREEN}✅ Firestore Rules page opened${NC}"
    echo ""
    echo "Copy these rules and paste them in the console:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    cat /tmp/firestore.rules
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
fi

echo ""
echo -e "${YELLOW}ISSUE 3: Firebase Functions Authentication${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Firebase Functions are returning UNAUTHENTICATED errors."
echo "This is likely due to App Check not being properly configured."
echo ""
echo "After registering the App Check token (Issue 1), this should be resolved."
echo ""

echo -e "${BLUE}📝 Summary of Actions:${NC}"
echo ""
echo "1. ✅ Register App Check debug token: CA9B6ADA-9EA6-45A5-A800-F2E973DF1C7C"
echo "2. ✅ Update Firestore security rules to allow authenticated access"
echo "3. ✅ Restart the app after making these changes"
echo ""

echo -e "${GREEN}Additional Debugging Commands:${NC}"
echo ""
echo "To verify Firebase connection:"
echo "  firebase login"
echo "  firebase use growth-training-app"
echo "  firebase firestore:indexes"
echo ""
echo "To deploy rules from command line (if you have Firebase CLI):"
echo "  cp /tmp/firestore.rules firestore.rules"
echo "  firebase deploy --only firestore:rules"
echo ""

echo "✨ Once these issues are fixed, the app should work properly!"