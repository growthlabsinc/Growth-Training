#!/bin/bash

# Fix entitlements path issue after iCloud sync

echo "Fixing entitlements path issue..."

# Clean derived data
echo "Cleaning derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Growth-*

# Remove xcuserdata which might contain stale paths
echo "Removing user-specific data..."
rm -rf Growth.xcodeproj/xcuserdata/
rm -rf Growth.xcodeproj/project.xcworkspace/xcuserdata/

# Create a symbolic link as a temporary workaround if needed
if [ ! -f "/Users/tradeflowj/iCloud Drive (Archive)/Desktop/Growth/Growth/Growth.entitlements" ]; then
    echo "Creating directory structure for compatibility..."
    mkdir -p "/Users/tradeflowj/iCloud Drive (Archive)/Desktop/Growth/Growth/"
    ln -sf "/Users/tradeflowj/Desktop/Growth/Growth/Growth.entitlements" "/Users/tradeflowj/iCloud Drive (Archive)/Desktop/Growth/Growth/Growth.entitlements"
fi

echo "Done! Now try these steps:"
echo "1. Close Xcode completely"
echo "2. Open Xcode and open the project from: /Users/tradeflowj/Desktop/Growth/Growth.xcodeproj"
echo "3. Clean build folder: Product > Clean Build Folder (Cmd+Shift+K)"
echo "4. Try building again"