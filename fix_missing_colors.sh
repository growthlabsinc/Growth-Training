#!/bin/bash

# Script to fix missing color assets

ASSETS_DIR="Growth/Assets.xcassets"

# Function to write single color JSON
write_single_color() {
    local colorset_name="$1"
    local hex="$2"
    
    # Extract RGB values from hex
    r=$(printf "%d" 0x${hex:0:2})
    g=$(printf "%d" 0x${hex:2:2})
    b=$(printf "%d" 0x${hex:4:2})
    
    cat > "$ASSETS_DIR/${colorset_name}.colorset/Contents.json" <<EOF
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "$(printf '0x%02X' $b)",
          "green" : "$(printf '0x%02X' $g)",
          "red" : "$(printf '0x%02X' $r)"
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
    echo "✓ Created ${colorset_name}"
}

# Function to write color with dark mode
write_color() {
    local colorset_name="$1"
    local light_hex="$2"
    local dark_hex="$3"
    
    # Extract RGB values from hex
    light_r=$(printf "%d" 0x${light_hex:0:2})
    light_g=$(printf "%d" 0x${light_hex:2:2})
    light_b=$(printf "%d" 0x${light_hex:4:2})
    
    dark_r=$(printf "%d" 0x${dark_hex:0:2})
    dark_g=$(printf "%d" 0x${dark_hex:2:2})
    dark_b=$(printf "%d" 0x${dark_hex:4:2})
    
    cat > "$ASSETS_DIR/${colorset_name}.colorset/Contents.json" <<EOF
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "$(printf '0x%02X' $light_b)",
          "green" : "$(printf '0x%02X' $light_g)",
          "red" : "$(printf '0x%02X' $light_r)"
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
          "blue" : "$(printf '0x%02X' $dark_b)",
          "green" : "$(printf '0x%02X' $dark_g)",
          "red" : "$(printf '0x%02X' $dark_r)"
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
    echo "✓ Created ${colorset_name}"
}

echo "Creating missing color assets..."

# BorderColor - Light gray for borders
write_color "BorderColor" "E0E0E0" "424242"

# CardBackground - Using surface white colors from AppColors
write_color "CardBackground" "FFFFFF" "263A36"

# CoreGreen - Same as GrowthGreen/AppPrimaryColor
write_color "CoreGreen" "0A5042" "26A69A"

# DarkText - Primary text color
write_color "DarkText" "212121" "F5F5F5"

# GrowthBlue - A complementary blue color
write_single_color "GrowthBlue" "1976D2"

echo ""
echo "✅ All missing color assets have been created!"
echo ""
echo "New colors added:"
echo "  • BorderColor: #E0E0E0 (light) / #424242 (dark)"
echo "  • CardBackground: #FFFFFF (light) / #263A36 (dark)"
echo "  • CoreGreen: #0A5042 (light) / #26A69A (dark)"
echo "  • DarkText: #212121 (light) / #F5F5F5 (dark)"
echo "  • GrowthBlue: #1976D2"