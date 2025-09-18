#!/bin/bash

# Script to fix all color assets in Growth app

ASSETS_DIR="/Users/tradeflowj/Desktop/Dev/growth-backup-22aug2025/Growth/Assets.xcassets"

# Function to write color JSON
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
    
    # Convert to 0-1 range for color components
    light_r_norm=$(echo "scale=3; $light_r / 255" | bc)
    light_g_norm=$(echo "scale=3; $light_g / 255" | bc)
    light_b_norm=$(echo "scale=3; $light_b / 255" | bc)
    
    dark_r_norm=$(echo "scale=3; $dark_r / 255" | bc)
    dark_g_norm=$(echo "scale=3; $dark_g / 255" | bc)
    dark_b_norm=$(echo "scale=3; $dark_b / 255" | bc)
    
    cat > "$ASSETS_DIR/${colorset_name}.colorset/Contents.json" <<EOF
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "$light_b_norm",
          "green" : "$light_g_norm",
          "red" : "$light_r_norm"
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
          "blue" : "$dark_b_norm",
          "green" : "$dark_g_norm",
          "red" : "$dark_r_norm"
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
    echo "✓ Fixed ${colorset_name}"
}

# Function to write single color JSON (no dark mode variant)
write_single_color() {
    local colorset_name="$1"
    local hex="$2"
    
    # Extract RGB values from hex
    r=$(printf "%d" 0x${hex:0:2})
    g=$(printf "%d" 0x${hex:2:2})
    b=$(printf "%d" 0x${hex:4:2})
    
    # Convert to 0-1 range for color components
    r_norm=$(echo "scale=3; $r / 255" | bc)
    g_norm=$(echo "scale=3; $g / 255" | bc)
    b_norm=$(echo "scale=3; $b / 255" | bc)
    
    cat > "$ASSETS_DIR/${colorset_name}.colorset/Contents.json" <<EOF
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "$b_norm",
          "green" : "$g_norm",
          "red" : "$r_norm"
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
    echo "✓ Fixed ${colorset_name}"
}

echo "Fixing color assets..."

# Primary colors (already fixed but ensuring consistency)
write_color "GrowthGreen" "0A5042" "26A69A"
write_color "AppPrimaryColor" "0A5042" "26A69A"

# Background colors
write_color "BackgroundColor" "F8FAFA" "1A2A27"
write_color "GrowthBackgroundLight" "F8FAFA" "1A2A27"

# Text colors
write_color "TextColor" "212121" "F5F5F5"
write_color "TextSecondaryColor" "9E9E9E" "B0BEC5"

# Neutral colors
write_color "NeutralGray" "9E9E9E" "9E9E9E"
write_color "GrowthNeutralGray" "9E9E9E" "9E9E9E"

# Accent colors
write_single_color "BrightTeal" "00BFA5"
write_single_color "MintGreen" "4CAF92"
write_color "PaleGreen" "E6F4F0" "1F3A36"

# Functional colors
write_single_color "SuccessColor" "43A047"
write_single_color "ErrorColor" "E53935"

# Accent color (using Bright Teal)
write_single_color "AccentColor" "00BFA5"

echo ""
echo "✅ All color assets have been fixed!"
echo ""
echo "Colors configured:"
echo "  • GrowthGreen: #0A5042 (light) / #26A69A (dark)"
echo "  • AppPrimaryColor: #0A5042 (light) / #26A69A (dark)"
echo "  • BackgroundColor: #F8FAFA (light) / #1A2A27 (dark)"
echo "  • TextColor: #212121 (light) / #F5F5F5 (dark)"
echo "  • TextSecondaryColor: #9E9E9E (light) / #B0BEC5 (dark)"
echo "  • BrightTeal: #00BFA5"
echo "  • MintGreen: #4CAF92"
echo "  • PaleGreen: #E6F4F0 (light) / #1F3A36 (dark)"
echo "  • SuccessColor: #43A047"
echo "  • ErrorColor: #E53935"
echo "  • AccentColor: #00BFA5"