#!/bin/bash

echo "🚀 Deploying APNs configuration fix for Live Activity push updates..."
echo ""
echo "This script will deploy the updated Firebase Functions with the correct bundle ID"
echo "for APNs push notifications after the recent bundle ID update."
echo ""

# Navigate to functions directory
cd functions

# Deploy only the Live Activity related functions
echo "📦 Deploying Live Activity functions..."
firebase deploy --only functions:updateLiveActivity,functions:updateLiveActivityTimer,functions:onTimerStateChange,functions:startLiveActivity,functions:manageLiveActivityUpdates

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📝 Notes:"
echo "1. The APNs topic has been updated to: com.growthlabs.growthmethod.GrowthTimerWidget.push-type.liveactivity"
echo "2. Make sure the APNs auth key is properly configured in Firebase Functions config"
echo "3. To set the APNs auth key if missing, run:"
echo "   firebase functions:config:set apns.auth_key=\"YOUR_AUTH_KEY_CONTENT\""
echo "4. The auth key should be the contents of your .p8 file from Apple Developer Portal"
echo ""
echo "⚠️  If you're still getting INTERNAL errors after deployment:"
echo "   1. Check that the APNs auth key is properly set in Firebase config"
echo "   2. Verify the key ID (3G84L8G52R) and team ID (62T6J77P6R) are correct"
echo "   3. Ensure the .p8 key file hasn't expired (they're valid for 1 year)"