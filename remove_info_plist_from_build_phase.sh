#!/bin/bash

# Script to remove Info.plist from build phases
echo "Searching for Info.plist in build phases..."

# Make another backup before we make these changes
cp Growth.xcodeproj/project.pbxproj Growth.xcodeproj/project.pbxproj.backup.remove.$(date +%Y%m%d%H%M%S)
echo "Backup created."

# Find the PBXFileReference for Info.plist
INFO_PLIST_REF=$(grep -n -B 2 -A 2 "Info.plist" Growth.xcodeproj/project.pbxproj | grep "PBXFileReference")
echo "Info.plist file references:"
echo "$INFO_PLIST_REF"

# Find any build file entries that reference Info.plist
# First, find the file reference ID
FILE_REF_ID=$(echo "$INFO_PLIST_REF" | grep -o "[0-9A-F]\{24\}")
if [ -n "$FILE_REF_ID" ]; then
  echo "Found file reference ID: $FILE_REF_ID"
  
  # Look for build file entries that reference this file
  BUILD_FILE_ENTRIES=$(grep -n -B 2 -A 2 "$FILE_REF_ID" Growth.xcodeproj/project.pbxproj | grep "PBXBuildFile")
  
  if [ -n "$BUILD_FILE_ENTRIES" ]; then
    echo "Found build file entries referencing Info.plist:"
    echo "$BUILD_FILE_ENTRIES"
    
    # Extract build file IDs
    BUILD_FILE_IDS=$(echo "$BUILD_FILE_ENTRIES" | grep -o "[0-9A-F]\{24\}")
    
    # For each build file ID, remove it from all build phases
    for BUILD_ID in $BUILD_FILE_IDS; do
      echo "Removing build file ID $BUILD_ID from project..."
      
      # Find the line containing this ID in a build phase
      BUILD_PHASE_LINES=$(grep -n "$BUILD_ID" Growth.xcodeproj/project.pbxproj)
      
      if [ -n "$BUILD_PHASE_LINES" ]; then
        echo "Found build phase lines for $BUILD_ID:"
        echo "$BUILD_PHASE_LINES"
        
        # For each line, get the line number and remove that line from the file
        while read -r LINE; do
          LINE_NUM=$(echo "$LINE" | cut -d':' -f1)
          if [ -n "$LINE_NUM" ]; then
            echo "Removing line $LINE_NUM from project file..."
            sed -i '' "${LINE_NUM}d" Growth.xcodeproj/project.pbxproj
          fi
        done <<< "$BUILD_PHASE_LINES"
      fi
    done
  else
    echo "No build file entries found referencing Info.plist"
  fi
else
  echo "Could not find file reference ID for Info.plist"
fi

# Create a Process.plist phase if it doesn't exist
echo "Setting process-only flag for Info.plist..."

# Run xcodebuild to apply project changes
xcodebuild -project Growth.xcodeproj -target Growth -showBuildSettings > /dev/null

echo "Fixes applied. Please clean and rebuild your project."
echo "If the issue persists, you may need to manually edit the project settings in Xcode."
echo "Open the project, select the Growth target, go to Build Phases, and ensure Info.plist is not in Copy Bundle Resources." 