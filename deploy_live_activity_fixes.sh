#!/bin/bash

# Deploy Live Activity Fixes Script
# This script deploys the Firebase Functions updates to fix Live Activity errors

echo "🚀 Deploying Live Activity Firebase Functions Fixes..."

# Navigate to functions directory
cd functions || exit 1

# Install dependencies (in case any were added)
echo "📦 Installing dependencies..."
npm install

# Deploy the specific functions that were updated
echo "🔧 Deploying updated functions..."
firebase deploy --only functions:registerLiveActivityPushToken,functions:registerPushToStartToken,functions:updateLiveActivity

echo "✅ Deployment complete!"
echo ""
echo "📝 Summary of fixes deployed:"
echo "1. ✅ Added registerLiveActivityPushToken function to store push tokens"
echo "2. ✅ Added registerPushToStartToken function for push-to-start support"
echo "3. ✅ Fixed content state encoding to only send required fields (startedAt, pausedAt, duration, methodName, sessionType)"
echo ""
echo "🎯 Next Steps:"
echo "1. Run the app on a physical device"
echo "2. Start a timer to test Live Activity"
echo "3. Use pause/resume buttons in Dynamic Island to verify push updates work"
echo "4. Check Firebase Functions logs for any errors"
echo ""
echo "📊 To monitor function logs:"
echo "   firebase functions:log --only updateLiveActivity"
echo "   firebase functions:log --only registerLiveActivityPushToken"