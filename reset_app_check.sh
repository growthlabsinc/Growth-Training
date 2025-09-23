#!/bin/bash

echo "🧹 Resetting App Check and clearing caches..."

# Kill simulator if running
echo "Closing simulator..."
killall Simulator 2>/dev/null || true

# Clear derived data
echo "Clearing Xcode derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Clear simulator device data
echo "Resetting simulator..."
xcrun simctl shutdown all
xcrun simctl erase all

echo "✅ Reset complete!"
echo ""
echo "Next steps:"
echo "1. Open Xcode"
echo "2. Clean Build Folder (⌘+Shift+K)"
echo "3. Build and Run (⌘+R)"
echo ""
echo "The app will generate a new App Check debug token on first launch."
echo "You'll need to register the new token in Firebase Console."