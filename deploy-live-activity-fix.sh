#!/bin/bash

# Deploy Firebase functions with the new simplified Live Activity format

echo "🚀 Deploying Firebase functions with simplified Live Activity format..."
echo ""

# Deploy the specific functions that handle Live Activities
echo "📦 Deploying Live Activity functions..."
firebase deploy --only functions:updateLiveActivity,functions:updateLiveActivityTimer,functions:onTimerStateChange,functions:manageLiveActivityUpdates

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Firebase functions deployed successfully!"
    echo ""
    echo "The Live Activity resume fix is now deployed. Key improvements:"
    echo "- Fixed 1-hour default duration bug"
    echo "- Simplified timestamp handling with startedAt/pausedAt approach"
    echo "- Better pause/resume behavior"
    echo "- Improved compatibility with iOS native timer APIs"
else
    echo ""
    echo "❌ Deployment failed. Please check the error messages above."
    exit 1
fi