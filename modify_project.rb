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
