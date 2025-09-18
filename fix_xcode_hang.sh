#!/bin/bash

echo "Emergency Xcode hang fix for Growth project..."
echo "========================================"

# 1. Force quit Xcode
echo "1. Force quitting Xcode..."
pkill -9 Xcode 2>/dev/null || true
pkill -9 "Interface Builder Cocoa Touch Tool" 2>/dev/null || true
pkill -9 com.apple.CoreSimulator.CoreSimulatorService 2>/dev/null || true

# 2. Clean all Xcode caches
echo "2. Cleaning Xcode caches..."
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf ~/Library/Caches/com.apple.dt.Xcode
rm -rf ~/Library/Saved\ Application\ State/com.apple.dt.Xcode.savedState
rm -rf ~/Library/Developer/Xcode/UserData/IDEEditorInteractivityHistory
rm -rf ~/Library/Developer/Xcode/UserData/Breakpoints/

# 3. Clean project-specific data
echo "3. Cleaning project-specific data..."
cd "$(dirname "$0")"
rm -rf Growth.xcodeproj/xcuserdata/
rm -rf Growth.xcodeproj/project.xcworkspace/xcuserdata/
rm -rf Growth.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/
rm -rf .swiftpm
rm -rf .build

# 4. Reset Swift Package Manager
echo "4. Resetting Swift Package Manager..."
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex

# 5. Clear simulator caches
echo "5. Clearing simulator caches..."
xcrun simctl delete all 2>/dev/null || true

# 6. Reset Xcode preferences (optional - uncomment if needed)
# echo "6. Resetting Xcode preferences..."
# defaults delete com.apple.dt.Xcode

echo ""
echo "Fix complete! Now try opening Xcode with:"
echo ""
echo "Option 1 - Safe mode (recommended):"
echo "  open -a Xcode --args -ApplePersistenceIgnoreState YES"
echo ""
echo "Option 2 - Normal mode:"
echo "  open -a Xcode"
echo ""
echo "Then manually open the project via File > Open"
echo ""
echo "If it still hangs, try:"
echo "1. Hold Shift while opening the project"
echo "2. Disable 'Restore State' in Xcode preferences"
echo "3. Open project.pbxproj in a text editor and check for corruption"