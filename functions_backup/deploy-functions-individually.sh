#!/bin/bash

echo "🚀 Deploying Firebase Functions Individually..."

# First, backup the current manageLiveActivityUpdates.js
cp manageLiveActivityUpdates.js manageLiveActivityUpdates-backup.js
cp manageLiveActivityUpdates-fixed.js manageLiveActivityUpdates.js

# Navigate to parent directory
cd ..

# Function to deploy with retry
deploy_function() {
    local func_name=$1
    local max_retries=3
    local retry=0
    
    echo "📦 Deploying function: $func_name"
    
    while [ $retry -lt $max_retries ]; do
        if firebase deploy --only functions:$func_name --force; then
            echo "✅ Successfully deployed: $func_name"
            return 0
        else
            retry=$((retry + 1))
            echo "⚠️ Retry $retry/$max_retries for: $func_name"
            sleep 5
        fi
    done
    
    echo "❌ Failed to deploy: $func_name after $max_retries attempts"
    return 1
}

# Deploy critical functions first
echo "🎯 Deploying critical functions..."
deploy_function "generateAIResponse"
deploy_function "manageLiveActivityUpdates"
deploy_function "updateLiveActivityTimer"
deploy_function "onTimerStateChange"

# Deploy other functions
echo "📱 Deploying Live Activity functions..."
deploy_function "updateLiveActivity"
deploy_function "startLiveActivity"

echo "🔧 Deploying utility functions..."
deploy_function "addMissingRoutines"
deploy_function "trackRoutineDownload"

echo "🛡️ Deploying moderation functions..."
deploy_function "moderateNewRoutine"
deploy_function "processReport"
deploy_function "banUser"
deploy_function "moderateContent"
deploy_function "cleanupOldReports"
deploy_function "checkUserBanned"

echo "📸 Deploying resource functions..."
deploy_function "updateEducationalResourceImages"
deploy_function "updateEducationalResourceImagesCallable"

echo "📊 Deploying stats functions..."
deploy_function "updateRoutineStats"

echo "✨ Deployment process complete!"
echo ""
echo "📝 Summary:"
echo "- Fixed manageLiveActivityUpdates.js with proper APNS payload format"
echo "- Added proper stale-date handling for Live Activities"
echo "- Improved timer state synchronization"
echo "- Fixed widget bundle ID for APNS topic"
echo ""
echo "🔍 Check deployment status:"
echo "firebase functions:log --only manageLiveActivityUpdates"