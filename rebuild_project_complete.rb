#!/usr/bin/env ruby

require 'securerandom'
require 'pathname'
require 'fileutils'
require 'json'

project_file = "/Users/tradeflowj/Desktop/Dev/growth-backup-22aug2025/Growth.xcodeproj/project.pbxproj"

# Backup the current project file
backup_file = "#{project_file}.backup.#{Time.now.strftime('%Y%m%d_%H%M%S')}"
FileUtils.cp(project_file, backup_file)
puts "Backed up project file to: #{backup_file}"

# Read the existing project file to preserve important settings
original_content = File.read(project_file)

def generate_uuid
  SecureRandom.hex(12).upcase
end

# Define the project structure
project_root = "/Users/tradeflowj/Desktop/Dev/growth-backup-22aug2025"

# Collect all files
growth_files = Dir.glob("#{project_root}/Growth/**/*").reject { |f| f.include?('.DS_Store') }
widget_files = Dir.glob("#{project_root}/GrowthTimerWidget/**/*").reject { |f| f.include?('.DS_Store') }
test_files = Dir.glob("#{project_root}/GrowthTests/**/*").reject { |f| f.include?('.DS_Store') }
uitest_files = Dir.glob("#{project_root}/GrowthUITests/**/*").reject { |f| f.include?('.DS_Store') }

# Known IDs from the existing project
main_project_id = "7F45FC3D2DCD768A00B4BEC9"
main_group_id = "7F45FC442DCD768A00B4BEC9"
products_group_id = "7F45FC462DCD768A00B4BEC9"
main_target_id = "7F45FC472DCD768A00B4BEC9"
test_target_id = "7F45FC582DCD768A00B4BEC9"
uitest_target_id = "7F45FC622DCD768A00B4BEC9"
widget_target_id = "7FE4D7832E01CE820006D2EA"

# Sources build phase IDs
main_sources_phase_id = "7F45FC5B2DCD768A00B4BEC9"
widget_sources_phase_id = "7FE4D7802E01CE820006D2EA"
test_sources_phase_id = "7F45FC5A2DCD768A00B4BEC9"
uitest_sources_phase_id = "7F45FC642DCD768A00B4BEC9"

# Resources build phase IDs
main_resources_phase_id = "7F45FC5C2DCD768A00B4BEC9"
widget_resources_phase_id = "7FE4D7812E01CE820006D2EA"

# Create new file references and build files
file_references = {}
build_files = {}
groups = {}

# Process files and create hierarchy
def process_directory(path, project_root)
  files = []
  dirs = []
  
  Dir.foreach(path) do |item|
    next if item == '.' || item == '..' || item == '.DS_Store'
    
    full_path = File.join(path, item)
    relative_path = Pathname.new(full_path).relative_path_from(Pathname.new(project_root)).to_s
    
    if File.directory?(full_path)
      dirs << {path: full_path, name: item, relative: relative_path}
    else
      files << {path: full_path, name: item, relative: relative_path}
    end
  end
  
  return files.sort_by { |f| f[:name] }, dirs.sort_by { |d| d[:name] }
end

# Create groups recursively
def create_group(dir_path, dir_name, parent_id, project_root, groups, file_references, build_files)
  group_id = generate_uuid
  groups[dir_path] = {
    id: group_id,
    name: dir_name,
    children: []
  }
  
  files, dirs = process_directory(dir_path, project_root)
  
  # Add files
  files.each do |file_info|
    file_id = generate_uuid
    file_references[file_info[:relative]] = {
      id: file_id,
      name: file_info[:name],
      path: file_info[:name],
      type: determine_file_type(file_info[:name])
    }
    groups[dir_path][:children] << file_id
    
    # Create build file if needed
    if should_compile?(file_info[:name])
      build_id = generate_uuid
      build_files[build_id] = {
        file_ref: file_id,
        file_name: file_info[:name],
        relative_path: file_info[:relative]
      }
    end
  end
  
  # Process subdirectories
  dirs.each do |dir_info|
    child_group_id = create_group(dir_info[:path], dir_info[:name], group_id, project_root, groups, file_references, build_files)
    groups[dir_path][:children] << child_group_id
  end
  
  return group_id
end

