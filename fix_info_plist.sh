#!/bin/bash

# Script to fix duplicate Info.plist issue in Xcode project
echo "Fixing duplicate Info.plist issue in Growth.xcodeproj..."

# First, let's make a backup of the original project file
cp Growth.xcodeproj/project.pbxproj Growth.xcodeproj/project.pbxproj.backup.$(date +%Y%m%d%H%M%S)
echo "Backup created."

# Update the build settings to use process info plist file only
# This should fix the "Multiple commands produce" error for Info.plist

# Check if xcodebuild is available
if ! command -v xcodebuild &> /dev/null; then
    echo "Error: xcodebuild command not found. Please make sure Xcode is installed."
    exit 1
fi

# Solution approach: Use a temporary file to modify the project.pbxproj
# We'll look for the Copy Bundle Resources build phase and remove Info.plist from it

# Find the copy resources build phase that contains Info.plist
echo "Looking for Info.plist in Copy Bundle Resources build phase..."

# Run this command to check if the Info.plist is in Copy Bundle Resources
RESOURCES_PHASE_LINES=$(grep -n "Begin PBXResourcesBuildPhase section" -A 100 Growth.xcodeproj/project.pbxproj | grep -B 10 -A 10 "Info.plist" | head -30)
echo "Found references to Info.plist in resource phase:"
echo "$RESOURCES_PHASE_LINES"

# We need to tell Xcode to NOT include Info.plist in the Copy Bundle Resources phase
# The simplest fix is to modify the project settings to ensure Info.plist is only processed once

echo "Applying fixes..."

# Run xcodebuild to update project settings
xcodebuild -project Growth.xcodeproj -target Growth clean

# Try a specific fix - create a custom script that does this project modification
cat > modify_project.rb << 'EOF'
#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'Growth.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
main_target = project.targets.find { |t| t.name == 'Growth' }

# Find the resources build phase
resources_phase = main_target.resources_build_phase

# Find Info.plist file reference
info_plist_ref = nil
project.files.each do |file|
  if file.path.end_with?('Info.plist')
    info_plist_ref = file
    break
  end
end

if info_plist_ref
  # Remove Info.plist from resources phase if it's there
  resources_phase.files.each do |build_file|
    if build_file.file_ref == info_plist_ref
      resources_phase.remove_build_file(build_file)
      puts "Removed Info.plist from resources build phase"
    end
  end
else
  puts "Info.plist reference not found in project"
end

# Save the project
project.save
EOF

# Make the script executable
chmod +x modify_project.rb

# Check if ruby and xcodeproj gem are available
if command -v ruby &> /dev/null && gem list -i xcodeproj &> /dev/null; then
    echo "Running Ruby script to modify project..."
    ruby modify_project.rb
    echo "Project modified with Ruby script."
else
    echo "Ruby or xcodeproj gem not found. Let's try a manual fix."
    
    # Manual fix approach: This is simpler but less reliable
    # Create a custom Info.plist file in a different location and update project settings
    
    # Create a new Info.plist in a subdirectory to avoid conflict
    mkdir -p Growth/Resources/Plist/App
    cp Growth/Info.plist Growth/Resources/Plist/App/Info.plist
    
    echo "Created a copy of Info.plist in Growth/Resources/Plist/App/"
    echo "Please update your project settings to use this file instead:"
    echo "INFOPLIST_FILE = Growth/Resources/Plist/App/Info.plist"
fi

echo "Fix completed. Please clean and rebuild your project."
echo "If the issue persists, you may need to open Xcode and manually remove Info.plist from the Copy Bundle Resources build phase." 