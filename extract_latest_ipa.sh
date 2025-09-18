#!/bin/bash

echo "🚀 Extracting IPA from latest archive..."

# Find latest archive with proper escaping
ARCHIVE=$(find ~/Library/Developer/Xcode/Archives -name "*.xcarchive" -type d -print0 | xargs -0 ls -dt | head -n 1)

if [ -z "$ARCHIVE" ]; then
    echo "❌ No archive found"
    exit 1
fi

echo "📦 Found archive: $(basename "$ARCHIVE")"

# Create export directory
EXPORT_DIR="$HOME/Desktop/Growth_TestFlight_IPA"
rm -rf "$EXPORT_DIR"
mkdir -p "$EXPORT_DIR/Payload"

# Find and copy the app bundle
APP_PATH=$(find "$ARCHIVE" -name "Growth.app" -type d | head -n 1)

if [ -n "$APP_PATH" ]; then
    echo "📱 Found app at: $(basename "$APP_PATH")"
    cp -R "$APP_PATH" "$EXPORT_DIR/Payload/"
    
    # Create IPA
    cd "$EXPORT_DIR"
    zip -qr Growth.ipa Payload
    
    # Get file size
    SIZE=$(ls -lh Growth.ipa | awk '{print $5}')
    
    echo ""
    echo "✅ SUCCESS! IPA created"
    echo "📍 Location: $EXPORT_DIR/Growth.ipa"
    echo "📦 Size: $SIZE"
    echo ""
    echo "🚀 Ready for TestFlight upload via Transporter!"
    
    # Open the directory
    open .
else
    echo "❌ Could not find Growth.app in archive"
    echo "Archive contents:"
    find "$ARCHIVE" -type d -name "*.app"
fi