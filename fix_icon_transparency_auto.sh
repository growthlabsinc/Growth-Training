#!/bin/bash

echo "🔧 Auto-fixing app icon transparency..."

ICON_PATH="Growth/Assets.xcassets/AppIcon.appiconset/1024.png"

if [ -f "$ICON_PATH" ]; then
    echo "Found 1024x1024 icon at: $ICON_PATH"
    
    # Backup original
    cp "$ICON_PATH" "${ICON_PATH}.backup"
    echo "✅ Created backup: ${ICON_PATH}.backup"
    
    # Remove alpha channel using sips (built-in macOS tool)
    # Convert to JPEG to remove transparency, then back to PNG
    echo "🔄 Removing alpha channel..."
    sips -s format jpeg "$ICON_PATH" --out temp_icon.jpg
    sips -s format png temp_icon.jpg --out "$ICON_PATH"
    rm temp_icon.jpg
    
    # Verify the fix
    if sips -g hasAlpha "$ICON_PATH" | grep -q "hasAlpha: no"; then
        echo "✅ Successfully removed alpha channel!"
        
        # Now we need to clean and rebuild
        echo ""
        echo "🧹 Cleaning build folder..."
        rm -rf ~/Library/Developer/Xcode/DerivedData/Growth-*
        
        echo ""
        echo "✅ Icon fixed! Next steps:"
        echo "1. Open Xcode"
        echo "2. Clean Build Folder (Shift+Cmd+K)"
        echo "3. Archive again (Product > Archive)"
        echo "4. The IPA should now upload successfully to TestFlight"
        
    else
        echo "❌ Failed to remove alpha channel. Manual fix required."
        # Restore backup
        cp "${ICON_PATH}.backup" "$ICON_PATH"
    fi
else
    echo "❌ Icon not found at expected path"
fi