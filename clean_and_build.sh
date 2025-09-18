#!/bin/bash

echo "🧹 Cleaning Xcode build artifacts..."

# Kill any stuck Xcode processes
echo "Stopping any stuck Xcode processes..."
killall Xcode 2>/dev/null || true

# Clean DerivedData
echo "Cleaning DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Growth-*

# Clean build folder
echo "Cleaning build folder..."
xcodebuild clean -project Growth.xcodeproj -scheme Growth -quiet

# Reset package caches
echo "Resetting Swift Package caches..."
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf .swiftpm

# Clear module cache
echo "Clearing module cache..."
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex

echo "✅ Cleanup complete!"
echo ""
echo "📱 Now you can:"
echo "1. Open Xcode"
echo "2. Let it re-index the project"
echo "3. Build the project (Cmd+B)"