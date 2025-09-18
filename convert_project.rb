#!/usr/bin/env ruby

require 'securerandom'
require 'pathname'

# Read the project file
project_file = "/Users/tradeflowj/Desktop/Dev/growth-backup-22aug2025/Growth.xcodeproj/project.pbxproj"
content = File.read(project_file)

# Change object version from 77 to 56
content.gsub!(/objectVersion = 77;/, 'objectVersion = 56;')

# Remove PBXFileSystemSynchronized sections
content.gsub!(/\/\* Begin PBXFileSystemSynchronizedRootGroup section \*\/.*?\/\* End PBXFileSystemSynchronizedRootGroup section \*\//m, '')
content.gsub!(/\/\* Begin PBXFileSystemSynchronizedBuildFileExceptionSet section \*\/.*?\/\* End PBXFileSystemSynchronizedBuildFileExceptionSet section \*\//m, '')

# Generate UUIDs for new references
def generate_uuid
  SecureRandom.hex(12).upcase
end

# Read all Swift files
swift_files = File.readlines('/tmp/swift_files.txt').map(&:strip)

# Also include widget files
widget_files = Dir.glob("/Users/tradeflowj/Desktop/Dev/growth-backup-22aug2025/GrowthTimerWidget/**/*.swift")
all_files = (swift_files + widget_files).uniq.sort

# Create file references and build files
file_references = []
build_files = []
group_children = {}

# Track main target ID and widget target ID
main_target_id = "7F45FC5E2DCD768A00B4BEC9"
widget_target_id = "7FE4D7832E01CE820006D2EA"

# Generate references for each file
file_ref_ids = {}
build_file_ids = {}

all_files.each do |file_path|
  next if file_path.empty?
  
  relative_path = Pathname.new(file_path).relative_path_from(
    Pathname.new("/Users/tradeflowj/Desktop/Dev/growth-backup-22aug2025")
  ).to_s
  
  file_name = File.basename(file_path)
  file_ref_id = generate_uuid
  build_file_id = generate_uuid
  
  file_ref_ids[relative_path] = file_ref_id
  build_file_ids[relative_path] = build_file_id
  
  # Create file reference
  file_ref = "\t\t#{file_ref_id} /* #{file_name} */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \"#{file_name}\"; sourceTree = \"<group>\"; };"
  file_references << file_ref
  
  # Determine which target(s) this file belongs to
  if relative_path.start_with?("GrowthTimerWidget/")
    # Widget files belong to widget target
    build_file = "\t\t#{build_file_id} /* #{file_name} in Sources */ = {isa = PBXBuildFile; fileRef = #{file_ref_id} /* #{file_name} */; };"
  else
    # Growth files belong to main target
    build_file = "\t\t#{build_file_id} /* #{file_name} in Sources */ = {isa = PBXBuildFile; fileRef = #{file_ref_id} /* #{file_name} */; };"
  end
  build_files << build_file
  
  # Track for group organization
  dir_path = File.dirname(relative_path)
  group_children[dir_path] ||= []
  group_children[dir_path] << file_ref_id
end

# Insert PBXFileReference section if it doesn't exist properly
if content !~ /\/\* Begin PBXFileReference section \*\//
  # Add before PBXFrameworksBuildPhase
  content.sub!(/\/\* Begin PBXFrameworksBuildPhase section \*\//, 
    "/* Begin PBXFileReference section */\n#{file_references.join("\n")}\n/* End PBXFileReference section */\n\n/* Begin PBXFrameworksBuildPhase section */")
else
  # Append to existing section
  content.sub!(/(\/\* Begin PBXFileReference section \*\/.*?)(\n\/\* End PBXFileReference section \*\/)/m) do
    "#{$1}\n#{file_references.join("\n")}#{$2}"
  end
end

# Insert PBXBuildFile entries
if content !~ /\/\* Begin PBXBuildFile section \*\//
  content = "/* Begin PBXBuildFile section */\n#{build_files.join("\n")}\n/* End PBXBuildFile section */\n\n" + content
else
  content.sub!(/(\/\* Begin PBXBuildFile section \*\/.*?)(\n\/\* End PBXBuildFile section \*\/)/m) do
    "#{$1}\n#{build_files.join("\n")}#{$2}"
  end
end

# Create source build phase entries
main_source_files = []
widget_source_files = []

all_files.each do |file_path|
  next if file_path.empty?
  
  relative_path = Pathname.new(file_path).relative_path_from(
    Pathname.new("/Users/tradeflowj/Desktop/Dev/growth-backup-22aug2025")
  ).to_s
  
  build_file_id = build_file_ids[relative_path]
  file_name = File.basename(file_path)
  
  if relative_path.start_with?("GrowthTimerWidget/")
    widget_source_files << "\t\t\t\t#{build_file_id} /* #{file_name} in Sources */,"
  else
    main_source_files << "\t\t\t\t#{build_file_id} /* #{file_name} in Sources */,"
  end
end

# Update main target sources build phase
content.sub!(/(7F45FC5B2DCD768A00B4BEC9 \/\* Sources \*\/ = \{[^}]*files = \()([^)]*)(\);)/m) do
  "#{$1}\n#{main_source_files.join("\n")}\n\t\t\t#{$3}"
end

# Update widget target sources build phase if it exists
if content =~ /7FE4D7802E01CE820006D2EA \/\* Sources \*\//
  content.sub!(/(7FE4D7802E01CE820006D2EA \/\* Sources \*\/ = \{[^}]*files = \()([^)]*)(\);)/m) do
    "#{$1}\n#{widget_source_files.join("\n")}\n\t\t\t#{$3}"
  end
end

# Write the modified content
File.write(project_file, content)

puts "✅ Project converted successfully!"
puts "   - Changed objectVersion from 77 to 56"
puts "   - Added #{file_references.length} file references"
puts "   - Added #{build_files.length} build files"
puts "   - Added #{main_source_files.length} files to main target"
puts "   - Added #{widget_source_files.length} files to widget target"