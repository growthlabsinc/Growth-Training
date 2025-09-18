#!/usr/bin/env ruby

require 'fileutils'

project_file = "/Users/tradeflowj/Desktop/Dev/growth-backup-22aug2025/Growth.xcodeproj/project.pbxproj"

# Create backup
backup_file = "#{project_file}.backup.#{Time.now.strftime('%Y%m%d_%H%M%S')}"
FileUtils.cp(project_file, backup_file)
puts "Backed up to: #{backup_file}"

# Read the project file
content = File.read(project_file)

# The error is about PBXFileSystemSynchronizedRootGroup buildPhase
# This is incorrect - synchronized groups don't have buildPhase, they have exceptions

# Fix the synchronized root group sections
fixed_content = content.gsub(/buildPhase[^;]*;/, '')

# Ensure proper structure for synchronized groups
if fixed_content =~ /\/\* Begin PBXFileSystemSynchronizedRootGroup section \*\/(.*?)\/\* End PBXFileSystemSynchronizedRootGroup section \*\//m
  section = $1
  
  # Clean up and rebuild the section properly
  new_section = <<-EOF
		7F45FC452DCD768A00B4BEC9 /* Growth */ = {
			isa = PBXFileSystemSynchronizedRootGroup;
			path = Growth;
			sourceTree = "<group>";
		};
		7FE4D7842E01CE820006D2EA /* GrowthTimerWidget */ = {
			isa = PBXFileSystemSynchronizedRootGroup;
			path = GrowthTimerWidget;
			sourceTree = "<group>";
		};
		7F45FC692DCD768A00B4BEC9 /* GrowthTests */ = {
			isa = PBXFileSystemSynchronizedRootGroup;
			path = GrowthTests;
			sourceTree = "<group>";
		};
		7F45FC732DCD768A00B4BEC9 /* GrowthUITests */ = {
			isa = PBXFileSystemSynchronizedRootGroup;
			path = GrowthUITests;
			sourceTree = "<group>";
		};
  EOF
  
  fixed_content.sub!(/\/\* Begin PBXFileSystemSynchronizedRootGroup section \*\/.*?\/\* End PBXFileSystemSynchronizedRootGroup section \*\//m,
                     "/* Begin PBXFileSystemSynchronizedRootGroup section */#{new_section}/* End PBXFileSystemSynchronizedRootGroup section */")
end

# Fix the build file exception set if it exists
if fixed_content =~ /\/\* Begin PBXFileSystemSynchronizedBuildFileExceptionSet section \*\//
  # Clean up this section
  exception_section = <<-EOF
		7FE4D7852E01CE820006D2EA /* PBXFileSystemSynchronizedBuildFileExceptionSet */ = {
			isa = PBXFileSystemSynchronizedBuildFileExceptionSet;
			membershipExceptions = (
				"Core/Constants/AppGroupConstants.swift",
				"Core/Models/TimerActivityAttributes.swift", 
				"Core/Services/LiveActivityManager.swift",
				"Core/Services/TimerService.swift",
				"Core/Theme/AppTheme.swift",
				"Core/Theme/ThemeManager.swift",
				"Core/Utilities/Logger.swift",
			);
			target = 7FE4D7832E01CE820006D2EA /* GrowthTimerWidgetExtension */;
		};
  EOF
  
  fixed_content.sub!(/\/\* Begin PBXFileSystemSynchronizedBuildFileExceptionSet section \*\/.*?\/\* End PBXFileSystemSynchronizedBuildFileExceptionSet section \*\//m,
                     "/* Begin PBXFileSystemSynchronizedBuildFileExceptionSet section */#{exception_section}/* End PBXFileSystemSynchronizedBuildFileExceptionSet section */")
end

# Ensure the main group properly references the synchronized folders
if fixed_content =~ /(7F45FC442DCD768A00B4BEC9[^=]*= \{[^}]*children = \()([^)]*)(\)[^}]*\})/m
  children_section = $2
  
  # Make sure it has the proper children
  required_children = [
    "7F45FC452DCD768A00B4BEC9 /* Growth */",
    "7FE4D7842E01CE820006D2EA /* GrowthTimerWidget */",
    "7F45FC692DCD768A00B4BEC9 /* GrowthTests */",
    "7F45FC732DCD768A00B4BEC9 /* GrowthUITests */",
    "7F45FC462DCD768A00B4BEC9 /* Products */"
  ]
  
  new_children = []
  required_children.each do |child|
    child_id = child[/([A-F0-9]{24})/, 1]
    child_name = child[/\/\* ([^*]+) \*\//, 1]
    new_children << "\t\t\t\t#{child_id} /* #{child_name} */,"
  end
  
  fixed_content.sub!(/(7F45FC442DCD768A00B4BEC9[^=]*= \{[^}]*children = \()([^)]*)(\)[^}]*\})/m) do
    "#{$1}\n#{new_children.join("\n")}\n\t\t\t#{$3}"
  end
end

# Write the fixed content
File.write(project_file, fixed_content)

puts "✅ Fixed project file corruption!"
puts ""
puts "The issue was:"
puts "- Incorrect 'buildPhase' reference in PBXFileSystemSynchronizedRootGroup"
puts "- Synchronized groups don't have buildPhase properties"
puts ""
puts "Now try opening the project again in Xcode."