#!/bin/bash

echo "Firebase App Check Diagnostic and Fix Script"
echo "==========================================="

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Please install it with: npm install -g firebase-tools"
    exit 1
fi

echo "✓ Firebase CLI is installed"

# Check current project
echo ""
echo "Current Firebase project:"
firebase use

# Get the project ID
PROJECT_ID=$(firebase use | grep -oE 'growth-[a-z0-9]+' | head -1)
if [ -z "$PROJECT_ID" ]; then
    PROJECT_ID="growth-70a85"
fi

echo ""
echo "Project ID: $PROJECT_ID"

# Instructions for App Check
echo ""
echo "To fix App Check issues, follow these steps:"
echo ""
echo "1. Open Firebase Console: https://console.firebase.google.com/project/$PROJECT_ID/appcheck"
echo ""
echo "2. Register your app with App Check:"
echo "   - Click on your iOS app"
echo "   - Select 'DeviceCheck' as the provider for production"
echo "   - Click 'Save'"
echo ""
echo "3. For DEBUG builds (simulator/development):"
echo "   - In your app, App Check will print a debug token in the console"
echo "   - Copy this token from Xcode console (starts with a long alphanumeric string)"
echo "   - In Firebase Console, go to App Check > Apps > Your App > Manage debug tokens"
echo "   - Add the debug token"
echo ""
echo "4. Optional - Disable App Check enforcement temporarily:"
echo "   - This can help test if App Check is the issue"
echo "   - In Firebase Console, go to each service (Firestore, Functions, etc.)"
echo "   - Disable 'Enforce App Check' if enabled"
echo ""
echo "5. For Cloud Functions specifically:"
echo "   - Functions may need to be redeployed after App Check changes"
echo "   - Run: firebase deploy --only functions"
echo ""

# Check if functions are using App Check
echo "Checking Cloud Functions configuration..."
if [ -f "functions/index.js" ]; then
    if grep -q "app-check" functions/index.js; then
        echo "⚠️  Your Cloud Functions appear to use App Check"
    else
        echo "✓ Your Cloud Functions don't appear to enforce App Check in code"
    fi
fi

echo ""
echo "Current Firestore rules enforcement:"
if grep -q "request.app" firestore.rules; then
    echo "⚠️  Firestore rules enforce App Check"
else
    echo "✓ Firestore rules don't enforce App Check"
fi

echo ""
echo "Script complete. Follow the steps above to configure App Check properly."