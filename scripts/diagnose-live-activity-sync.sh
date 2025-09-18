#!/bin/bash

# Live Activity Synchronization Diagnostic Script
# This script helps diagnose issues with Live Activity pause/resume functionality

echo "🔍 Live Activity Synchronization Diagnostic"
echo "=========================================="
echo ""

# Check if the app is running
echo "1. Checking for running Growth app processes..."
ps aux | grep -i "growth" | grep -v grep | head -5

echo ""
echo "2. Checking for Firebase function logs (last 20 lines)..."
if command -v firebase &> /dev/null; then
    firebase functions:log --only updateLiveActivitySimplified --lines 20 2>/dev/null || echo "   ⚠️  Unable to fetch Firebase logs. Make sure you're logged in: firebase login"
else
    echo "   ⚠️  Firebase CLI not found. Install with: npm install -g firebase-tools"
fi

echo ""
echo "3. Checking for GTMSessionFetcher errors in system logs..."
log show --predicate 'eventMessage contains "GTMSessionFetcher"' --last 5m 2>/dev/null | tail -20 || echo "   ℹ️  No GTMSessionFetcher errors found in last 5 minutes"

echo ""
echo "4. Checking for Live Activity logs..."
log show --predicate 'eventMessage contains "Live Activity" OR eventMessage contains "LiveActivity"' --last 5m 2>/dev/null | tail -30 || echo "   ℹ️  No Live Activity logs found"

echo ""
echo "5. Checking for Darwin notification logs..."
log show --predicate 'eventMessage contains "Darwin notification" OR eventMessage contains "com.growthlabs.growthmethod.liveactivity"' --last 5m 2>/dev/null | tail -20 || echo "   ℹ️  No Darwin notification logs found"

echo ""
echo "6. Checking App Group container..."
APP_GROUP_PATH=~/Library/Group\ Containers/group.com.growthlabs.growthlabsmethod.shared
if [ -d "$APP_GROUP_PATH" ]; then
    echo "   ✅ App Group container exists"
    echo "   📁 Path: $APP_GROUP_PATH"
    
    # Check for timer action file
    if [ -f "$APP_GROUP_PATH/timer_action.json" ]; then
        echo "   📄 Timer action file found:"
        cat "$APP_GROUP_PATH/timer_action.json" 2>/dev/null | jq . || cat "$APP_GROUP_PATH/timer_action.json"
    else
        echo "   ℹ️  No timer action file found"
    fi
else
    echo "   ⚠️  App Group container not found"
fi

echo ""
echo "7. Testing Darwin notification delivery..."
echo "   ℹ️  To test Darwin notifications manually, run:"
echo "   notifyutil -p com.growthlabs.growthmethod.liveactivity.pause"

echo ""
echo "=========================================="
echo "📋 Quick Troubleshooting Guide:"
echo ""
echo "1. If you see 'GTMSessionFetcher was already running':"
echo "   - The synchronization fix should prevent this"
echo "   - Check that LiveActivityManagerSimplified has FirebaseSynchronizer"
echo ""
echo "2. If Live Activity doesn't update:"
echo "   - Ensure device has network connection"
echo "   - Check Firebase function logs for errors"
echo "   - Verify push token is registered in Firestore"
echo ""
echo "3. If pause button doesn't work:"
echo "   - Check Darwin notification logs"
echo "   - Verify App Group is configured correctly"
echo "   - Ensure timer type (main/quick) matches"
echo ""
echo "4. For iOS 16 devices:"
echo "   - Buttons are display-only, updates come via push"
echo "   - Check Firebase function is sending updates"
echo ""
echo "5. For iOS 17+ devices:"
echo "   - Buttons should work immediately"
echo "   - Local updates happen first, then Firebase sync"

chmod +x "$0"