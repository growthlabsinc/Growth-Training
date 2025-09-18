#!/bin/bash

# Script to fix remaining imageset Contents.json files with proper filenames

DEST_ASSETS="/Users/tradeflowj/Desktop/Dev/growth-backup-22aug2025/Growth/Assets.xcassets"

echo "Fixing remaining imagesets with proper Contents.json files..."

# LaunchLogo imageset
if [ -d "$DEST_ASSETS/LaunchLogo.imageset" ] && [ ! -f "$DEST_ASSETS/LaunchLogo.imageset/Contents.json" ]; then
    echo "Creating Contents.json for LaunchLogo.imageset"
    cat > "$DEST_ASSETS/LaunchLogo.imageset/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "launch_logo@1x.png",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "filename" : "launch_logo@2x.png",
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "filename" : "launch_logo@3x.png",
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

# advanced-angion-vascion imageset
if [ -d "$DEST_ASSETS/advanced-angion-vascion.imageset" ] && [ ! -f "$DEST_ASSETS/advanced-angion-vascion.imageset/Contents.json" ]; then
    echo "Creating Contents.json for advanced-angion-vascion.imageset"
    cat > "$DEST_ASSETS/advanced-angion-vascion.imageset/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "advanced-angion-vascion.jpg",
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

# angion-method-evolving imageset
if [ -d "$DEST_ASSETS/angion-method-evolving.imageset" ] && [ ! -f "$DEST_ASSETS/angion-method-evolving.imageset/Contents.json" ]; then
    echo "Creating Contents.json for angion-method-evolving.imageset"
    cat > "$DEST_ASSETS/angion-method-evolving.imageset/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "angion-method-evolving.jpg",
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

# beginners-guide-angion-method imageset
if [ -d "$DEST_ASSETS/beginners-guide-angion-method.imageset" ] && [ ! -f "$DEST_ASSETS/beginners-guide-angion-method.imageset/Contents.json" ]; then
    echo "Creating Contents.json for beginners-guide-angion-method.imageset"
    cat > "$DEST_ASSETS/beginners-guide-angion-method.imageset/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "beginners-guide-angion-method.jpg",
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

# blood-vessel-growth-mechanisms imageset
if [ -d "$DEST_ASSETS/blood-vessel-growth-mechanisms.imageset" ] && [ ! -f "$DEST_ASSETS/blood-vessel-growth-mechanisms.imageset/Contents.json" ]; then
    echo "Creating Contents.json for blood-vessel-growth-mechanisms.imageset"
    cat > "$DEST_ASSETS/blood-vessel-growth-mechanisms.imageset/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "blood-vessel-growth-mechanisms.jpg",
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

# holistic-male-health imageset
if [ -d "$DEST_ASSETS/holistic-male-health.imageset" ] && [ ! -f "$DEST_ASSETS/holistic-male-health.imageset/Contents.json" ]; then
    echo "Creating Contents.json for holistic-male-health.imageset"
    cat > "$DEST_ASSETS/holistic-male-health.imageset/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "holistic-male-health.png",
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

# intermediate-angion-cardiovascular imageset
if [ -d "$DEST_ASSETS/intermediate-angion-cardiovascular.imageset" ] && [ ! -f "$DEST_ASSETS/intermediate-angion-cardiovascular.imageset/Contents.json" ]; then
    echo "Creating Contents.json for intermediate-angion-cardiovascular.imageset"
    cat > "$DEST_ASSETS/intermediate-angion-cardiovascular.imageset/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "intermediate-angion-cardiovascular.jpg",
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

# intermediate-angion-mastering imageset
if [ -d "$DEST_ASSETS/intermediate-angion-mastering.imageset" ] && [ ! -f "$DEST_ASSETS/intermediate-angion-mastering.imageset/Contents.json" ]; then
    echo "Creating Contents.json for intermediate-angion-mastering.imageset"
    cat > "$DEST_ASSETS/intermediate-angion-mastering.imageset/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "intermediate-angion-mastering.png",
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

# preparing-angion-foundations imageset
if [ -d "$DEST_ASSETS/preparing-angion-foundations.imageset" ] && [ ! -f "$DEST_ASSETS/preparing-angion-foundations.imageset/Contents.json" ]; then
    echo "Creating Contents.json for preparing-angion-foundations.imageset"
    cat > "$DEST_ASSETS/preparing-angion-foundations.imageset/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "preparing-angion-foundations.jpg",
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

echo ""
echo "All remaining imagesets have been fixed!"
echo "The Assets.xcassets folder should now be properly configured."