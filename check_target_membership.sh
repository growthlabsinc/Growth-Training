#!/bin/bash

# Check if files are in the Xcode project
echo "Checking if MethodsGuideViewModel.swift is referenced in the Xcode project..."

# Check in the project file
if grep -q "MethodsGuideViewModel.swift" Growth.xcodeproj/project.pbxproj 2>/dev/null; then
    echo "✅ MethodsGuideViewModel.swift is referenced in the Xcode project"
else
    echo "❌ MethodsGuideViewModel.swift is NOT referenced in the Xcode project"
    echo "   You need to add it to the project in Xcode:"
    echo "   1. Open Growth.xcodeproj in Xcode"
    echo "   2. Right-click on Growth/Features/Routines/ViewModels"
    echo "   3. Select 'Add Files to Growth...'"
    echo "   4. Select MethodsGuideViewModel.swift"
    echo "   5. Make sure 'Growth' target is checked"
fi

echo ""
echo "Checking if MethodsGuideView.swift is referenced in the Xcode project..."

if grep -q "MethodsGuideView.swift" Growth.xcodeproj/project.pbxproj 2>/dev/null; then
    echo "✅ MethodsGuideView.swift is referenced in the Xcode project"
else
    echo "❌ MethodsGuideView.swift is NOT referenced in the Xcode project"
fi

echo ""
echo "Files in ViewModels directory:"
ls -la Growth/Features/Routines/ViewModels/

echo ""
echo "Files in Views directory:"
ls -la Growth/Features/Routines/Views/