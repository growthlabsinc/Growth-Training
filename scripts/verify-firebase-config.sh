#!/bin/bash

# Script to verify Firebase configuration
echo "🔍 Firebase Configuration Verification"
echo "===================================="

# Check bundle ID
BUNDLE_ID=$(defaults read "$(pwd)/Growth/Resources/Plist/App/Info.plist" CFBundleIdentifier 2>/dev/null || echo "Not found")
echo "App Bundle ID: $BUNDLE_ID"

# Check GoogleService-Info.plist files
echo -e "\n📄 GoogleService-Info.plist Files:"
for file in Growth/Resources/Plist/*GoogleService-Info.plist; do
    if [ -f "$file" ]; then
        echo -e "\n✅ Found: $file"
        # Extract key information
        BUNDLE_ID_PLIST=$(defaults read "$(pwd)/$file" BUNDLE_ID 2>/dev/null || echo "Not found")
        API_KEY=$(defaults read "$(pwd)/$file" API_KEY 2>/dev/null || echo "Not found")
        GCM_SENDER_ID=$(defaults read "$(pwd)/$file" GCM_SENDER_ID 2>/dev/null || echo "Not found")
        GOOGLE_APP_ID=$(defaults read "$(pwd)/$file" GOOGLE_APP_ID 2>/dev/null || echo "Not found")
        
        echo "  - Bundle ID: $BUNDLE_ID_PLIST"
        echo "  - API Key: ${API_KEY:0:10}..."
        echo "  - GCM Sender ID: $GCM_SENDER_ID"
        echo "  - Google App ID: $GOOGLE_APP_ID"
        
        # Check if bundle IDs match
        if [ "$BUNDLE_ID" = "$BUNDLE_ID_PLIST" ]; then
            echo "  ✅ Bundle ID matches app bundle ID"
        else
            echo "  ❌ Bundle ID mismatch! App: $BUNDLE_ID, Plist: $BUNDLE_ID_PLIST"
        fi
    fi
done

# Check Firebase Functions
echo -e "\n🔧 Firebase Functions:"
if [ -f "functions/package.json" ]; then
    echo "✅ Functions directory exists"
    
    # Check for liveActivityUpdates function
    if grep -q "updateLiveActivity" functions/*.js 2>/dev/null; then
        echo "✅ Live Activity update function found"
        
        # Check APNs topic
        echo -e "\n📱 APNs Topic Configuration:"
        grep -h "push-type.liveactivity" functions/*.js 2>/dev/null | head -5
    else
        echo "❌ Live Activity update function not found"
    fi
else
    echo "❌ Functions directory not found"
fi

# Check widget bundle ID
echo -e "\n📦 Widget Bundle ID:"
WIDGET_BUNDLE_ID=$(grep -A1 "PRODUCT_BUNDLE_IDENTIFIER.*Widget" Growth.xcodeproj/project.pbxproj | grep -v "PRODUCT_BUNDLE_IDENTIFIER" | sed 's/.*= //;s/;//' | head -1)
echo "Widget Bundle ID: $WIDGET_BUNDLE_ID"
echo "Expected APNs topic: ${WIDGET_BUNDLE_ID}.push-type.liveactivity"

echo -e "\n===================================="
echo "📋 Next Steps:"
echo "1. If bundle IDs don't match, download new GoogleService-Info.plist from Firebase Console"
echo "2. Ensure the app is registered in Firebase Console with bundle ID: $BUNDLE_ID"
echo "3. Configure App Check in Firebase Console for the app"
echo "4. Add debug token from Xcode console to Firebase App Check"