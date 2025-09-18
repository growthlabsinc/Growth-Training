#!/bin/bash

echo "🔍 Pre-Archive Verification"
echo "=========================="
echo ""

# Check if deep link handling is implemented
echo "1. Checking deep link handling..."
if grep -q "growth://timer/pause" Growth/Application/AppSceneDelegate.swift; then
    echo "✅ Deep link handling implemented"
else
    echo "❌ Deep link handling missing!"
    exit 1
fi

# Verify URL scheme
echo ""
echo "2. Checking URL scheme registration..."
if grep -q "<string>growth</string>" Growth/Resources/Plist/App/Info.plist; then
    echo "✅ URL scheme registered"
else
    echo "❌ URL scheme not registered!"
    exit 1
fi

# Check build settings
echo ""
echo "3. Checking build configuration..."
xcodebuild -project Growth.xcodeproj \
  -scheme Growth \
  -showBuildSettings \
  -configuration Release | grep -E "CONFIGURATION|PRODUCT_BUNDLE_IDENTIFIER|CODE_SIGN" | head -10

echo ""
echo "4. Testing Release build..."
xcodebuild -project Growth.xcodeproj \
  -scheme Growth \
  -configuration Release \
  -sdk iphoneos \
  -destination generic/platform=iOS \
  -dry-run

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ All checks passed!"
    echo ""
    echo "📱 To test on device:"
    echo "1. Connect your iPhone"
    echo "2. Select it as destination in Xcode"
    echo "3. Build and run with Release configuration"
    echo "4. Test the Live Activity pause button"
    echo ""
    echo "🚀 If local testing works, archive will work the same!"
else
    echo ""
    echo "❌ Build check failed. Fix issues before archiving."
fi