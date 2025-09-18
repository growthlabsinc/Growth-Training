#!/bin/bash

echo "🧹 Clearing Firebase Cache and App Check Token"
echo "=============================================="
echo ""

# Function to find and clear app containers
clear_app_containers() {
    local bundle_id=$1
    local app_name=$2
    
    echo "📱 Clearing cache for $app_name ($bundle_id)..."
    
    # Find the app container
    APP_CONTAINER=$(find ~/Library/Developer/CoreSimulator/Devices -name "$bundle_id" -type d 2>/dev/null | head -1)
    
    if [ -n "$APP_CONTAINER" ]; then
        echo "   Found container at: $APP_CONTAINER"
        
        # Clear Firebase cache directories
        rm -rf "$APP_CONTAINER/Library/Caches/com.google.firebase.*" 2>/dev/null
        rm -rf "$APP_CONTAINER/Library/Caches/Firebase" 2>/dev/null
        rm -rf "$APP_CONTAINER/Library/Application Support/com.google.firebase.*" 2>/dev/null
        rm -rf "$APP_CONTAINER/Library/Application Support/Firebase" 2>/dev/null
        
        # Clear App Check specific data
        rm -rf "$APP_CONTAINER/Library/Caches/com.firebase.appcheck" 2>/dev/null
        rm -rf "$APP_CONTAINER/Library/Application Support/com.firebase.appcheck" 2>/dev/null
        
        echo "   ✅ Firebase cache cleared for simulator"
    else
        echo "   ℹ️  No simulator container found"
    fi
}

# Kill any running app instances
echo "1. Stopping any running Growth app instances..."
pkill -f "Growth" || echo "   ℹ️  No running instances found"

echo ""
echo "2. Clearing DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Growth-*
echo "   ✅ DerivedData cleared"

echo ""
echo "3. Clearing Firebase cache from simulators..."

# Clear for all bundle IDs
clear_app_containers "com.growth" "Production"
clear_app_containers "com.growth.dev" "Development"
clear_app_containers "com.growth.staging" "Staging"

echo ""
echo "4. Clearing physical device cache (if connected)..."
echo "   ℹ️  For physical devices, you need to:"
echo "   1. Delete the app from the device"
echo "   2. Restart the device"
echo "   3. Reinstall the app"

echo ""
echo "5. Clearing App Group data..."
APP_GROUP_PATH=~/Library/Group\ Containers/group.com.growthlabs.growthlabsmethod.shared
if [ -d "$APP_GROUP_PATH" ]; then
    # Clear App Check token
    rm -f "$APP_GROUP_PATH/app_check_token.json" 2>/dev/null
    rm -f "$APP_GROUP_PATH/firebase_app_check_token" 2>/dev/null
    
    # Clear any cached Firebase data
    rm -rf "$APP_GROUP_PATH/Firebase" 2>/dev/null
    rm -rf "$APP_GROUP_PATH/com.firebase.*" 2>/dev/null
    
    echo "   ✅ App Group Firebase data cleared"
else
    echo "   ℹ️  App Group container not found"
fi

echo ""
echo "6. Clearing Keychain items (requires user approval)..."
echo "   ℹ️  You may be prompted to allow keychain access"

# Try to delete Firebase-related keychain items
security delete-generic-password -s "com.firebase.appcheck" 2>/dev/null || true
security delete-generic-password -s "com.google.firebase.appcheck" 2>/dev/null || true
security delete-generic-password -s "FIRAppCheckToken" 2>/dev/null || true

echo ""
echo "7. Creating App Check token reset flag..."
# Create a flag file to force token regeneration
touch ~/Library/Developer/Xcode/DerivedData/force_appcheck_reset.flag
echo "   ✅ Reset flag created"

echo ""
echo "=============================================="
echo "✅ Firebase cache clearing complete!"
echo ""
echo "📝 Next steps:"
echo "1. Clean build folder: Cmd+Shift+K in Xcode"
echo "2. Reset package cache: File > Packages > Reset Package Caches"
echo "3. Build and run the app"
echo "4. The app will generate a new App Check token on launch"
echo ""
echo "🔍 To verify new token generation, look for:"
echo "   - 'App Check token fetched successfully' in console"
echo "   - 'New App Check debug token:' followed by the token"
echo ""
echo "💡 If you're using debug tokens, remember to:"
echo "1. Add the new debug token to Firebase Console"
echo "2. Update any environment variables with the new token"

# Make the script executable
chmod +x "$0"