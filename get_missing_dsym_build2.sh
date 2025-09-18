#!/bin/bash

echo "📥 Download Missing dSYM for Version 1.1.1 (Build 2)"
echo "===================================================="
echo ""
echo "UUID needed: F9183554-C8E6-3915-8713-0CEF7BE4460F"
echo ""
echo "Steps to download from App Store Connect:"
echo ""
echo "1. Go to: https://appstoreconnect.apple.com"
echo "2. Navigate to: My Apps → Growth: Method"
echo "3. Click on: TestFlight tab"
echo "4. Find: Version 1.1.1 (2) - Build 2"
echo "5. Click: Build Metadata → Download dSYM"
echo ""
echo "Once downloaded:"
echo "  unzip ~/Downloads/dSYMs.zip -d ~/Downloads/"
echo "  ./upload_specific_dsym.sh ~/Downloads/dSYMs"
echo ""
echo "===================================================="
echo ""
echo "Checking for local archive with build 2..."
echo ""

# Search for version 1.1.1 build 2 in local archives
ARCHIVES=$(find ~/Library/Developer/Xcode/Archives -name "*.xcarchive" -type d 2>/dev/null)

for archive in $ARCHIVES; do
    if [ -f "$archive/Info.plist" ]; then
        VERSION=$(/usr/libexec/PlistBuddy -c "Print :ApplicationProperties:CFBundleShortVersionString" "$archive/Info.plist" 2>/dev/null)
        BUILD=$(/usr/libexec/PlistBuddy -c "Print :ApplicationProperties:CFBundleVersion" "$archive/Info.plist" 2>/dev/null)
        
        if [ "$VERSION" = "1.1.1" ] && [ "$BUILD" = "2" ]; then
            echo "✅ Found local archive for 1.1.1 (2):"
            echo "   $archive"
            
            DSYM_PATH="$archive/dSYMs/Growth.app.dSYM"
            if [ -d "$DSYM_PATH" ]; then
                # Check UUID
                UUID=$(dwarfdump -u "$DSYM_PATH" 2>/dev/null | grep "UUID:" | head -1 | awk '{print $2}')
                echo "   dSYM UUID: $UUID"
                
                if [[ "$UUID" == *"F9183554"* ]]; then
                    echo ""
                    echo "✅ This is the correct dSYM! Upload it with:"
                    echo "   ./upload_specific_dsym.sh \"$DSYM_PATH\""
                else
                    echo "   ⚠️  UUID doesn't match. This might be a different build."
                fi
            fi
        fi
    fi
done

echo ""
echo "===================================================="
echo "Note: Build 2 is different from Build 1"
echo "Make sure to get the correct build's dSYM"