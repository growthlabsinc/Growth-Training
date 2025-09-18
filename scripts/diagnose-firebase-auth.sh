#!/bin/bash

echo "=== Firebase Authentication Diagnostics ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Navigate to project root
cd "$(dirname "$0")/.."

echo -e "${BLUE}1. Checking Firebase project configuration...${NC}"
firebase use 2>/dev/null || echo -e "${RED}Firebase CLI not configured${NC}"

echo ""
echo -e "${BLUE}2. Checking deployed functions...${NC}"
firebase functions:list 2>/dev/null || echo -e "${RED}Cannot list functions${NC}"

echo ""
echo -e "${BLUE}3. Checking package.json for function dependencies...${NC}"
if [ -f "functions/package.json" ]; then
    echo "Functions package.json found"
    grep -E '"firebase-functions"|"firebase-admin"' functions/package.json
else
    echo -e "${RED}functions/package.json not found${NC}"
fi

echo ""
echo -e "${BLUE}4. Checking function code for authentication settings...${NC}"
if [ -f "functions/index.js" ]; then
    echo "Checking generateAIResponse function configuration:"
    grep -A 20 "generateAIResponse" functions/index.js | grep -E "cors|invoker|consumeAppCheckToken|region" || echo "No auth settings found"
else
    echo -e "${RED}functions/index.js not found${NC}"
fi

echo ""
echo -e "${BLUE}5. Checking Firestore rules...${NC}"
if [ -f "firebase/firestore/firestore.rules" ]; then
    echo "Current Firestore rules:"
    head -n 20 firebase/firestore/firestore.rules
else
    echo -e "${RED}Firestore rules file not found${NC}"
fi

echo ""
echo -e "${BLUE}6. Checking AppCheckProviderFactory configuration...${NC}"
if [ -f "Growth/Core/Networking/AppCheckProviderFactory.swift" ]; then
    echo "App Check configuration:"
    grep -E "AppCheckDebugProvider|AppCheckProvider|setAppCheckProviderFactory" Growth/Core/Networking/AppCheckProviderFactory.swift
else
    echo -e "${RED}AppCheckProviderFactory.swift not found${NC}"
fi

echo ""
echo -e "${BLUE}7. Testing function endpoint (if deployed)...${NC}"
PROJECT_ID=$(firebase use 2>/dev/null | grep "Active Project" | cut -d ":" -f 2 | xargs)
if [ ! -z "$PROJECT_ID" ]; then
    FUNCTION_URL="https://us-central1-$PROJECT_ID.cloudfunctions.net/generateAIResponse"
    echo "Testing function at: $FUNCTION_URL"
    
    # Test with curl
    RESPONSE=$(curl -s -X POST $FUNCTION_URL \
        -H "Content-Type: application/json" \
        -d '{"data":{"query":"test"}}' 2>&1)
    
    if [[ $RESPONSE == *"UNAUTHENTICATED"* ]]; then
        echo -e "${RED}Function returns UNAUTHENTICATED - needs permission fix${NC}"
    elif [[ $RESPONSE == *"text"* ]]; then
        echo -e "${GREEN}Function appears to be working!${NC}"
    elif [[ $RESPONSE == *"404"* ]] || [[ $RESPONSE == *"Not Found"* ]]; then
        echo -e "${RED}Function not found - may not be deployed${NC}"
    else
        echo -e "${YELLOW}Unexpected response:${NC}"
        echo "$RESPONSE" | head -n 5
    fi
else
    echo -e "${RED}Cannot determine project ID${NC}"
fi

echo ""
echo -e "${BLUE}=== Diagnostic Summary ===${NC}"
echo ""
echo -e "${YELLOW}Common issues and solutions:${NC}"
echo ""
echo "1. ${YELLOW}UNAUTHENTICATED error:${NC}"
echo "   - Enable Anonymous Authentication in Firebase Console"
echo "   - Set function to allow unauthenticated invocations"
echo "   - Update function with invoker: 'public' setting"
echo ""
echo "2. ${YELLOW}App Check DEBUG provider warning:${NC}"
echo "   - This is normal for development"
echo "   - Make sure consumeAppCheckToken: false in function config"
echo ""
echo "3. ${YELLOW}Network connection errors:${NC}"
echo "   - Check internet connectivity"
echo "   - Verify Firebase project is active"
echo "   - Try resetting iOS Simulator network settings"
echo ""
echo "Run ${GREEN}./scripts/fix-firebase-complete.sh${NC} to apply fixes"