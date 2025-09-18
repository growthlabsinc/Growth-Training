#!/bin/bash

echo "Diagnosing Xcode hanging issue..."
echo "================================="

# Check for large files that might cause issues
echo "1. Checking for unusually large files..."
find . -type f -size +10M -not -path "./node_modules/*" -not -path "./.git/*" -not -path "./functions/node_modules/*" 2>/dev/null | head -10

echo ""
echo "2. Checking for corrupt git index..."
if [ -f .git/index ]; then
    ls -lah .git/index
    file .git/index
fi

echo ""
echo "3. Checking Swift Package resolved versions..."
if [ -f Growth.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved ]; then
    echo "Package.resolved exists"
    wc -l Growth.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
else
    echo "No Package.resolved file found"
fi

echo ""
echo "4. Checking for workspace settings..."
if [ -f Growth.xcodeproj/project.xcworkspace/contents.xcworkspacedata ]; then
    echo "Workspace data exists"
    cat Growth.xcodeproj/project.xcworkspace/contents.xcworkspacedata
fi

echo ""
echo "5. Checking for any lock files..."
find . -name "*.lock" -o -name "*~" -o -name ".DS_Store" | grep -v node_modules | head -10

echo ""
echo "6. Recommendations:"
echo "- Try opening Xcode first, then use File > Open"
echo "- Hold Shift while opening to disable state restoration"
echo "- If using Git, try: git reset --hard HEAD"
echo "- Consider creating a new Xcode project and importing files"