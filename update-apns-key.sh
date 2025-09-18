#!/bin/bash

echo "🔐 Updating Firebase APNs Secrets with Production Key..."
echo "=================================================="

# Update APNS_AUTH_KEY
echo ""
echo "📝 Updating APNS_AUTH_KEY secret..."
if firebase functions:secrets:set APNS_AUTH_KEY < /Users/tradeflowj/Downloads/AuthKey_S5JA56D56T.p8; then
    echo "✅ APNS_AUTH_KEY updated successfully"
else
    echo "❌ Failed to update APNS_AUTH_KEY"
    exit 1
fi

# Update APNS_KEY_ID
echo ""
echo "🔑 Updating APNS_KEY_ID secret..."
if echo "S5JA56D56T" | firebase functions:secrets:set APNS_KEY_ID; then
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
echo "✅ Secrets updated! Now deploying functions..."
echo ""

# Deploy the functions
firebase deploy --only functions:updateLiveActivity,functions:manageLiveActivityUpdates,functions:updateLiveActivityTimer,functions:collectAPNsDiagnostics,functions:onTimerStateChange

echo ""
echo "🎉 Done! Your Live Activities should now work with production push tokens."
echo ""
echo "📱 Key Details:"
echo "   - Key ID: S5JA56D56T (Production)"
echo "   - Team ID: 62T6J77P6R"
echo "   - Bundle ID: com.growthlabs.growthmethod"