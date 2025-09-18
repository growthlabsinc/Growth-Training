#!/bin/bash

echo "🚀 TestFlight Export Script"
echo "=========================="
echo ""

# Clean and archive
echo "📦 Step 1: Building and archiving..."
xcodebuild -project Growth.xcodeproj \
    -scheme Growth \
    -configuration Release \
    -archivePath ~/Library/Developer/Xcode/Archives/GrowthTestFlight.xcarchive \
    archive

if [ $? -eq 0 ]; then
    echo "✅ Archive successful!"
    
    # Export for TestFlight
    echo ""
    echo "📤 Step 2: Exporting for TestFlight..."
    
    # Create TestFlight export options
    cat > ExportOptions-TestFlight.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>62T6J77P6R</string>
    <key>uploadSymbols</key>
    <true/>
    <key>generateAppStoreInformation</key>
    <false/>
    <key>provisioningProfiles</key>
    <dict>
        <key>com.growthlabs.growthmethod</key>
        <string>Growth Labs Connect</string>
        <key>com.growthlabs.growthmethod.GrowthTimerWidget</key>
        <string>Growth Labs Widget Connect</string>
    </dict>
</dict>
</plist>
EOF
    
    EXPORT_DIR="$HOME/Desktop/GrowthTestFlight_$(date +%Y%m%d_%H%M%S)"
    
    xcodebuild -exportArchive \
        -archivePath ~/Library/Developer/Xcode/Archives/GrowthTestFlight.xcarchive \
        -exportPath "$EXPORT_DIR" \
        -exportOptionsPlist ExportOptions-TestFlight.plist
    
    if [ $? -eq 0 ]; then
        echo "✅ Export successful!"
        echo ""
        echo "📱 IPA ready for TestFlight at:"
        echo "$EXPORT_DIR/Growth.ipa"
        echo ""
        echo "🚀 To upload to TestFlight:"
        echo "1. Open Transporter app"
        echo "2. Sign in with your Apple ID (jon@growthlabs.coach)"
        echo "3. Drag the IPA file to Transporter"
        echo "4. Click 'Deliver'"
        echo ""
        echo "After upload completes:"
        echo "- Wait 5-10 minutes for processing"
        echo "- Check App Store Connect > TestFlight"
        echo "- Add testers and start testing!"
        
        open "$EXPORT_DIR"
    else
        echo "❌ Export failed. Trying manual extraction..."
        
        # Manual IPA creation as fallback
        MANUAL_DIR="$HOME/Desktop/GrowthTestFlightManual"
        rm -rf "$MANUAL_DIR"
        mkdir -p "$MANUAL_DIR/Payload"
        
        cp -R ~/Library/Developer/Xcode/Archives/GrowthTestFlight.xcarchive/Products/Applications/Growth.app "$MANUAL_DIR/Payload/"
        
        cd "$MANUAL_DIR"
        zip -r Growth.ipa Payload
        
        echo "✅ Manual IPA created at: $MANUAL_DIR/Growth.ipa"
        open "$MANUAL_DIR"
    fi
else
    echo "❌ Archive failed. Please check Xcode for errors."
fi