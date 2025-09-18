#!/bin/bash

echo "🔍 Diagnosing App Check Issues..."
echo "================================"

# Check for debug token in UserDefaults
echo "1. Checking for stored debug token..."
TOKEN=$(defaults read com.growthlabs.growthmethod FIRAAppCheckDebugToken 2>/dev/null)

if [ $? -eq 0 ]; then
    echo "✅ Found debug token: $TOKEN"
    echo ""
    echo "⚠️  Make sure this token is registered in Firebase Console:"
    echo "   https://console.firebase.google.com/project/growth-70a85/appcheck/apps"
else
    echo "❌ No debug token found in UserDefaults"
    echo "   The app will generate one on next run"
fi

echo ""
echo "2. Checking -FIRDebugEnabled flag..."
# Check if Xcode scheme has the flag
if grep -q "FIRDebugEnabled" ~/Library/Developer/Xcode/DerivedData/Growth-*/Build/Products/Debug-iphonesimulator/Growth.app/Info.plist 2>/dev/null; then
    echo "✅ -FIRDebugEnabled flag is set"
else
    echo "⚠️  -FIRDebugEnabled flag might not be set"
    echo "   Check: Xcode → Product → Scheme → Edit Scheme → Arguments"
fi

echo ""
echo "3. Next Steps:"
echo "   a) Run the app - it will generate a new token if needed"
echo "   b) Copy the token from console logs"
echo "   c) Add it to Firebase Console → App Check → Manage debug tokens"
echo "   d) Restart the app"
echo ""
echo "4. If still getting 403 errors:"
echo "   - Check App Check enforcement is disabled in Firebase Console"
echo "   - Verify the app ID matches your Firebase project"
echo "   - Try clearing all caches with: ./force_new_debug_token.sh"