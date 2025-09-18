#!/bin/bash

echo "Growth App Installation Conflict Fixer"
echo "======================================"
echo ""
echo "This error occurs when the App Store/TestFlight version conflicts with Xcode development build."
echo ""
echo "Choose a solution:"
echo "1) Delete app from device (Recommended for testing)"
echo "2) Use development bundle ID (com.growthlabs.growthmethod.dev)"
echo "3) Increment build number"
echo "4) Clean build folder and retry"
echo ""
read -p "Enter your choice (1-4): " choice

case $choice in
    1)
        echo ""
        echo "Please delete the Growth app from your device:"
        echo "1. On your iPhone, find the 'Growth' app"
        echo "2. Long press the app icon"
        echo "3. Tap 'Remove App' → 'Delete App'"
        echo "4. Try running from Xcode again"
        echo ""
        echo "Press Enter after deleting the app to continue..."
        read
        ;;
    
    2)
        echo ""
        echo "Changing to development bundle ID..."
        # This would require modifying the project file
        echo "To use a development bundle ID:"
        echo "1. Open Growth.xcodeproj in Xcode"
        echo "2. Select the Growth target"
        echo "3. Go to Signing & Capabilities"
        echo "4. Change Bundle Identifier to: com.growthlabs.growthmethod.dev"
        echo "5. Do the same for the Widget Extension target"
        echo ""
        ;;
    
    3)
        echo ""
        echo "Incrementing build number..."
        current_build=$(defaults read "$PWD/Growth/Resources/Plist/App/Info.plist" CFBundleVersion 2>/dev/null || echo "1")
        new_build=$((current_build + 1))
        echo "Current build: $current_build"
        echo "New build: $new_build"
        
        # Update Info.plist
        /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $new_build" "$PWD/Growth/Resources/Plist/App/Info.plist"
        echo "Build number updated to $new_build"
        echo ""
        echo "Now clean and rebuild in Xcode"
        ;;
    
    4)
        echo ""
        echo "Cleaning build folder..."
        rm -rf ~/Library/Developer/Xcode/DerivedData/Growth-*
        echo "Build folder cleaned."
        echo ""
        echo "Now try these steps:"
        echo "1. In Xcode: Product → Clean Build Folder (⇧⌘K)"
        echo "2. Restart Xcode"
        echo "3. Delete the app from your device if it's installed"
        echo "4. Try running again"
        ;;
    
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

echo ""
echo "If the issue persists, try:"
echo "- Restarting your iPhone"
echo "- Restarting Xcode"
echo "- Using a different device for testing"
echo "- Checking your provisioning profiles in Xcode settings"