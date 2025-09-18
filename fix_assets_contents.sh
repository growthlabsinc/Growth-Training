#!/bin/bash

# Script to fix missing Contents.json files in Assets.xcassets

SOURCE_ASSETS="/Users/tradeflowj/Desktop/Dev/growth-fresh/Growth/Assets.xcassets"
DEST_ASSETS="/Users/tradeflowj/Desktop/Dev/growth-backup-22aug2025/Growth/Assets.xcassets"

echo "Fixing Assets.xcassets Contents.json files..."

# Copy missing Contents.json files for imagesets that exist in backup but are missing Contents.json
declare -a imagesets=(
    "AppleIcon.imageset"
    "FacebookIcon.imageset"
    "GoogleLogo.imageset"
    "LaunchLogo.imageset"
    "Logo.imageset"
    "SplashBackground.imageset"
    "advanced-angion-vascion.imageset"
    "advanced_intensive_hero.imageset"
    "am1_0.imageset"
    "am2_0.imageset"
    "am2_5.imageset"
    "angio_pumping.imageset"
    "angion-method-evolving.imageset"
    "beginner_express_hero.imageset"
    "beginners-guide-angion-method.imageset"
    "beginners-guide-angion.imageset"
    "blood-vessel-growth-mechanisms.imageset"
    "day4_rest_hero.imageset"
    "hero_today.imageset"
    "holistic-male-health.imageset"
    "hydration_guide.imageset"
    "hydration_wellness.imageset"
    "intermediate-angion-2-0.imageset"
    "intermediate-angion-cardiovascular.imageset"
    "intermediate-angion-mastering.imageset"
    "intermediate-cardiovascular-training.imageset"
    "janus_hero.imageset"
    "nutrition_basics.imageset"
    "nutrition_wellness.imageset"
    "preparing-angion-foundations.imageset"
    "progression_timeline.imageset"
    "recovery_focus_hero.imageset"
    "recovery_wellness.imageset"
    "standard_routine_hero.imageset"
    "technique_guide.imageset"
    "training_hero.imageset"
    "two_week_transformation_hero.imageset"
    "vascular_basics.imageset"
    "waterfall-hero.imageset"
)

# Process imagesets
for imageset in "${imagesets[@]}"; do
    dest_imageset="$DEST_ASSETS/$imageset"
    
    # Check if imageset directory exists in destination
    if [ -d "$dest_imageset" ]; then
        # Check if Contents.json is missing
        if [ ! -f "$dest_imageset/Contents.json" ]; then
            # Try to find a matching imageset in source (handle slight naming differences)
            source_imageset="$SOURCE_ASSETS/$imageset"
            
            # Check for exact match first
            if [ -f "$source_imageset/Contents.json" ]; then
                echo "Copying Contents.json for $imageset"
                cp "$source_imageset/Contents.json" "$dest_imageset/"
            else
                # Try to find alternative naming in source
                base_name=$(echo "$imageset" | sed 's/.imageset$//')
                alt_name=$(echo "$base_name" | tr '_' '-')
                
                if [ -f "$SOURCE_ASSETS/${alt_name}.imageset/Contents.json" ]; then
                    echo "Copying Contents.json for $imageset (from ${alt_name}.imageset)"
                    cp "$SOURCE_ASSETS/${alt_name}.imageset/Contents.json" "$dest_imageset/"
                elif [ "$alt_name" != "$base_name" ]; then
                    # Try underscore version if original had dash
                    alt_name=$(echo "$base_name" | tr '-' '_')
                    if [ -f "$SOURCE_ASSETS/${alt_name}.imageset/Contents.json" ]; then
                        echo "Copying Contents.json for $imageset (from ${alt_name}.imageset)"
                        cp "$SOURCE_ASSETS/${alt_name}.imageset/Contents.json" "$dest_imageset/"
                    else
                        echo "Warning: Could not find source Contents.json for $imageset, creating generic one"
                        # Create a generic Contents.json
                        cat > "$dest_imageset/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "",
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
                fi
            fi
        else
            echo "Contents.json already exists for $imageset, skipping"
        fi
    fi
done

# Copy missing colorset Contents.json files
declare -a colorsets=(
    "AppPrimaryColor.colorset"
    "BackgroundColor.colorset"
    "BorderColor.colorset"
    "BrightTeal.colorset"
    "CardBackground.colorset"
    "CoreGreen.colorset"
    "ErrorColor.colorset"
    "FormSectionBackground.colorset"
    "GrowthBackgroundLight.colorset"
    "GrowthBlue.colorset"
    "GrowthGreen.colorset"
    "GrowthNeutralGray.colorset"
    "MintGreen.colorset"
    "NeutralGray.colorset"
    "PaleGreen.colorset"
    "PrimaryTextColor.colorset"
    "SuccessColor.colorset"
    "TextColor.colorset"
    "TextSecondaryColor.colorset"
)

for colorset in "${colorsets[@]}"; do
    dest_colorset="$DEST_ASSETS/$colorset"
    
    if [ -d "$dest_colorset" ]; then
        if [ ! -f "$dest_colorset/Contents.json" ]; then
            source_colorset="$SOURCE_ASSETS/$colorset"
            
            if [ -f "$source_colorset/Contents.json" ]; then
                echo "Copying Contents.json for $colorset"
                cp "$source_colorset/Contents.json" "$dest_colorset/"
            else
                echo "Warning: Could not find source Contents.json for $colorset, creating generic one"
                # Create a generic colorset Contents.json
                cat > "$dest_colorset/Contents.json" << 'EOF'
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0.500",
          "green" : "0.500",
          "red" : "0.500"
        }
      },
      "idiom" : "universal"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0.700",
          "green" : "0.700",
          "red" : "0.700"
        }
      },
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF
            fi
        else
            echo "Contents.json already exists for $colorset, skipping"
        fi
    fi
done

echo ""
echo "Completed fixing Assets.xcassets!"
echo "Next steps:"
echo "1. Open Xcode and verify the assets are now showing correctly"
echo "2. Clean build folder (Product > Clean Build Folder)"
echo "3. Build the project to ensure assets are properly recognized"