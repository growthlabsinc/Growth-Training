#!/bin/bash

echo "Cleaning Xcode build artifacts..."

# Clean build folder
echo "Cleaning build folder..."
xcodebuild clean -workspace Growth.xcworkspace -scheme Growth -configuration Debug 2>/dev/null || true
xcodebuild clean -project Growth.xcodeproj -scheme Growth -configuration Debug 2>/dev/null || true

# Remove derived data
echo "Removing DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Growth-*

# Clean module cache
echo "Cleaning module cache..."
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex

# Clean build intermediates
echo "Cleaning build intermediates..."
rm -rf build/
rm -rf Build/

echo "Build cleaning complete!"
echo ""
echo "Next steps:"
echo "1. Open Xcode"
echo "2. Press Cmd+Shift+K to clean"
echo "3. Press Cmd+B to rebuild"