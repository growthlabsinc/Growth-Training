#!/usr/bin/env ruby

require 'securerandom'
require 'pathname'
require 'fileutils'

project_file = "/Users/tradeflowj/Desktop/Dev/growth-backup-22aug2025/Growth.xcodeproj/project.pbxproj"

# Backup the current project file
backup_file = "#{project_file}.backup.#{Time.now.strftime('%Y%m%d_%H%M%S')}"
FileUtils.cp(project_file, backup_file)
puts "Backed up project file to: #{backup_file}"

content = File.read(project_file)

def generate_uuid
  SecureRandom.hex(12).upcase
end

# Find all Swift files and organize by directory
project_root = "/Users/tradeflowj/Desktop/Dev/growth-backup-22aug2025"
swift_files = Dir.glob("#{project_root}/Growth/**/*.swift").sort
widget_files = Dir.glob("#{project_root}/GrowthTimerWidget/**/*.swift").sort
test_files = Dir.glob("#{project_root}/GrowthTests/**/*.swift").sort
ui_test_files = Dir.glob("#{project_root}/GrowthUITests/**/*.swift").sort

# Also include other important files
storyboard_files = Dir.glob("#{project_root}/Growth/**/*.storyboard").sort
xib_files = Dir.glob("#{project_root}/Growth/**/*.xib").sort
plist_files = Dir.glob("#{project_root}/Growth/**/*.plist").sort
asset_files = Dir.glob("#{project_root}/Growth/**/*.xcassets").sort
entitlement_files = Dir.glob("#{project_root}/**/*.entitlements").sort
xcdatamodeld_files = Dir.glob("#{project_root}/Growth/**/*.xcdatamodeld").sort
json_files = Dir.glob("#{project_root}/Growth/**/*.json").sort

all_files = (swift_files + widget_files + test_files + ui_test_files + 
             storyboard_files + xib_files + plist_files + asset_files + 
             entitlement_files + xcdatamodeld_files + json_files).uniq.sort

# Clear existing file references and build files
content.gsub!(/\/\* Begin PBXFileReference section \*\/.*?\/\* End PBXFileReference section \*\//m, 
              "/* Begin PBXFileReference section */\n/* End PBXFileReference section */")
content.gsub!(/\/\* Begin PBXBuildFile section \*\/.*?\/\* End PBXBuildFile section \*\//m,
              "/* Begin PBXBuildFile section */\n/* End PBXBuildFile section */")

# Generate file references and build files
file_refs = {}
build_files = {}
group_children = {}

# Main app group ID
main_group_id = "7F45FC452DCD768A00B4BEC9"
widget_group_id = "7FE4D7842E01CE820006D2EA"
tests_group_id = generate_uuid
ui_tests_group_id = generate_uuid

# Track which files go to which target
main_target_files = []
widget_target_files = []
test_target_files = []
ui_test_target_files = []

all_files.each do |file_path|
  relative_path = Pathname.new(file_path).relative_path_from(Pathname.new(project_root)).to_s
  file_name = File.basename(file_path)
  dir_path = File.dirname(relative_path)
  
  # Generate IDs
  file_ref_id = generate_uuid
  file_refs[relative_path] = file_ref_id
  
  # Determine file type
  file_type = case File.extname(file_path)
  when '.swift'
    'sourcecode.swift'
  when '.storyboard'
    'file.storyboard'
  when '.xib'
    'file.xib'
  when '.plist'
    'text.plist.xml'
  when '.xcassets'
    'folder.assetcatalog'
  when '.entitlements'
    'text.plist.entitlements'
  when '.xcdatamodeld'
    'wrapper.xcdatamodeld'
  when '.json'
    'text.json'
  else
    'text'
  end
  
  # Track for groups
  group_children[dir_path] ||= []
  group_children[dir_path] << {id: file_ref_id, name: file_name}
  
  # Determine which target(s) this file belongs to
  if relative_path.start_with?("GrowthTimerWidget/")
    build_file_id = generate_uuid
    build_files[build_file_id] = {file_ref: file_ref_id, file_name: file_name}
    widget_target_files << build_file_id if file_type == 'sourcecode.swift'
  elsif relative_path.start_with?("GrowthTests/")
    build_file_id = generate_uuid
    build_files[build_file_id] = {file_ref: file_ref_id, file_name: file_name}
    test_target_files << build_file_id if file_type == 'sourcecode.swift'
  elsif relative_path.start_with?("GrowthUITests/")
    build_file_id = generate_uuid
    build_files[build_file_id] = {file_ref: file_ref_id, file_name: file_name}
    ui_test_target_files << build_file_id if file_type == 'sourcecode.swift'
  elsif relative_path.start_with?("Growth/")
    build_file_id = generate_uuid
    build_files[build_file_id] = {file_ref: file_ref_id, file_name: file_name}
    
    # Add to main target if it's a compilable file
    if ['sourcecode.swift', 'file.storyboard', 'file.xib', 'folder.assetcatalog', 'wrapper.xcdatamodeld'].include?(file_type)
      main_target_files << build_file_id
    end
    
    # Some files also need to be in widget target
    if file_name == "AppGroupConstants.swift" || 
       file_name == "TimerActivityAttributes.swift" ||
       file_name == "LiveActivityManager.swift" ||
       file_name == "TimerService.swift" ||
       file_name == "AppTheme.swift" ||
       file_name == "ThemeManager.swift" ||
       file_name == "Logger.swift"
      widget_build_file_id = generate_uuid
      build_files[widget_build_file_id] = {file_ref: file_ref_id, file_name: file_name}
      widget_target_files << widget_build_file_id
    end
  end
