#!/bin/bash

# Fix Widget Extension Archive Issues

echo "Fixing widget extension signing and build issues..."

# 1. Clean derived data
echo "Cleaning derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Growth-* 2>/dev/null || true

# 2. Clean build folder
echo "Cleaning build folder..."
xcodebuild clean -project Growth.xcodeproj -alltargets -configuration Release

# 3. Reset package cache
echo "Resetting Swift package cache..."
rm -rf .swiftpm
xcodebuild -resolvePackageDependencies -project Growth.xcodeproj

echo "✅ Cleanup complete!"
echo ""
echo "Next steps:"
echo "1. Configure GrowthTimerWidgetExtension signing:"
echo "   - Select widget target → Signing & Capabilities"
echo "   - Switch to Release configuration"
echo "   - Disable automatic signing"
echo "   - Create and select widget provisioning profile"
echo ""
echo "2. Check Build Settings for widget:"
echo "   - PRODUCT_MODULE_NAME should be different from main app"
echo "   - Ensure no duplicate module names"
echo ""
echo "3. Try archiving again"