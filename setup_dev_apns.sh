#!/bin/bash

# Setup Development APNS Key for Firebase Functions
echo "========================================="
echo "Setting up Development APNS Key"
echo "========================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Navigate to functions directory
cd /Users/tradeflowj/Desktop/Dev/growth-backup-22aug2025/functions

# Check if development key exists
if [ ! -f "AuthKey_55LZB28UY2.p8" ]; then
    echo -e "${RED}❌ Development APNS key not found!${NC}"
    echo "Please ensure AuthKey_55LZB28UY2.p8 exists in the functions directory"
    exit 1
fi

echo -e "${GREEN}✅ Development APNS key found${NC}"

# Create or update secrets for development key
echo ""
echo "Setting up Firebase secrets for development..."

# Set the development APNS key as a secret
echo "Creating secret for development APNS key..."
firebase functions:secrets:set APNS_AUTH_KEY_55LZB28UY2 < AuthKey_55LZB28UY2.p8

# Set other APNS configuration
echo ""
echo "Setting APNS configuration..."
firebase functions:secrets:set APNS_KEY_ID "55LZB28UY2"
firebase functions:secrets:set APNS_TEAM_ID "X3GR4M63VQ"
firebase functions:secrets:set APNS_TOPIC "com.growthlabs.growthmethod.push-type.liveactivity"

echo ""
echo -e "${GREEN}✅ Development APNS configuration complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Deploy the functions: firebase deploy --only functions"
echo "2. Run the app in Xcode with Development build configuration"
echo "3. Monitor logs with: ./diagnose_live_activity.sh"
echo ""
echo -e "${YELLOW}Note: The development key (55LZB28UY2) will be used for:${NC}"
echo "  • Xcode builds (Debug configuration)"
echo "  • Development server: api.development.push.apple.com"
echo "  • Sandbox environment testing"