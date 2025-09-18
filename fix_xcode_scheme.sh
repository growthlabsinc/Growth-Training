#!/bin/bash

echo "🔧 Fixing Xcode Build Configuration"
echo "=================================="
echo ""

echo "The error shows: Build/Products/Release-iphoneos/Growth.app"
echo "This means Xcode is using Release configuration instead of Debug!"
echo ""

echo "📱 To fix this in Xcode:"
echo ""
echo "1. Click on the scheme (next to device selector)"
echo "2. Select 'Edit Scheme...'"
echo "3. In the left sidebar, select 'Run'"
echo "4. Change 'Build Configuration' from 'Release' to 'Debug'"
echo "5. Click 'Close'"
echo "6. Clean build folder (Shift+Cmd+K)"
echo "7. Run again"
echo ""

echo "Alternative quick fix:"
echo "1. In Xcode toolbar, look for 'Growth > Your iPhone'"
echo "2. Hold Option and click on it"
echo "3. Select 'Growth' (without 'Release')"
echo ""

echo "🎯 The correct configuration should be:"
echo "- Scheme: Growth"
echo "- Configuration: Debug (for local testing)"
echo "- Device: Your iPhone"
echo ""

# Also check current scheme settings
echo "Current build settings for verification:"
xcodebuild -project Growth.xcodeproj -scheme Growth -showBuildSettings | grep -E "CONFIGURATION|CODE_SIGN_STYLE" | grep -v EXPANDED | head -10