#!/bin/bash

echo "🔍 Diagnosing Signing Issue"
echo "=========================="
echo ""

# Check if we're using manual or automatic signing
echo "1️⃣ Checking current signing method..."
SIGNING_STYLE=$(xcodebuild -project Growth.xcodeproj -scheme Growth -showBuildSettings | grep "CODE_SIGN_STYLE" | grep -v "EXPANDED" | head -1 | awk '{print $3}')
echo "Current signing style: $SIGNING_STYLE"

# Check the profile being used
echo ""
echo "2️⃣ Checking provisioning profile..."
PROFILE=$(xcodebuild -project Growth.xcodeproj -scheme Growth -showBuildSettings | grep "PROVISIONING_PROFILE_SPECIFIER" | grep -v "EXPANDED" | head -1 | cut -d'=' -f2 | xargs)
echo "Profile name: $PROFILE"

# Check if it's a distribution profile
if [[ "$PROFILE" == *"Connect"* ]] || [[ "$PROFILE" == *"Distribution"* ]]; then
    echo "⚠️  You're using a Distribution profile!"
    echo "   This won't work for direct device installation."
fi

# Check device iOS version
echo ""
echo "3️⃣ Your device info from error:"
echo "- Model: iPhone 17,2 (iPhone 16 Pro)"
echo "- iOS: 18.5"
echo "- Architecture: arm64"

echo ""
echo "🔧 IMMEDIATE FIX:"
echo "==============="
echo ""
echo "For local testing, run this command:"
echo ""
echo "chmod +x switch_to_development_signing.rb && ./switch_to_development_signing.rb"
echo ""
echo "This will:"
echo "- Switch to automatic signing for Debug builds"
echo "- Keep manual signing for Release/Archive"
echo "- Allow you to test on your device"
echo ""
echo "After running the script:"
echo "1. Clean build folder in Xcode (Shift+Cmd+K)"
echo "2. Run on your device again"