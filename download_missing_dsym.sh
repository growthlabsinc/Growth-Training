#!/bin/bash

echo "📥 Download Missing dSYM for Version 1.1.0"
echo "==========================================="
echo ""
echo "Since version 1.1.0 was submitted to TestFlight/App Store,"
echo "you need to download the dSYM from App Store Connect:"
echo ""
echo "1. Go to: https://appstoreconnect.apple.com"
echo "2. Navigate to: My Apps → Growth: Method"
echo "3. Click on: TestFlight → Build 1.1.0 (1)"
echo "4. Under 'Build Metadata', click: Download dSYM"
echo "5. This will download a .zip file"
echo ""
echo "Once downloaded, run this command to upload it:"
echo ""
echo "  unzip ~/Downloads/dSYMs.zip -d ~/Downloads/"
echo "  ./upload_specific_dsym.sh ~/Downloads/dSYMs"
echo ""
echo "==========================================="
echo ""
echo "Alternatively, if you have the 1.1.0 archive locally:"
echo ""

# Search for 1.1.0 archives
echo "🔍 Searching for local 1.1.0 archives..."
ARCHIVES=$(find ~/Library/Developer/Xcode/Archives -name "*.xcarchive" -type d 2>/dev/null)

for archive in $ARCHIVES; do
    # Check Info.plist for version 1.1.0
    if [ -f "$archive/Info.plist" ]; then
        VERSION=$(/usr/libexec/PlistBuddy -c "Print :ApplicationProperties:CFBundleShortVersionString" "$archive/Info.plist" 2>/dev/null)
        if [ "$VERSION" = "1.1.0" ]; then
            echo "✅ Found 1.1.0 archive: $archive"
            DSYM_PATH="$archive/dSYMs/Growth.app.dSYM"
            if [ -d "$DSYM_PATH" ]; then
                echo "   dSYM path: $DSYM_PATH"
                echo ""
                echo "To upload this dSYM, run:"
                echo "  ./upload_specific_dsym.sh \"$DSYM_PATH\""
            fi
        fi
    fi
done

echo ""
echo "UUID needed: 82414719-9496-3F90-ADE5-780E3F3A7C38"