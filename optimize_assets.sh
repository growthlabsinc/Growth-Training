#!/bin/bash

echo "🖼️ Optimizing large images in Assets.xcassets..."

# Find all images larger than 1MB and optimize them
find Growth/Assets.xcassets -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \) -size +1M | while read file; do
    size_before=$(ls -lh "$file" | awk '{print $5}')
    filename=$(basename "$file")
    extension="${filename##*.}"
    
    echo "Processing: $file (${size_before})"
    
    # Create backup
    cp "$file" "${file}.backup"
    
    # Optimize based on file type
    if [[ "$extension" == "png" ]]; then
        # For PNG files, use sips to resize if too large
        width=$(sips -g pixelWidth "$file" | awk '/pixelWidth:/{print $2}')
        if [ "$width" -gt 2048 ]; then
            sips -Z 2048 "$file" >/dev/null 2>&1
        fi
    else
        # For JPEG files, reduce quality and resize if needed
        width=$(sips -g pixelWidth "$file" | awk '/pixelWidth:/{print $2}')
        if [ "$width" -gt 2048 ]; then
            sips -Z 2048 "$file" >/dev/null 2>&1
        fi
        # Re-compress with 85% quality
        sips -s format jpeg -s formatOptions 85 "$file" --out "$file" >/dev/null 2>&1
    fi
    
    size_after=$(ls -lh "$file" | awk '{print $5}')
    echo "  ✓ Optimized to: ${size_after}"
done

echo "✅ Asset optimization complete!"
echo ""
echo "⚠️  Note: Backup files created with .backup extension"
echo "   If images look good, you can remove backups with:"
echo "   find Growth/Assets.xcassets -name '*.backup' -delete"