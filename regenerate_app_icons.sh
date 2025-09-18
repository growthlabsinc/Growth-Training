#!/bin/bash

# Script to regenerate all app icons from the source logo

ICON_DIR="Growth/Assets.xcassets/AppIcon.appiconset"
SOURCE_ICON="/tmp/new_logo_large.png"

# Function to create icon
create_icon() {
    local size=$1
    local filename=$2
    echo "Creating ${size}x${size} icon as ${filename}.png"
    
    python3 -c "
from PIL import Image

# Open source icon
img = Image.open('${SOURCE_ICON}')

# Resize to target size
img_resized = img.resize((${size}, ${size}), Image.Resampling.LANCZOS)

# Save
img_resized.save('${ICON_DIR}/${filename}.png')
print('Created ${filename}.png (${size}x${size})')
"
}

echo "Regenerating all app icons with new logo..."

# iPhone icons
create_icon 40 "40"
create_icon 60 "60"
create_icon 58 "58"
create_icon 87 "87"
create_icon 80 "80"
create_icon 120 "120"
create_icon 180 "180"

# iPad icons
create_icon 20 "20"
create_icon 29 "29"
create_icon 76 "76"
create_icon 152 "152"
create_icon 167 "167"

# Additional legacy icons
create_icon 50 "50"
create_icon 57 "57"
create_icon 72 "72"
create_icon 100 "100"
create_icon 114 "114"
create_icon 144 "144"

# App Store icon (1024x1024) - special handling to remove alpha
python3 -c "
from PIL import Image

# Open source icon
img = Image.open('${SOURCE_ICON}')

# Create 1024x1024 version
img_1024 = img.resize((1024, 1024), Image.Resampling.LANCZOS)

# Convert to RGB (remove alpha) for App Store
if img_1024.mode == 'RGBA':
    # Create background with the teal color
    background = Image.new('RGB', (1024, 1024), (10, 80, 66))
    # Paste the icon if it has transparency
    if img_1024.mode == 'RGBA':
        background.paste(img_1024, (0, 0), img_1024)
    else:
        background.paste(img_1024, (0, 0))
    img_1024 = background

img_1024.save('${ICON_DIR}/1024.png')
print('Created 1024.png (App Store icon)')
"

echo "✅ All app icons regenerated successfully!"