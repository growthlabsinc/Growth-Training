#!/bin/bash

cd /Users/tradeflowj/Desktop/Growth

# Set up environment
SDK_PATH=$(xcrun --show-sdk-path --sdk iphonesimulator)
TARGET="x86_64-apple-ios15.0-simulator"
FRAMEWORKS="-F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks"

echo "Testing compilation of key files..."

# Test main app file
echo "Testing GrowthAppApp.swift..."
xcrun swiftc -parse Growth/Application/GrowthAppApp.swift -sdk "$SDK_PATH" -target "$TARGET" $FRAMEWORKS -I Growth -import-objc-header Growth/Growth-Bridging-Header.h 2>&1 | grep -E "error:|warning:"

# Test MainView
echo "Testing MainView.swift..."
xcrun swiftc -parse Growth/MainView.swift -sdk "$SDK_PATH" -target "$TARGET" $FRAMEWORKS -I Growth 2>&1 | grep -E "error:|warning:"

# Test Settings Views
echo "Testing SettingsView.swift..."
xcrun swiftc -parse Growth/Features/Settings/SettingsView.swift -sdk "$SDK_PATH" -target "$TARGET" $FRAMEWORKS -I Growth 2>&1 | grep -E "error:|warning:"

echo "Done checking files."