#!/usr/bin/env ruby

require 'pathname'
require 'fileutils'

project_file = "/Users/tradeflowj/Desktop/Dev/growth-backup-22aug2025/Growth.xcodeproj/project.pbxproj"
backup_file = "/Users/tradeflowj/Desktop/Dev/growth-backup-22aug2025/Growth.xcodeproj/project.pbxproj.backup.20250826_162936"

# Restore the Xcode 15 format backup
puts "Restoring Xcode 15 format backup..."
FileUtils.cp(backup_file, project_file)

# Read the project file
content = File.read(project_file)

# The issue with Xcode 15's folder sync is that it needs proper folder references
# We need to ensure the synchronized groups have the correct structure

# Find the PBXFileSystemSynchronizedRootGroup sections
if content =~ /\/\* Begin PBXFileSystemSynchronizedRootGroup section \*\/(.*?)\/\* End PBXFileSystemSynchronizedRootGroup section \*\//m
  sync_section = $1
  
  # Check if Growth folder reference exists
  if sync_section !~ /7F45FC452DCD768A00B4BEC9.*?Growth.*?path = Growth/m
    puts "⚠️  Growth folder reference is missing or incorrect"
    
    # Fix the Growth folder reference
    growth_ref = <<-EOF
		7F45FC452DCD768A00B4BEC9 /* Growth */ = {
			isa = PBXFileSystemSynchronizedRootGroup;
			explicitFileTypes = {
			};
			explicitFolders = (
			);
			path = Growth;
			sourceTree = "<group>";
		};
    EOF
    
    # Insert before the end of section if not present
    unless content.include?("7F45FC452DCD768A00B4BEC9 /* Growth */")
      content.sub!(/(\/\* End PBXFileSystemSynchronizedRootGroup section \*\/)/) do
        "#{growth_ref}#{$1}"
      end
      puts "✅ Added Growth folder reference"
    end
  end
  
  # Check if GrowthTimerWidget folder reference exists
  if sync_section !~ /7FE4D7842E01CE820006D2EA.*?GrowthTimerWidget.*?path = GrowthTimerWidget/m
    puts "⚠️  GrowthTimerWidget folder reference is missing or incorrect"
    
    widget_ref = <<-EOF
		7FE4D7842E01CE820006D2EA /* GrowthTimerWidget */ = {
			isa = PBXFileSystemSynchronizedRootGroup;
			explicitFileTypes = {
			};
			explicitFolders = (
			);
			path = GrowthTimerWidget;
			sourceTree = "<group>";
		};
    EOF
    
    unless content.include?("7FE4D7842E01CE820006D2EA /* GrowthTimerWidget */")
      content.sub!(/(\/\* End PBXFileSystemSynchronizedRootGroup section \*\/)/) do
        "#{widget_ref}#{$1}"
      end
      puts "✅ Added GrowthTimerWidget folder reference"
    end
  end
end

# Ensure main group has proper children references
if content =~ /(7F45FC442DCD768A00B4BEC9 = \{[^}]*children = \()([^)]*)(\);)/m
  children = $2
  updated_children = []
  
  # Ensure Growth folder is referenced
  if children !~ /7F45FC452DCD768A00B4BEC9/
    updated_children << "\t\t\t\t7F45FC452DCD768A00B4BEC9 /* Growth */,"
  end
  
  # Ensure GrowthTimerWidget is referenced  
  if children !~ /7FE4D7842E01CE820006D2EA/
    updated_children << "\t\t\t\t7FE4D7842E01CE820006D2EA /* GrowthTimerWidget */,"
  end
  
  # Ensure Products is referenced
  if children !~ /7F45FC462DCD768A00B4BEC9/
    updated_children << "\t\t\t\t7F45FC462DCD768A00B4BEC9 /* Products */,"
  end
  
  if updated_children.any?
    content.sub!(/(7F45FC442DCD768A00B4BEC9 = \{[^}]*children = \()([^)]*)(\);)/m) do
      "#{$1}\n#{updated_children.join("\n")}\n\t\t\t#{$3}"
    end
    puts "✅ Updated main group children"
  end
