#!/bin/bash

# Source image
SOURCE_IMAGE="/Users/tradeflowj/Downloads/ChatGPT Image May 5, 2025, 12_57_04 PM.png"
DEST_DIR="Growth/Assets.xcassets/AppIcon.appiconset"

# App icon sizes needed for iOS
SIZES=(20 29 40 50 57 58 60 72 76 80 87 100 114 120 144 152 167 180 1024)

# Check if source image exists
if [ ! -f "$SOURCE_IMAGE" ]; then
    echo "Source image not found: $SOURCE_IMAGE"
    exit 1
fi

# Create app icons in all required sizes
for size in "${SIZES[@]}"; do
    echo "Generating $size x $size icon..."
    convert "$SOURCE_IMAGE" -resize ${size}x${size} "$DEST_DIR/${size}.png"
done

echo "App icons generated successfully!" 