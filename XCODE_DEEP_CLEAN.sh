#!/bin/bash
# Deep clean script for persistent Xcode issues

echo "🧹 Performing deep clean of Xcode caches..."

# Kill Xcode and related processes
echo "1. Killing Xcode processes..."
killall Xcode 2>/dev/null || true
killall com.apple.dt.Xcode.ITunesSoftwareService 2>/dev/null || true
killall xcprebuild 2>/dev/null || true

# Remove ALL derived data
echo "2. Removing all derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Remove module cache
echo "3. Removing module cache..."
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex

# Remove Xcode caches
echo "4. Removing Xcode caches..."
rm -rf ~/Library/Caches/com.apple.dt.Xcode*

# Remove project-specific caches
echo "5. Removing project caches..."
cd /Users/tradeflowj/Desktop/Dev/growth-fresh
rm -rf .build
rm -rf .swiftpm
rm -f Package.resolved
rm -rf *.xcworkspace/xcuserdata
rm -rf *.xcodeproj/xcuserdata

# Remove build folder if exists
echo "6. Removing build folder..."
rm -rf build/

# Clear Swift Package Manager cache
echo "7. Clearing SPM cache..."
rm -rf ~/Library/Caches/org.swift.swiftpm

echo "✅ Deep clean complete!"
echo ""
echo "Next steps:"
echo "1. Open Xcode"
echo "2. Open the project"
echo "3. Wait for indexing to complete"
echo "4. Product → Clean Build Folder (Shift+Cmd+K)"
echo "5. File → Packages → Reset Package Caches"
echo "6. Build (Cmd+B)"