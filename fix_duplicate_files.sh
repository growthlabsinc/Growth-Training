#!/bin/bash

# Script to help identify and fix duplicate file issues in Xcode project

echo "=== Fixing Duplicate File Issues in Growth Project ==="
echo ""

# 1. Clean DerivedData
echo "Step 1: Cleaning DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Growth-*
echo "✅ DerivedData cleaned"
echo ""

# 2. Check for duplicate files in the project
echo "Step 2: Checking for duplicate files in the project..."

# Check for duplicate Swift files
echo "Checking for duplicate Swift files..."
find /Users/tradeflowj/Desktop/Growth -name "NotificationPreferencesView.swift" -type f 2>/dev/null | head -10
find /Users/tradeflowj/Desktop/Growth -name "PendingConsents.swift" -type f 2>/dev/null | head -10
find /Users/tradeflowj/Desktop/Growth -name "ConsentRecord.swift" -type f 2>/dev/null | head -10
find /Users/tradeflowj/Desktop/Growth -name "RoutineProgress.swift" -type f 2>/dev/null | head -10
find /Users/tradeflowj/Desktop/Growth -name "InsightGenerationService.swift" -type f 2>/dev/null | head -10

echo ""

# 3. Check for multiple Info.plist references
echo "Step 3: Checking Info.plist locations..."
find /Users/tradeflowj/Desktop/Growth -name "Info.plist" -type f | grep -E "(Growth|App)" | head -10

echo ""
echo "=== Manual Steps Required ==="
echo ""
echo "1. Open Growth.xcodeproj in Xcode"
echo ""
echo "2. For each duplicate file:"
echo "   - Search for the file name in the project navigator"
echo "   - If it appears multiple times, remove duplicates"
echo "   - Keep only one reference to each file"
echo ""
echo "3. For Info.plist issue:"
echo "   - Go to Build Settings > Packaging"
echo "   - Ensure 'Info.plist File' points to: Growth/Resources/Plist/App/Info.plist"
echo "   - Remove any duplicate Info.plist references in Build Phases"
echo ""
echo "4. Clean and rebuild:"
echo "   - Product > Clean Build Folder (Cmd+Shift+K)"
echo "   - Product > Build (Cmd+B)"
echo ""

# Make the script executable
chmod +x fix_duplicate_files.sh