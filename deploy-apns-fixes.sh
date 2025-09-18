#!/bin/bash

echo "🚀 Deploying APNs fixes for Live Activity updates..."

# Navigate to functions directory
cd functions || exit 1

# Deploy the updated functions
echo "📦 Deploying updated Firebase functions..."
firebase deploy --only functions:updateLiveActivity,functions:updateLiveActivityTimer,functions:manageLiveActivityUpdates,functions:collectAPNsDiagnostics,functions:onTimerStateChange

if [ $? -eq 0 ]; then
    echo "✅ APNs fixes deployed successfully!"
    echo ""
    echo "📋 Summary of fixes:"
    echo "1. ✅ APNs topic corrected from 'com.growthlabs.growthmethod.push-type.liveactivity' to 'com.growthlabs.growthmethod'"
    echo "2. ✅ APNS_KEY_ID secret value trimmed to remove newline characters"
    echo "3. ✅ All environment variables now trimmed when loaded"
    echo ""
    echo "🔧 Functions updated:"
    echo "- updateLiveActivity"
    echo "- updateLiveActivityTimer"
    echo "- manageLiveActivityUpdates"
    echo "- collectAPNsDiagnostics"
    echo "- onTimerStateChange"
else
    echo "❌ Deployment failed. Please check the error messages above."
    exit 1
fi