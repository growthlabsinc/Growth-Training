#!/bin/bash

# Fix unassigned asset images in Assets.xcassets

ASSETS_DIR="/Users/tradeflowj/Desktop/Dev/growth-backup-22aug2025/Growth/Assets.xcassets"

echo "Fixing unassigned asset images..."

# Find all imageset directories
find "$ASSETS_DIR" -name "*.imageset" -type d | while read -r imageset_dir; do
    contents_json="$imageset_dir/Contents.json"
    
    if [ -f "$contents_json" ]; then
        # Find image files in the directory (jpg, png, pdf)
        image_file=$(find "$imageset_dir" -maxdepth 1 \( -name "*.jpg" -o -name "*.png" -o -name "*.pdf" \) | head -1)
        
        if [ -n "$image_file" ]; then
            image_filename=$(basename "$image_file")
            
            # Check if filename is already in Contents.json
            if ! grep -q "\"filename\"" "$contents_json"; then
                echo "Fixing: $imageset_dir"
                
                # Update Contents.json to include the filename
                python3 -c "
import json
import sys

with open('$contents_json', 'r') as f:
    data = json.load(f)

# Add filename to the first image entry
if 'images' in data and len(data['images']) > 0:
    data['images'][0]['filename'] = '$image_filename'

with open('$contents_json', 'w') as f:
    json.dump(data, f, indent=2)
"
            fi
        fi
    fi
done

echo "Asset fix complete!"