#!/bin/bash

# Script to fix asset references in Contents.json files

ASSETS_DIR="/Users/tradeflowj/Desktop/Dev/growth-backup-22aug2025/Growth/Assets.xcassets"

echo "Fixing asset references in Contents.json files..."

# Fix AppIcon.appiconset
if [ -f "$ASSETS_DIR/AppIcon.appiconset/Contents.json" ]; then
    echo "Fixing AppIcon.appiconset..."
    cat > "$ASSETS_DIR/AppIcon.appiconset/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "40.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "60.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20"
    },
    {
      "filename" : "58.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "87.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29"
    },
    {
      "filename" : "80.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "120.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "filename" : "120.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "filename" : "180.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "filename" : "20.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "20x20"
    },
    {
      "filename" : "40.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "29.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "29x29"
    },
    {
      "filename" : "58.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "40.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "40x40"
    },
    {
      "filename" : "80.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "76.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "76x76"
    },
    {
      "filename" : "152.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "76x76"
    },
    {
      "filename" : "167.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "83.5x83.5"
    },
    {
      "filename" : "1024.png",
      "idiom" : "ios-marketing",
      "scale" : "1x",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF
fi

# Function to fix imageset with single image
fix_single_image_set() {
    local imageset_name="$1"
    local image_filename="$2"
    
    if [ -d "$ASSETS_DIR/$imageset_name" ]; then
        echo "Fixing $imageset_name..."
        cat > "$ASSETS_DIR/$imageset_name/Contents.json" << EOF
{
  "images" : [
    {
      "filename" : "$image_filename",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "idiom" : "universal",
      "scale" : "3x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF
    fi
}

# Fix individual imagesets
fix_single_image_set "AppleIcon.imageset" "icon.png"
fix_single_image_set "Logo.imageset" "app_logo.png"
fix_single_image_set "SplashBackground.imageset" "splash.png"
fix_single_image_set "advanced_intensive_hero.imageset" "advanced_intensive_hero.jpg"
fix_single_image_set "beginners-guide-angion.imageset" "beginners-guide-angion.jpg"
fix_single_image_set "day4_rest_hero.imageset" "day4_rest_hero.jpg"
fix_single_image_set "hero_today.imageset" "hero_today.jpg"
fix_single_image_set "hydration_guide.imageset" "hydration_guide.jpg"
fix_single_image_set "intermediate-angion-2-0.imageset" "intermediate-angion-2-0.jpg"
fix_single_image_set "intermediate-cardiovascular-training.imageset" "intermediate-cardiovascular-training.jpg"
fix_single_image_set "janus_hero.imageset" "janus_hero.jpg"
fix_single_image_set "nutrition_basics.imageset" "nutrition_basics.jpg"
fix_single_image_set "nutrition_wellness.imageset" "nutrition_basics.jpg"
fix_single_image_set "recovery_focus_hero.imageset" "recovery_focus_hero.jpg"
fix_single_image_set "recovery_wellness.imageset" "vascular_basics.jpg"
fix_single_image_set "standard_routine_hero.imageset" "standard_routine_hero.jpg"
fix_single_image_set "technique_guide.imageset" "technique_guide.jpg"
fix_single_image_set "training_hero.imageset" "training_hero.jpg"
fix_single_image_set "two_week_transformation_hero.imageset" "two_week_transformation_hero.jpg"
fix_single_image_set "vascular_basics.imageset" "vascular_basics.jpg"
fix_single_image_set "waterfall-hero.imageset" "waterfall-hero.jpg"

echo ""
echo "Asset references have been fixed!"
echo "Please clean build folder and rebuild the project in Xcode."