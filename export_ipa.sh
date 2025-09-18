#!/bin/bash

echo "🚀 Alternative IPA Export Method"
echo ""

# Find latest archive
ARCHIVE=$(find ~/Library/Developer/Xcode/Archives -name "*.xcarchive" -type d | sort -r | head -n 1)
echo "Found archive: $(basename "$ARCHIVE")"

# Create a simple export options for development
cat > ExportOptions-Dev.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>teamID</key>
    <string>62T6J77P6R</string>
</dict>
</plist>
EOF

# Try development export first
echo ""
echo "Attempting development export..."
EXPORT_PATH="$HOME/Desktop/GrowthExport_Dev"
rm -rf "$EXPORT_PATH"

xcodebuild -exportArchive \
    -archivePath "$ARCHIVE" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist ExportOptions-Dev.plist

if [ $? -eq 0 ]; then
    echo "✅ Development export successful!"
    echo "IPA location: $EXPORT_PATH"
    open "$EXPORT_PATH"
else
    echo "❌ Development export also failed"
    
    # Try to extract IPA manually
    echo ""
    echo "Attempting manual IPA extraction..."
    
    # Create directory
    MANUAL_EXPORT="$HOME/Desktop/GrowthManualExport"
    rm -rf "$MANUAL_EXPORT"
    mkdir -p "$MANUAL_EXPORT"
    
    # Copy the app from archive
    cp -R "$ARCHIVE/Products/Applications/Growth.app" "$MANUAL_EXPORT/"
    
    # Create Payload directory
    mkdir "$MANUAL_EXPORT/Payload"
    mv "$MANUAL_EXPORT/Growth.app" "$MANUAL_EXPORT/Payload/"
    
    # Create IPA
    cd "$MANUAL_EXPORT"
    zip -r Growth.ipa Payload
    
    echo "✅ Manual IPA created at: $MANUAL_EXPORT/Growth.ipa"
    echo ""
    echo "To upload this IPA:"
    echo "1. Download 'Transporter' from Mac App Store"
    echo "2. Open Transporter and sign in"
    echo "3. Drag $MANUAL_EXPORT/Growth.ipa to Transporter"
    
    open "$MANUAL_EXPORT"
fi