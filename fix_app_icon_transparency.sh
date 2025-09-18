#!/bin/bash

echo "🔍 Checking for app icon with transparency..."

# Find Assets.xcassets
ASSETS_PATH="Growth/Assets.xcassets"

if [ -d "$ASSETS_PATH" ]; then
    echo "Found Assets at: $ASSETS_PATH"
    
    # Look for AppIcon
    ICON_PATH="$ASSETS_PATH/AppIcon.appiconset"
    
    if [ -d "$ICON_PATH" ]; then
        echo "Found AppIcon at: $ICON_PATH"
        echo ""
        echo "App icons in this directory:"
        ls -la "$ICON_PATH"/*.png 2>/dev/null || echo "No PNG files found"
        
        echo ""
        echo "Checking for 1024x1024 icon..."
        
        # Common names for 1024x1024 icons
        for icon in "$ICON_PATH"/*1024*.png "$ICON_PATH"/*ios-marketing*.png; do
            if [ -f "$icon" ]; then
                echo ""
                echo "Found potential App Store icon: $(basename "$icon")"
                
                # Check if it has alpha channel using sips
                if sips -g hasAlpha "$icon" | grep -q "hasAlpha: yes"; then
                    echo "❌ This icon HAS ALPHA CHANNEL (transparency)"
                    echo ""
                    echo "To fix this icon:"
                    echo "1. Open it in Preview or image editor"
                    echo "2. Add a solid background color"
                    echo "3. Export without transparency"
                    echo "4. Replace in Xcode"
                else
                    echo "✅ This icon has no alpha channel"
                fi
            fi
        done
    else
        echo "❌ AppIcon.appiconset not found"
    fi
else
    echo "❌ Assets.xcassets not found at expected path"
    echo "Searching for Assets.xcassets..."
    find . -name "Assets.xcassets" -type d 2>/dev/null
fi

echo ""
echo "📝 To fix the transparency issue:"
echo "1. Open the 1024x1024 icon in an image editor"
echo "2. If it has transparency, add a solid background"
echo "3. Save as PNG without alpha or as JPEG"
echo "4. Replace in Xcode's Assets.xcassets"
echo "5. Clean build folder (Shift+Cmd+K)"
echo "6. Archive again"