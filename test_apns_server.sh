#!/bin/bash

# Test script for Direct APNs Server
# This script tests the APNs server endpoints

echo "=========================================="
echo "Testing Direct APNs Server"
echo "=========================================="
echo ""

# Server URL (default to localhost)
SERVER_URL="${1:-http://localhost:3000}"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Test health endpoint
echo "Testing health endpoint..."
HEALTH_RESPONSE=$(curl -s "$SERVER_URL/health")
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Health check passed${NC}"
    echo "Response: $HEALTH_RESPONSE"
else
    echo -e "${RED}❌ Health check failed${NC}"
    echo "Is the server running? Try: cd apns-server && npm start"
    exit 1
fi

echo ""
echo "Testing token registration..."

# Test token registration
TEST_TOKEN="test_token_$(date +%s)"
TEST_ACTIVITY="test_activity_$(date +%s)"

REGISTER_RESPONSE=$(curl -s -X POST "$SERVER_URL/register-token" \
    -H "Content-Type: application/json" \
    -d "{\"token\":\"$TEST_TOKEN\",\"activityId\":\"$TEST_ACTIVITY\"}")

if echo "$REGISTER_RESPONSE" | grep -q "success"; then
    echo -e "${GREEN}✅ Token registration test passed${NC}"
    echo "Response: $REGISTER_RESPONSE"
else
    echo -e "${RED}❌ Token registration test failed${NC}"
    echo "Response: $REGISTER_RESPONSE"
fi

echo ""
echo "Testing activity update (will fail without valid token)..."

# Test activity update (this will fail without a real push token, but tests the endpoint)
UPDATE_RESPONSE=$(curl -s -X POST "$SERVER_URL/update-activity" \
    -H "Content-Type: application/json" \
    -d "{
        \"activityId\":\"$TEST_ACTIVITY\",
        \"action\":\"update\",
        \"contentState\":{
            \"startedAt\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",
            \"pausedAt\":null,
            \"duration\":1800,
            \"methodName\":\"Test Timer\",
            \"sessionType\":\"countdown\"
        }
    }")

echo "Update response: $UPDATE_RESPONSE"
echo ""

# Cleanup test tokens
echo "Testing cleanup endpoint..."
CLEANUP_RESPONSE=$(curl -s -X POST "$SERVER_URL/cleanup-tokens")
if echo "$CLEANUP_RESPONSE" | grep -q "success"; then
    echo -e "${GREEN}✅ Cleanup test passed${NC}"
    echo "Response: $CLEANUP_RESPONSE"
else
    echo -e "${YELLOW}⚠️  Cleanup test returned:${NC}"
    echo "Response: $CLEANUP_RESPONSE"
fi

echo ""
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo ""
echo "Server URL: $SERVER_URL"
echo ""
echo "Note: The update-activity endpoint will fail with APNs errors"
echo "unless you use a real push token from an actual Live Activity."
echo ""
echo "To test with real Live Activities:"
echo "1. Run the iOS app and start a timer"
echo "2. Check server logs for registered push tokens"
echo "3. Use the actual token to test updates"
echo ""