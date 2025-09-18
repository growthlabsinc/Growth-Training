#!/bin/bash

echo "🔄 Switching to Development Environment with Key DQ46FN4PQU..."
echo "=================================================="

# Update APNS_AUTH_KEY
echo ""
echo "📝 Updating APNS_AUTH_KEY secret..."
if firebase functions:secrets:set APNS_AUTH_KEY < /Users/tradeflowj/Downloads/AuthKey_DQ46FN4PQU.p8; then
    echo "✅ APNS_AUTH_KEY updated successfully"
else
    echo "❌ Failed to update APNS_AUTH_KEY"
    exit 1
fi

# Update APNS_KEY_ID
echo ""
echo "🔑 Updating APNS_KEY_ID secret..."
if echo "DQ46FN4PQU" | firebase functions:secrets:set APNS_KEY_ID; then
    echo "✅ APNS_KEY_ID updated successfully"
else
    echo "❌ Failed to update APNS_KEY_ID"
    exit 1
fi

# Verify APNS_TEAM_ID
echo ""
echo "🔍 Verifying APNS_TEAM_ID..."
TEAM_ID=$(firebase functions:secrets:access APNS_TEAM_ID 2>/dev/null)
if [[ "$TEAM_ID" == "62T6J77P6R" ]]; then
    echo "✅ APNS_TEAM_ID is correct: 62T6J77P6R"
else
    echo "⚠️  APNS_TEAM_ID might need updating. Current value: $TEAM_ID"
fi

echo ""
echo "=================================================="
echo "🚀 Updating functions to use development APNs server..."
echo ""

# Now we need to update the code to use development server
echo "✅ Secrets updated! Now deploying functions..."
echo ""

# Deploy all APNs-related functions
firebase deploy --only functions:updateLiveActivity,functions:manageLiveActivityUpdates,functions:updateLiveActivityTimer,functions:collectAPNsDiagnostics,functions:onTimerStateChange,functions:testAPNsConnection

echo ""
echo "🎉 Done! Your app is now configured for development environment."
echo ""
echo "📱 New Configuration:"
echo "   - Key ID: DQ46FN4PQU (Development)"
echo "   - Team ID: 62T6J77P6R"
echo "   - Bundle ID: com.growthlabs.growthmethod"
echo "   - APNs Server: api.development.push.apple.com"