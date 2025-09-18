#!/bin/bash

echo "🧹 Cleaning Xcode Derived Data and Build Folders..."

# Clean DerivedData
echo "Removing DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Clean build folder
echo "Cleaning build folder..."
if [ -d "build" ]; then
    rm -rf build
fi

# Clean Xcode project caches
echo "Cleaning Xcode caches..."
xcodebuild clean -project Growth.xcodeproj -scheme Growth 2>/dev/null || true

echo ""
echo "✅ Cleaning complete!"
echo ""
echo "📝 Next steps to fix MethodsGuideViewModel issue:"
echo ""
echo "1. Open Growth.xcodeproj in Xcode"
echo ""
echo "2. Add the missing files to the project:"
echo "   a. Right-click on 'Growth/Features/Routines/ViewModels' group"
echo "   b. Select 'Add Files to \"Growth\"...'"
echo "   c. Navigate to and select:"
echo "      - MethodsGuideViewModel.swift"
echo "   d. Make sure 'Growth' target is checked"
echo "   e. Click 'Add'"
echo ""
echo "3. Do the same for Views if needed:"
echo "   a. Right-click on 'Growth/Features/Routines/Views' group"
echo "   b. Add MethodsGuideView.swift if it's missing"
echo ""
echo "4. Build the project (⌘+B)"
echo ""
echo "The files exist on disk but aren't in the Xcode project."
echo "After adding them, the MethodsGuideViewModel will be found."