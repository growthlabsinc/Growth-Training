#!/bin/bash

# Fix Build Conflicts for Growth App

echo "🔧 Fixing build conflicts..."

# 1. Clean all caches
echo "Cleaning all caches..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Growth-*
rm -rf .swiftpm
rm -rf ~/Library/Caches/org.swift.swiftpm

# 2. Reset package resolved
echo "Resetting Swift packages..."
rm -f Growth.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved

# 3. Clean SPM cache
echo "Cleaning Swift Package Manager cache..."
swift package purge-cache 2>/dev/null || true

echo "✅ Cleanup complete!"
echo ""
echo "⚠️  IMPORTANT: Widget Module Name Conflict"
echo ""
echo "The issue is that both the main app and widget are producing the same module name."
echo ""
echo "To fix in Xcode:"
echo "1. Select GrowthTimerWidgetExtension target"
echo "2. Go to Build Settings"
echo "3. Search for 'PRODUCT_MODULE_NAME'"
echo "4. Change it from 'Growth' to 'GrowthWidget'"
echo ""
echo "Also check:"
echo "- PRODUCT_NAME should be 'GrowthTimerWidget'"
echo "- Bundle Identifier should end with '.GrowthTimerWidget'"
echo ""
echo "After making these changes:"
echo "1. Close Xcode"
echo "2. Reopen the project"
echo "3. Product → Clean Build Folder"
echo "4. Try archiving again"