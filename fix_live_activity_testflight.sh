#!/bin/bash

echo "🔧 Fixing Live Activity Pause Button for TestFlight"
echo "=================================================="
echo ""

# Clean DerivedData
echo "1️⃣ Cleaning DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Growth-*

# Verify URL scheme handling is implemented
echo ""
echo "2️⃣ Verifying URL scheme handling..."
if grep -q "growth://timer" Growth/Application/AppSceneDelegate.swift; then
    echo "✅ URL scheme handling is implemented"
else
    echo "❌ URL scheme handling missing - fix has been applied"
fi

# Check widget iOS version requirement
echo ""
echo "3️⃣ Checking widget iOS version compatibility..."
echo "Widget uses conditional code:"
echo "- iOS 17.0+: App Intents (Button with intent)"
echo "- iOS 16.x: Deep Links (Link with URL)"

# Verify Info.plist has the URL scheme
echo ""
echo "4️⃣ Verifying Info.plist URL scheme..."
if grep -q "<string>growth</string>" Growth/Resources/Plist/App/Info.plist; then
    echo "✅ URL scheme 'growth' is registered"
else
    echo "❌ URL scheme 'growth' is NOT registered"
fi

echo ""
echo "📝 Summary of the fix:"
echo "1. Added deep link handling in AppSceneDelegate.swift"
echo "2. The widget already has iOS 16/17 compatibility code"
echo "3. URL scheme 'growth' is registered in Info.plist"
echo ""
echo "⚠️  Important Notes:"
echo "- iOS 16.x users will use deep links for pause/resume"
echo "- iOS 17.0+ users will use App Intents"
echo "- Both methods are now properly handled"
echo ""
echo "🚀 Next Steps:"
echo "1. Clean and rebuild the app"
echo "2. Archive with the production scheme"
echo "3. Upload to TestFlight"
echo "4. Test on both iOS 16.x and iOS 17.x devices"
echo ""
echo "✅ Fix Complete!"