end

# Fix build phase file exceptions
# For Xcode 15, we need to ensure certain files are explicitly included in build phases
exceptions_section = content[/\/\* Begin PBXFileSystemSynchronizedBuildFileExceptionSet section \*\/(.*?)\/\* End PBXFileSystemSynchronizedBuildFileExceptionSet section \*\//m, 1]

if exceptions_section.nil? || exceptions_section.strip.empty?
  puts "⚠️  Build file exceptions section is missing"
  
  # Add exceptions for files that need to be in multiple targets
  exceptions = <<-EOF
		7F45FC5D2DCD768A00B4BEC9 /* PBXFileSystemSynchronizedBuildFileExceptionSet */ = {
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
  
  # Insert the exceptions section if it doesn't exist
  if content !~ /\/\* Begin PBXFileSystemSynchronizedBuildFileExceptionSet section \*\//
    content.sub!(/(\/\* End PBXFileSystemSynchronizedRootGroup section \*\/)/) do
      "#{$1}\n\n/* Begin PBXFileSystemSynchronizedBuildFileExceptionSet section */#{exceptions}/* End PBXFileSystemSynchronizedBuildFileExceptionSet section */"
    end
  else
    content.sub!(/(\/\* Begin PBXFileSystemSynchronizedBuildFileExceptionSet section \*\/)([^\/]*)(\/\* End PBXFileSystemSynchronizedBuildFileExceptionSet section \*\/)/) do
      "#{$1}#{exceptions}#{$3}"
    end
  end
  
  puts "✅ Added build file exceptions for widget target"
end

# Ensure source build phases reference the synchronized groups
# Main target sources
if content =~ /(7F45FC5B2DCD768A00B4BEC9 \/\* Sources \*\/ = \{[^}]*files = \()([^)]*)(\);)/m
  files = $2
  if files !~ /7F45FC452DCD768A00B4BEC9/
    content.sub!(/(7F45FC5B2DCD768A00B4BEC9 \/\* Sources \*\/ = \{[^}]*files = \()([^)]*)(\);)/m) do
      "#{$1}\n\t\t\t\t7F45FC452DCD768A00B4BEC9 /* Growth */,\n\t\t\t#{$3}"
    end
    puts "✅ Added Growth to main target sources"
  end
end

# Widget target sources
if content =~ /(7FE4D7802E01CE820006D2EA \/\* Sources \*\/ = \{[^}]*files = \()([^)]*)(\);)/m
  files = $2
  if files !~ /7FE4D7842E01CE820006D2EA/
    content.sub!(/(7FE4D7802E01CE820006D2EA \/\* Sources \*\/ = \{[^}]*files = \()([^)]*)(\);)/m) do
      "#{$1}\n\t\t\t\t7FE4D7842E01CE820006D2EA /* GrowthTimerWidget */,\n\t\t\t#{$3}"
    end
    puts "✅ Added GrowthTimerWidget to widget target sources"
  end
end

# Write the updated content
File.write(project_file, content)

puts "\n✅ Xcode 15 folder syncing fixed!"
puts "\nNow:"
puts "1. Quit Xcode completely (Cmd+Q)"
puts "2. Clear derived data: rm -rf ~/Library/Developer/Xcode/DerivedData/Growth-*"
puts "3. Open Xcode"
puts "4. Open the project"
puts "5. Wait for Xcode to index the files"
puts "6. Clean Build Folder (Cmd+Shift+K)"
puts "7. Build (Cmd+B)"
puts "\nIf files still don't appear:"
puts "- Right-click on Growth folder in navigator"
puts "- Select 'Add Files to Growth...'"
puts "- Navigate to the Growth folder"
puts "- Select 'Create folder references'"
puts "- Click Add"