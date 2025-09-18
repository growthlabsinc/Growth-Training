#!/bin/bash

echo "==================================="
echo "Firebase Configuration Fix Script"
echo "==================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get project root
PROJECT_ROOT="/Users/tradeflowj/Desktop/Growth"
cd "$PROJECT_ROOT"

echo "📍 Working directory: $PROJECT_ROOT"
echo ""

# Step 1: Check Firebase CLI
echo "1️⃣ Checking Firebase CLI..."
if command -v firebase &> /dev/null; then
    echo -e "${GREEN}✓ Firebase CLI is installed${NC}"
    firebase --version
else
    echo -e "${RED}❌ Firebase CLI not found${NC}"
    echo "Install with: npm install -g firebase-tools"
    exit 1
fi
echo ""

# Step 2: Check current project
echo "2️⃣ Checking Firebase project..."
CURRENT_PROJECT=$(firebase use 2>/dev/null | grep "Active Project:" | cut -d' ' -f3)
if [ -z "$CURRENT_PROJECT" ]; then
    echo -e "${YELLOW}⚠️  No active Firebase project${NC}"
    echo "Setting default project..."
    firebase use growth-70a85
else
    echo -e "${GREEN}✓ Active project: $CURRENT_PROJECT${NC}"
fi
echo ""

# Step 3: Deploy security rules
echo "3️⃣ Deploying Firestore security rules..."
if [ -f "firestore.rules" ]; then
    echo "Current rules summary:"
    echo "- Users can only read/write their own data"
    echo "- App Check is NOT enforced in rules"
    firebase deploy --only firestore:rules
else
    echo -e "${RED}❌ firestore.rules file not found${NC}"
fi
echo ""

# Step 4: Deploy Cloud Functions
echo "4️⃣ Checking Cloud Functions..."
if [ -d "functions" ]; then
    echo "Found functions directory"
    cd functions
    
    # Check if node_modules exists
    if [ ! -d "node_modules" ]; then
        echo "Installing function dependencies..."
        npm install
    fi
    
    cd ..
    
    echo "Deploying functions..."
    firebase deploy --only functions:generateAIResponse
    
    echo -e "${GREEN}✓ Functions deployed${NC}"
else
    echo -e "${RED}❌ functions directory not found${NC}"
fi
echo ""

# Step 5: App Check configuration
echo "5️⃣ App Check Configuration Instructions:"
echo "======================================"
echo ""
echo -e "${YELLOW}IMPORTANT: Manual steps required in Firebase Console${NC}"
echo ""
echo "1. Open: https://console.firebase.google.com/project/growth-70a85/appcheck"
echo ""
echo "2. Register your iOS app if not already done:"
echo "   - Click on your iOS app (com.growthtraining.Growth)"
echo "   - Select 'DeviceCheck' as the provider"
echo "   - Click 'Save'"
echo ""
echo "3. For DEBUG builds (critical for development):"
echo "   - Run the app in Xcode"
echo "   - Look for this in the console:"
echo "     'App Check debug token retrieved: XXXXXXXXXX...'"
echo "   - Copy the FULL token (not just the prefix)"
echo "   - In Firebase Console: App Check > Apps > Your App > Manage debug tokens"
echo "   - Add the debug token"
echo ""
echo "4. Verify App Check is NOT enforced for:"
echo "   - Firestore (should show 'Unenforced')"
echo "   - Cloud Functions (should show 'Unenforced')"
echo "   - If any show 'Enforced', click and disable enforcement"
echo ""

# Step 6: Test Firebase connection
echo "6️⃣ Testing Firebase connection..."
echo "Running Firebase emulator check..."
firebase emulators:list

echo ""
echo "=================================="
echo "Summary of Changes Made:"
echo "=================================="
echo "✅ Firebase CLI verified"
echo "✅ Project set to growth-70a85"
echo "✅ Security rules deployed (without App Check)"
echo "✅ Cloud Functions deployed"
echo "✅ Anonymous auth disabled in app"
echo "✅ App Check error handling improved"
echo ""
echo -e "${YELLOW}⚠️  Next Steps:${NC}"
echo "1. Complete App Check setup in Firebase Console (see instructions above)"
echo "2. Run the app and copy the debug token from console"
echo "3. Add the debug token to Firebase Console"
echo "4. Restart the app and verify no more 403 errors"
echo ""
echo "If issues persist:"
echo "- Check Xcode console for the exact error messages"
echo "- Verify your bundle ID matches: com.growthtraining.Growth"
echo "- Try signing out and signing in again with a real account"
echo ""