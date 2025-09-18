#!/bin/bash

# Script to update Info.plist path in Xcode project
echo "Updating Info.plist path in Growth.xcodeproj..."

# First, let's make a backup of the original project file
cp Growth.xcodeproj/project.pbxproj Growth.xcodeproj/project.pbxproj.backup.update.$(date +%Y%m%d%H%M%S)
echo "Backup created."

# Update INFOPLIST_FILE setting in the project.pbxproj file
sed -i '' 's|INFOPLIST_FILE = Growth/Info.plist;|INFOPLIST_FILE = Growth/Resources/Plist/App/Info.plist;|g' Growth.xcodeproj/project.pbxproj

echo "Updated INFOPLIST_FILE path in project.pbxproj"

# Create a direct fix for the most common cause: Info.plist included in Copy Bundle Resources
echo "Checking for other issues in project file..."

# Find files section with PBXBuildFile that might include Info.plist
INFO_PLIST_BUILD_FILE=$(grep -B 3 -A 1 "Info.plist in" Growth.xcodeproj/project.pbxproj)
if [ -n "$INFO_PLIST_BUILD_FILE" ]; then
  echo "Found potential reference to Info.plist in build files:"
  echo "$INFO_PLIST_BUILD_FILE"
  
  # Find the ID of the build file entry
  BUILD_FILE_ID=$(echo "$INFO_PLIST_BUILD_FILE" | grep -o "[0-9A-F]\{24\}")
  
  if [ -n "$BUILD_FILE_ID" ]; then
    echo "Found build file ID: $BUILD_FILE_ID"
    
    # Remove the build file entry from the Resources build phase
    sed -i '' "/$BUILD_FILE_ID/d" Growth.xcodeproj/project.pbxproj
    echo "Removed build file entry from project.pbxproj"
  fi
else
  echo "No explicit Info.plist build file entry found in project.pbxproj"
fi

# Check if there's a Copy Files build phase that might be causing issues
COPY_FILES_PHASE=$(grep -A 20 "Copy Files" Growth.xcodeproj/project.pbxproj | grep -B 5 -A 5 "Info.plist")
if [ -n "$COPY_FILES_PHASE" ]; then
  echo "Found potential Copy Files phase including Info.plist:"
  echo "$COPY_FILES_PHASE"
  
  # This is harder to automatically fix, would need a custom script
  echo "Please manually remove Info.plist from any Copy Files build phases in Xcode"
else
  echo "No explicit Copy Files phase including Info.plist found"
fi

echo "Fixes applied. Please try cleaning and rebuilding your project."
echo "If the problem persists, you will need to open the project in Xcode and manually remove Info.plist from the Copy Bundle Resources build phase." 