#!/bin/bash

# Script to add missing widget files to Xcode project

echo "🔧 Adding missing widget files to Xcode project..."

# Note to user: You need to manually add these files to the Xcode project:
# 
# 1. Open Growth.xcodeproj in Xcode
# 2. Right-click on the "GrowthTimerWidget" group
# 3. Select "Add Files to Growth..."
# 4. Add these files to the GrowthTimerWidget target:
#    - GrowthTimerWidget/Managers/LiveActivityUpdateManager.swift
#
# 5. For AppGroupFileManager.swift, add it to BOTH targets:
#    - Growth (main app target)
#    - GrowthTimerWidgetExtension
#    Location: Growth/Core/Utilities/AppGroupFileManager.swift
#
# This will resolve the duplicate symbols error.

echo "⚠️  IMPORTANT: Manual Xcode steps required!"
echo ""
echo "1. Open Xcode"
echo "2. Add LiveActivityUpdateManager.swift to GrowthTimerWidget target"
echo "3. Make sure AppGroupFileManager.swift is added to BOTH:"
echo "   - Main app target (Growth)"
echo "   - Widget extension target (GrowthTimerWidgetExtension)"
echo ""
echo "This will fix the 'duplicate output file' errors."