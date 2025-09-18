#!/bin/bash

echo "🔧 Fixing Beta Profile Installation Error"
echo "======================================="
echo ""

# Check current signing configuration
echo "1️⃣ Current signing configuration:"
xcodebuild -project Growth.xcodeproj \
  -scheme Growth \
  -showBuildSettings | grep -E "CODE_SIGN|PROVISIONING_PROFILE|DEVELOPMENT_TEAM" | head -20

echo ""
echo "2️⃣ Available provisioning profiles:"
ls -la ~/Library/MobileDevice/Provisioning\ Profiles/*.mobileprovision 2>/dev/null | wc -l
echo "profiles found"

echo ""
echo "3️⃣ The error means:"
echo "- You're using a Beta/Development profile"
echo "- Your device expects a Distribution profile"
echo "- Or the profile doesn't match the device's capabilities"

echo ""
echo "🔧 SOLUTIONS:"
echo ""
echo "Option 1: Use Automatic Signing (Recommended for local testing)"
echo "--------------------------------------------------------"
echo "1. Open Xcode"
echo "2. Select your project"
echo "3. Go to Signing & Capabilities"
echo "4. Check 'Automatically manage signing'"
echo "5. Select your team"
echo "6. Run again"

echo ""
echo "Option 2: Install via TestFlight (Your current setup)"
echo "---------------------------------------------------"
echo "1. Archive the app (Product > Archive)"
echo "2. Upload to App Store Connect"
echo "3. Install via TestFlight on your device"
echo ""
echo "This uses your Distribution profiles which are already configured."

echo ""
echo "Option 3: Switch to Development Profile for Local Testing"
echo "-------------------------------------------------------"
echo "Run this Ruby script to switch to development signing:"
echo "./switch_to_development_signing.rb"