#!/bin/bash

# Script to add the GrowthTimerWidget extension to the Xcode project

PROJECT_PATH="Growth.xcodeproj"
PROJECT_FILE="$PROJECT_PATH/project.pbxproj"

echo "Adding GrowthTimerWidget extension to Xcode project..."

# This is a simplified version - in reality you'd need to use a tool like xcodeproj or manually add via Xcode
# The widget extension needs:
# 1. A new target for the widget extension
# 2. Build phases (compile sources, copy bundle resources)
# 3. Proper bundle identifier (com.growth.widget)
# 4. Link against WidgetKit and SwiftUI frameworks
# 5. Add files to compile sources

cat << EOF

============================================
MANUAL STEPS REQUIRED IN XCODE:
============================================

1. Open Growth.xcodeproj in Xcode

2. File > New > Target > Widget Extension
   - Product Name: GrowthTimerWidget
   - Include Live Activity: YES
   - Bundle Identifier: com.growth.widget

3. When prompted, activate the scheme

4. Add existing files to the widget target:
   - GrowthTimerWidget/GrowthTimerWidget.swift
   - GrowthTimerWidget/TimerActivityAttributes.swift

5. In Widget Extension's Build Settings:
   - Set iOS Deployment Target to match main app
   - Ensure "Supports Live Activities" is YES

6. In Widget Extension's Info.plist:
   - Verify NSExtension settings are correct

7. Build the widget extension target to verify setup

============================================
EOF

chmod +x "$0"