#!/bin/bash

# Script to extract App Check debug token from UserDefaults
# This works even when the app is not running

echo "🔍 Looking for App Check Debug Token..."
echo ""

# Try to read from the app's UserDefaults
BUNDLE_ID="com.growthlabs.growthmethod"
TOKEN=$(defaults read $BUNDLE_ID FIRAAppCheckDebugToken 2>/dev/null)

if [ $? -eq 0 ] && [ ! -z "$TOKEN" ]; then
    echo "✅ Found App Check Debug Token:"
    echo "========================================"
    echo "$TOKEN"
    echo "========================================"
    echo ""
    echo "📋 To use this token:"
    echo "1. Go to: https://console.firebase.google.com/project/growth-70a85/appcheck/apps"
    echo "2. Find your iOS app (com.growthlabs.growthmethod)"
    echo "3. Click the three dots menu → 'Manage debug tokens'"
    echo "4. Click 'Add debug token'"
    echo "5. Paste the token above and give it a name like 'Dev Simulator'"
    echo ""
    echo "💡 Tip: You can copy the token by running:"
    echo "   defaults read $BUNDLE_ID FIRAAppCheckDebugToken | pbcopy"
else
    echo "❌ No App Check debug token found in UserDefaults"
    echo ""
    echo "This could mean:"
    echo "1. The app hasn't been run yet in debug mode"
    echo "2. The app was deleted and reinstalled (new token will be generated)"
    echo "3. You're not running in debug/simulator mode"
    echo ""
    echo "Try:"
    echo "1. Build and run the app in the simulator"
    echo "2. Look for the token in Xcode console at app startup"
    echo "3. Or go to Settings > Developer Options > App Check Debug Token"
fi