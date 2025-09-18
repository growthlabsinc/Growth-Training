#!/bin/bash

echo "🧹 Clearing App Check cache and debug tokens..."

# Kill any running app instances
echo "Stopping app if running..."
killall "Growth" 2>/dev/null || true

# Clear all possible App Check related UserDefaults
echo "Clearing UserDefaults..."
defaults delete com.growthlabs.growthmethod FIRAAppCheckDebugToken 2>/dev/null || true
defaults delete com.growthlabs.growthmethod FIRAppCheckDebugToken 2>/dev/null || true
defaults delete com.growthlabs.growthmethod AppCheckDebugToken 2>/dev/null || true
defaults delete com.growthlabs.growthmethod com.firebase.appcheck.debug_token 2>/dev/null || true

# Clear Firebase cache
echo "Clearing Firebase cache..."
rm -rf ~/Library/Caches/com.growthlabs.growthmethod 2>/dev/null || true
rm -rf ~/Library/Caches/com.google.firebase.* 2>/dev/null || true

# Clear app data
echo "Clearing app data..."
rm -rf ~/Library/Developer/CoreSimulator/Devices/*/data/Containers/Data/Application/*/Library/Caches/com.growthlabs.growthmethod 2>/dev/null || true

echo "✅ Cache cleared!"
echo ""
echo "Next steps:"
echo "1. Run the app again with -FIRDebugEnabled flag"
echo "2. Copy the new debug token from console"
echo "3. Add it to Firebase Console → App Check → Manage debug tokens"
echo "4. Restart the app"