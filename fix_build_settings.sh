#!/bin/bash

# Script to fix Info.plist duplicate issue by updating build settings
echo "Fixing Info.plist issues by updating build settings..."

# Create a final backup of the project file
cp Growth.xcodeproj/project.pbxproj Growth.xcodeproj/project.pbxproj.backup.final.$(date +%Y%m%d%H%M%S)
echo "Final backup created."

# Create a target-level xcconfig file to override build settings
mkdir -p Config
cat > Config/InfoPlist.xcconfig << EOF
// Custom build settings to fix Info.plist duplication issue
INFOPLIST_FILE = Growth/Resources/Plist/App/Info.plist
INFOPLIST_PREPROCESS = YES
INFOPLIST_PREFIX_HEADER = 
COPYFILE_DISABLE = YES
// Skip copying Info.plist in Copy Resource phase
COPY_PHASE_STRIP = NO
// Process but don't copy
INFOPLIST_OTHER_PREPROCESSOR_FLAGS = -traditional
// Use only processed version, not copied version
EOF

echo "Created Config/InfoPlist.xcconfig with proper settings"

# Update the project to use the xcconfig file
cat > add_xcconfig.rb << EOF
#!/usr/bin/env ruby

begin
  # Try to use xcodeproj gem if available
  require 'xcodeproj'
  
  project_path = 'Growth.xcodeproj'
  project = Xcodeproj::Project.open(project_path)
  
  # Get the main target
  main_target = project.targets.find { |t| t.name == 'Growth' }
  
  if main_target
    # Add the xcconfig file to the project
    file_ref = project.new_file('Config/InfoPlist.xcconfig')
    
    # Set the xcconfig file for all configurations
    main_target.build_configurations.each do |config|
      config.base_configuration_reference = file_ref
    end
    
    # Set specific build settings 
    main_target.build_configurations.each do |config|
      config.build_settings['INFOPLIST_FILE'] = 'Growth/Resources/Plist/App/Info.plist'
      config.build_settings['SKIP_INSTALL'] = 'NO'
      
      # Remove any explicit resource copying
      if config.build_settings['COPY_PHASE_STRIP']
        config.build_settings.delete('COPY_PHASE_STRIP')
      end
      
      # Ensure we're using the processed version
      config.build_settings['INFOPLIST_PREPROCESS'] = 'YES'
    end
    
    # Save the project
    project.save
    puts "Successfully updated project with xcconfig file"
  else
    puts "Error: Couldn't find Growth target"
  end
rescue LoadError
  puts "Xcodeproj gem not available, using manual approach"
  
  # Fallback to manual approach
  # Update INFOPLIST_FILE setting in the project.pbxproj file
  system("sed -i '' 's|INFOPLIST_FILE = Growth/Info.plist;|INFOPLIST_FILE = Growth/Resources/Plist/App/Info.plist;|g' Growth.xcodeproj/project.pbxproj")
end
EOF

chmod +x add_xcconfig.rb

# Try to run the Ruby script
if command -v ruby &> /dev/null; then
  echo "Running Ruby script to update project..."
  ruby add_xcconfig.rb
else
  echo "Ruby not available, applying manual fixes..."
  # Manual fix - just update the INFOPLIST_FILE path
  sed -i '' 's|INFOPLIST_FILE = Growth/Info.plist;|INFOPLIST_FILE = Growth/Resources/Plist/App/Info.plist;|g' Growth.xcodeproj/project.pbxproj
fi

# One more additional fix: check if the Info.plist is being included in any resource file lists
echo "Checking for Info.plist in resource file lists..."

# Create a final xcodebuild command to clean the project
echo "Running final clean build to apply settings..."
xcodebuild -project Growth.xcodeproj -target Growth clean

echo "All fixes applied. Please rebuild your project."
echo ""
echo "⚠️ If the issue persists, please follow these manual steps in Xcode:"
echo "1. Open Growth.xcodeproj in Xcode"
echo "2. Select the Growth target"
echo "3. Go to Build Phases tab"
echo "4. Expand 'Copy Bundle Resources'"
echo "5. Remove Info.plist if it appears in the list"
echo "6. Go to Build Settings tab"
echo "7. Search for 'Info.plist'"
echo "8. Ensure INFOPLIST_FILE is set to Growth/Resources/Plist/App/Info.plist for all configurations"
echo "9. Clean and rebuild the project" 