def determine_file_type(filename)
  case File.extname(filename)
  when '.swift' then 'sourcecode.swift'
  when '.h' then 'sourcecode.c.h'
  when '.m' then 'sourcecode.c.objc'
  when '.storyboard' then 'file.storyboard'
  when '.xib' then 'file.xib'
  when '.xcassets' then 'folder.assetcatalog'
  when '.plist' then 'text.plist.xml'
  when '.entitlements' then 'text.plist.entitlements'
  when '.xcdatamodeld' then 'wrapper.xcdatamodeld'
  when '.json' then 'text.json'
  when '.png' then 'image.png'
  when '.jpg', '.jpeg' then 'image.jpeg'
  when '.pdf' then 'image.pdf'
  when '.txt' then 'text.plain'
  when '.md' then 'text'
  when '.strings' then 'text.plist.strings'
  when '.xcconfig' then 'text.xcconfig'
  when '.intentdefinition' then 'file.intentdefinition'
  else 'text'
  end
end

def should_compile?(filename)
  ext = File.extname(filename)
  ['.swift', '.m', '.mm', '.c', '.cpp'].include?(ext)
end

def needs_resources?(filename)
  ext = File.extname(filename)
  ['.storyboard', '.xib', '.xcassets', '.xcdatamodeld', '.intentdefinition'].include?(ext)
end

# Create main Growth group
growth_group_id = generate_uuid
groups["#{project_root}/Growth"] = {
  id: growth_group_id,
  name: "Growth",
  children: []
}

# Process Growth directory
if Dir.exist?("#{project_root}/Growth")
  growth_files, growth_dirs = process_directory("#{project_root}/Growth", project_root)
  
  # Add top-level files
  growth_files.each do |file_info|
    file_id = generate_uuid
    file_references[file_info[:relative]] = {
      id: file_id,
      name: file_info[:name],
      path: file_info[:name],
      type: determine_file_type(file_info[:name])
    }
    groups["#{project_root}/Growth"][:children] << file_id
    
    if should_compile?(file_info[:name]) || needs_resources?(file_info[:name])
      build_id = generate_uuid
      build_files[build_id] = {
        file_ref: file_id,
        file_name: file_info[:name],
        relative_path: file_info[:relative]
      }
    end
  end
  
  # Process subdirectories
  growth_dirs.each do |dir_info|
    child_group_id = create_group(dir_info[:path], dir_info[:name], growth_group_id, project_root, groups, file_references, build_files)
    groups["#{project_root}/Growth"][:children] << child_group_id
  end
end

# Create widget group
widget_group_id = generate_uuid
if Dir.exist?("#{project_root}/GrowthTimerWidget")
  groups["#{project_root}/GrowthTimerWidget"] = {
    id: widget_group_id,
    name: "GrowthTimerWidget",
    children: []
  }
  
  widget_group_id = create_group("#{project_root}/GrowthTimerWidget", "GrowthTimerWidget", main_group_id, project_root, groups, file_references, build_files)
end

# Now build the project file content
content = []

# Header
content << "// !$*UTF8*$!"
content << "{"
content << "\tarchiveVersion = 1;"
content << "\tclasses = {"
content << "\t};"
content << "\tobjectVersion = 56;"
content << "\tobjects = {"
content << ""

# PBXBuildFile section
content << "/* Begin PBXBuildFile section */"
build_files.each do |build_id, info|
  if needs_resources?(info[:file_name])
    content << "\t\t#{build_id} /* #{info[:file_name]} in Resources */ = {isa = PBXBuildFile; fileRef = #{info[:file_ref]} /* #{info[:file_name]} */; };"
  else
    content << "\t\t#{build_id} /* #{info[:file_name]} in Sources */ = {isa = PBXBuildFile; fileRef = #{info[:file_ref]} /* #{info[:file_name]} */; };"
  end
end
content << "/* End PBXBuildFile section */"
content << ""

# PBXFileReference section
content << "/* Begin PBXFileReference section */"
file_references.each do |path, info|
  content << "\t\t#{info[:id]} /* #{info[:name]} */ = {isa = PBXFileReference; lastKnownFileType = #{info[:type]}; path = \"#{info[:path]}\"; sourceTree = \"<group>\"; };"
end
content << "/* End PBXFileReference section */"
content << ""

# PBXGroup section
content << "/* Begin PBXGroup section */"

