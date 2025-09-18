#!/bin/bash

echo "Clearing Launch Screen Cache..."
echo "================================"

# Clean DerivedData
echo "1. Cleaning DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Growth-*

# Clean device support files
echo "2. Cleaning device support files..."
rm -rf ~/Library/Developer/Xcode/iOS\ DeviceSupport/*

# Clean simulator caches if testing on simulator
echo "3. Cleaning simulator caches..."
xcrun simctl shutdown all 2>/dev/null
xcrun simctl erase all 2>/dev/null

echo ""
echo "Launch screen cache cleared!"
echo ""
echo "Next steps:"
echo "1. Delete the app from your device/simulator"
echo "2. Clean Build Folder in Xcode (Cmd+Shift+K)"
echo "3. Build and run the app again"
echo ""
echo "If the issue persists on a physical device:"
echo "- Go to Settings > General > iPhone Storage"
echo "- Find your app and delete it"
echo "- Restart your device"
echo "- Reinstall the app"