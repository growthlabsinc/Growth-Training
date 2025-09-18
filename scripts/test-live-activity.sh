#!/bin/bash

# Test Live Activity Push Updates

echo "🔵 Testing Live Activity Push Updates..."
echo ""

# Check Firebase Functions deployment
echo "1. Checking Firebase Functions deployment..."
firebase functions:config:get | grep -E "(APNS_|apns_)" || echo "⚠️  No APNs config found. Set with: firebase functions:config:set apns.key_id=YOUR_KEY_ID apns.team_id=YOUR_TEAM_ID"
echo ""

# Check recent function logs
echo "2. Recent function logs (last 10 entries)..."
firebase functions:log --only manageLiveActivityUpdates -n 10
echo ""

# Instructions
echo "3. Manual Testing Steps:"
echo "   a) Start a timer in the app on a REAL DEVICE (not simulator)"
echo "   b) Look for these logs in Xcode console:"
echo "      - '✅ Live Activity push token received'"
echo "      - '✅ LiveActivityManager: Successfully stored Live Activity push token'"
echo "   c) Check Firebase function logs for:"
echo "      - 'Starting push updates for activity'"
echo "      - 'Push Notification] Successfully sent push update'"
echo ""

echo "4. If push tokens aren't received:"
echo "   - Ensure testing on real device with iOS 16.2+"
echo "   - Check Settings > [Your App] > Notifications is ON"
echo "   - Check Settings > Face ID & Passcode > Live Activities is ON"
echo "   - Delete and reinstall the app"
echo ""

echo "5. Deploy functions with APNs config:"
echo "   firebase functions:config:set apns.key_id=YOUR_KEY_ID apns.team_id=YOUR_TEAM_ID"
echo "   # Add your APNs auth key to environment"
echo "   firebase functions:config:set apns.auth_key=\"-----BEGIN PRIVATE KEY-----"
echo "   YOUR_KEY_CONTENT_HERE"
echo "   -----END PRIVATE KEY-----\""
echo "   firebase deploy --only functions:manageLiveActivityUpdates"