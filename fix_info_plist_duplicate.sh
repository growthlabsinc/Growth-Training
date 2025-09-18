#!/bin/bash

echo "=== Fixing Info.plist Duplicate Issue ==="
echo ""

# Check if duplicate exists
if [ -f "/Users/tradeflowj/Desktop/Growth/Growth/Info.plist" ]; then
    echo "Found duplicate Info.plist at root of Growth directory"
    echo "The correct Info.plist is at: Growth/Resources/Plist/App/Info.plist"
    echo ""
    echo "Removing duplicate..."
    rm "/Users/tradeflowj/Desktop/Growth/Growth/Info.plist"
    echo "✅ Duplicate removed"
else
    echo "No duplicate Info.plist found at Growth root"
fi

echo ""
echo "Cleaning DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Growth-*
echo "✅ DerivedData cleaned"

echo ""
echo "=== Next Steps ==="
echo "1. Open Growth.xcodeproj in Xcode"
echo "2. Select the Growth project in navigator"
echo "3. Select the Growth target"
echo "4. Go to Build Settings tab"
echo "5. Search for 'Info.plist'"
echo "6. Ensure 'Info.plist File' is set to: Growth/Resources/Plist/App/Info.plist"
echo ""
echo "7. Go to Build Phases tab"
echo "8. Expand 'Copy Bundle Resources'"
echo "9. Remove any Info.plist entries (they shouldn't be in resources)"
echo ""
echo "10. Clean Build Folder (Cmd+Shift+K)"
echo "11. Build (Cmd+B)"