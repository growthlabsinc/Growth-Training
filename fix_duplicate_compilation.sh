#!/bin/bash

echo "🔍 Diagnosing duplicate AppGroupConstants compilation issue..."

# Clean DerivedData
echo "🧹 Cleaning DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Growth-*

# Find all instances of AppGroupConstants.swift in the project
echo -e "\n📁 Finding all instances of AppGroupConstants.swift:"
find . -name "AppGroupConstants.swift" -type f 2>/dev/null | grep -v DerivedData | grep -v ".git"

# Check if file exists in multiple locations
count=$(find . -name "AppGroupConstants.swift" -type f 2>/dev/null | grep -v DerivedData | grep -v ".git" | wc -l)
if [ $count -gt 1 ]; then
    echo "⚠️  WARNING: Found $count instances of AppGroupConstants.swift!"
    echo "This could cause duplicate compilation. Remove duplicates."
fi

# Check xcodeproj for duplicate references
echo -e "\n📋 Checking project file for duplicate references:"
if [ -d "Growth.xcodeproj" ]; then
    grep -c "AppGroupConstants.swift" Growth.xcodeproj/project.pbxproj || true
    echo "References found in project.pbxproj"
    
    # Show the actual references
    echo -e "\n📝 Actual references:"
    grep "AppGroupConstants.swift" Growth.xcodeproj/project.pbxproj | head -10
fi

# Look for the file in build phases
echo -e "\n🔨 Checking if file appears multiple times in Compile Sources:"
if [ -d "Growth.xcodeproj" ]; then
    # Extract the compile sources section
    awk '/PBXSourcesBuildPhase/,/};/' Growth.xcodeproj/project.pbxproj | grep -c "AppGroupConstants.swift" || true
fi

echo -e "\n✅ Diagnostic complete!"
echo -e "\n📌 To fix in Xcode:"
echo "1. Open Growth.xcodeproj"
echo "2. Find AppGroupConstants.swift in navigator"
echo "3. Delete any duplicate references (keep only one)"
echo "4. Make sure it's only in one group/folder"
echo "5. Check Build Phases > Compile Sources"
echo "6. Remove any duplicate entries"
echo "7. Clean and rebuild"

echo -e "\n🚀 Quick fix attempt:"
echo "Backing up project file..."
cp Growth.xcodeproj/project.pbxproj Growth.xcodeproj/project.pbxproj.backup

# Try to remove duplicate entries from project file
echo "Attempting to remove duplicate compile sources entries..."
perl -i -pe 'BEGIN{undef $/;} s/(AppGroupConstants\.swift in Sources.*?\n)(?=.*AppGroupConstants\.swift in Sources)//smg' Growth.xcodeproj/project.pbxproj

echo -e "\n✨ Done! Now:"
echo "1. Open Xcode"
echo "2. Clean Build Folder (Cmd+Shift+K)"
echo "3. Build again"