end

# Create PBXFileReference entries
file_ref_entries = []
file_refs.each do |relative_path, file_ref_id|
  file_name = File.basename(relative_path)
  file_type = case File.extname(relative_path)
  when '.swift'
    'sourcecode.swift'
  when '.storyboard'
    'file.storyboard'
  when '.xib'
    'file.xib'
  when '.plist'
    'text.plist.xml'
  when '.xcassets'
    'folder.assetcatalog'
  when '.entitlements'
    'text.plist.entitlements'
  when '.xcdatamodeld'
    'wrapper.xcdatamodeld'
  when '.json'
    'text.json'
  else
    'text'
  end
  
  # For files in subdirectories, use the full path
  if relative_path.include?('/')
    path_parts = relative_path.split('/')
    if path_parts.length > 2
      # Use relative path from parent directory
      file_path = path_parts.last
    else
      file_path = file_name
    end
  else
    file_path = file_name
  end
  
  file_ref_entries << "\t\t#{file_ref_id} /* #{file_name} */ = {isa = PBXFileReference; lastKnownFileType = #{file_type}; path = \"#{file_path}\"; sourceTree = \"<group>\"; };"
end

# Create PBXBuildFile entries
build_file_entries = []
build_files.each do |build_file_id, info|
  build_file_entries << "\t\t#{build_file_id} /* #{info[:file_name]} in Sources */ = {isa = PBXBuildFile; fileRef = #{info[:file_ref]} /* #{info[:file_name]} */; };"
end

# Create PBXGroup entries for directory structure
group_entries = {}
group_children.each do |dir_path, children|
  next if dir_path == "." || dir_path.empty?
  
  group_id = generate_uuid
  group_entries[dir_path] = group_id
  
  # Get the parent directory
  parent_dir = File.dirname(dir_path)
  parent_group = if parent_dir == "Growth"
    main_group_id
  elsif parent_dir == "GrowthTimerWidget"
    widget_group_id
  else
    group_entries[parent_dir]
  end
end

# Insert PBXFileReference section
content.sub!(/\/\* Begin PBXFileReference section \*\/\n\/\* End PBXFileReference section \*\//) do
  "/* Begin PBXFileReference section */\n#{file_ref_entries.join("\n")}\n/* End PBXFileReference section */"
end

# Insert PBXBuildFile section
content.sub!(/\/\* Begin PBXBuildFile section \*\/\n\/\* End PBXBuildFile section \*\//) do
  "/* Begin PBXBuildFile section */\n#{build_file_entries.join("\n")}\n/* End PBXBuildFile section */"
end

# Update Sources build phases
# Main target
if main_target_files.any?
  main_sources = main_target_files.map { |id| "\t\t\t\t#{id} /* in Sources */," }.join("\n")
  content.sub!(/(7F45FC5B2DCD768A00B4BEC9 \/\* Sources \*\/ = \{[^}]*files = \()([^)]*)(\);)/m) do
    "#{$1}\n#{main_sources}\n\t\t\t#{$3}"
  end
end

# Widget target
if widget_target_files.any?
  widget_sources = widget_target_files.map { |id| "\t\t\t\t#{id} /* in Sources */," }.join("\n")
  content.sub!(/(7FE4D7802E01CE820006D2EA \/\* Sources \*\/ = \{[^}]*files = \()([^)]*)(\);)/m) do
    "#{$1}\n#{widget_sources}\n\t\t\t#{$3}"
  end
end

# Update main group children
main_group_children = []
Dir.glob("#{project_root}/Growth/*").each do |item|
  if File.directory?(item)
    dir_name = File.basename(item)
    dir_relative = "Growth/#{dir_name}"
    if group_entries[dir_relative]
      main_group_children << "\t\t\t\t#{group_entries[dir_relative]} /* #{dir_name} */,"
    end
  else
    file_name = File.basename(item)
    file_relative = "Growth/#{file_name}"
    if file_refs[file_relative]
      main_group_children << "\t\t\t\t#{file_refs[file_relative]} /* #{file_name} */,"
    end
  end
end

if main_group_children.any?
  # Find and update the main group
  content.sub!(/(#{main_group_id} \/\* Growth \*\/ = \{[^}]*children = \()([^)]*)(\);)/m) do
    "#{$1}\n#{main_group_children.join("\n")}\n\t\t\t#{$3}"
  end
end

# Write the updated project file
File.write(project_file, content)

puts "✅ Project structure fixed!"
puts "   - Added #{file_refs.length} file references"
puts "   - Added #{build_files.length} build files"
puts "   - Main target: #{main_target_files.length} source files"
puts "   - Widget target: #{widget_target_files.length} source files"
puts "   - Created #{group_entries.length} groups"
puts ""
puts "Next steps:"
puts "1. Close Xcode completely"
puts "2. Open the project again"
puts "3. Clean Build Folder (Cmd+Shift+K)"
puts "4. Build (Cmd+B)"