# Main group
content << "\t\t#{main_group_id} = {"
content << "\t\t\tisa = PBXGroup;"
content << "\t\t\tchildren = ("
content << "\t\t\t\t#{growth_group_id} /* Growth */,"
content << "\t\t\t\t#{widget_group_id} /* GrowthTimerWidget */," if widget_group_id
content << "\t\t\t\t#{products_group_id} /* Products */,"
content << "\t\t\t);"
content << "\t\t\tsourceTree = \"<group>\";"
content << "\t\t};"

# Products group
content << "\t\t#{products_group_id} /* Products */ = {"
content << "\t\t\tisa = PBXGroup;"
content << "\t\t\tchildren = ("
content << "\t\t\t);"
content << "\t\t\tname = Products;"
content << "\t\t\tsourceTree = \"<group>\";"
content << "\t\t};"

# All other groups
groups.each do |path, group_info|
  content << "\t\t#{group_info[:id]} /* #{group_info[:name]} */ = {"
  content << "\t\t\tisa = PBXGroup;"
  content << "\t\t\tchildren = ("
  group_info[:children].each do |child_id|
    # Find the name for this child
    child_name = nil
    file_references.each do |fp, fi|
      if fi[:id] == child_id
        child_name = fi[:name]
        break
      end
    end
    if !child_name
      groups.each do |gp, gi|
        if gi[:id] == child_id
          child_name = gi[:name]
          break
        end
      end
    end
    content << "\t\t\t\t#{child_id} /* #{child_name || 'Unknown'} */,"
  end
  content << "\t\t\t);"
  content << "\t\t\tpath = \"#{File.basename(path)}\";"
  content << "\t\t\tsourceTree = \"<group>\";"
  content << "\t\t};"
end

content << "/* End PBXGroup section */"
content << ""

# Extract remaining sections from original file
remaining_sections = original_content.split(/\/\* End PBXGroup section \*\//, 2)[1]

# Fix the Sources build phases
if remaining_sections
  # Collect source files for each target
  main_sources = []
  widget_sources = []
  test_sources = []
  uitest_sources = []
  
  build_files.each do |build_id, info|
    if should_compile?(info[:file_name])
      if info[:relative_path].start_with?("GrowthTimerWidget/")
        widget_sources << "\t\t\t\t#{build_id} /* #{info[:file_name]} in Sources */,"
      elsif info[:relative_path].start_with?("GrowthTests/")
        test_sources << "\t\t\t\t#{build_id} /* #{info[:file_name]} in Sources */,"
      elsif info[:relative_path].start_with?("GrowthUITests/")
        uitest_sources << "\t\t\t\t#{build_id} /* #{info[:file_name]} in Sources */,"
      else
        main_sources << "\t\t\t\t#{build_id} /* #{info[:file_name]} in Sources */,"
        
        # Some files need to be in widget target too
        if ['AppGroupConstants.swift', 'TimerActivityAttributes.swift', 'LiveActivityManager.swift', 
            'TimerService.swift', 'AppTheme.swift', 'ThemeManager.swift', 'Logger.swift'].include?(info[:file_name])
          widget_sources << "\t\t\t\t#{build_id} /* #{info[:file_name]} in Sources */,"
        end
      end
    end
  end
  
  # Update the sources build phases in remaining sections
  remaining_sections.gsub!(/(#{main_sources_phase_id} \/\* Sources \*\/ = \{[^}]*files = \()([^)]*)(\);)/m) do
    "#{$1}\n#{main_sources.join("\n")}\n\t\t\t#{$3}"
  end
  
  if widget_sources.any?
    remaining_sections.gsub!(/(#{widget_sources_phase_id} \/\* Sources \*\/ = \{[^}]*files = \()([^)]*)(\);)/m) do
      "#{$1}\n#{widget_sources.join("\n")}\n\t\t\t#{$3}"
    end
  end
  
  content << remaining_sections
else
  content << "\t};"
  content << "\trootObject = #{main_project_id} /* Project object */;"
  content << "}"
end

# Write the complete file
File.write(project_file, content.join("\n"))

puts "✅ Project completely rebuilt!"
puts "   - Created #{file_references.length} file references"
puts "   - Created #{build_files.length} build files"  
puts "   - Created #{groups.length} groups"
puts ""
puts "IMPORTANT: Now you must:"
puts "1. Quit Xcode completely (Cmd+Q)"
puts "2. Delete ~/Library/Developer/Xcode/DerivedData/Growth-*"
puts "3. Open the project fresh"
puts "4. Clean Build Folder (Cmd+Shift+K)"
puts "5. Build (Cmd+B)"