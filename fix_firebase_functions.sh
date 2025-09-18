#!/bin/bash

echo "🔧 Fixing Firebase Functions Errors"
echo "==================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "firebase.json" ]; then
    echo -e "${RED}❌ Not in Firebase project root. Please run from project root.${NC}"
    exit 1
fi

echo "📋 Summary of fixes being applied:"
echo "1. ✅ Fixed appStoreConfig.js - Replaced deprecated functions.config() with Secret Manager"
echo "2. ✅ Fixed appStoreNotifications.js - Updated to Firebase Functions v2 syntax"
echo "3. ✅ Fixed updateLiveActivitySimplified.js - Improved APNs token generation"
echo ""

# Deploy functions
echo -e "${YELLOW}🚀 Deploying Firebase Functions...${NC}"
echo ""

# First, let's check if secrets are configured
echo "📋 Checking configured secrets..."
firebase functions:secrets:list

echo ""
echo -e "${YELLOW}⚠️  Before proceeding, make sure you have set up the required secrets:${NC}"
echo "   - APNS_AUTH_KEY"
echo "   - APNS_KEY_ID"
echo "   - APNS_TEAM_ID"
echo "   - APP_STORE_CONNECT_KEY_ID"
echo "   - APP_STORE_CONNECT_ISSUER_ID"
echo "   - APP_STORE_SHARED_SECRET"
echo ""
echo "If not, run: ./setup_firebase_secrets.sh"
echo ""

read -p "Have you configured all required secrets? (y/n): " confirm
if [ "$confirm" != "y" ]; then
    echo "Please set up secrets first using ./setup_firebase_secrets.sh"
    exit 1
fi

# Deploy specific functions that had errors
echo ""
echo -e "${GREEN}Deploying fixed functions...${NC}"

# Deploy the fixed functions
firebase deploy --only functions:handleAppStoreNotification,functions:updateLiveActivitySimplified,functions:validateSubscriptionReceipt

echo ""
echo -e "${GREEN}✅ Deployment complete!${NC}"
echo ""
echo "📋 Next steps:"
echo "1. Check Firebase console for deployment status"
echo "2. Monitor function logs: firebase functions:log"
echo "3. Test the webhook endpoint for App Store notifications"
echo "4. Verify Live Activity updates are working"
echo ""
echo "🔍 To check if errors are resolved, run:"
echo "   firebase functions:log --only handleAppStoreNotification,updateLiveActivitySimplified"