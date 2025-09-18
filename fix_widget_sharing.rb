#!/usr/bin/env ruby

require 'securerandom'

project_file = "/Users/tradeflowj/Desktop/Dev/growth-backup-22aug2025/Growth.xcodeproj/project.pbxproj"
content = File.read(project_file)

# Files that should be shared between main app and widget
shared_files = [
  "AppGroupConstants.swift",
  "TimerActivityAttributes.swift", 
  "LiveActivityManager.swift",
  "TimerService.swift",
  "AppTheme.swift",
  "ThemeManager.swift",
  "Logger.swift",
  "FeatureAccess.swift",
  "SubscriptionTier.swift",
  "PaywallContext.swift"
]

widget_target_id = "7FE4D7832E01CE820006D2EA"
widget_sources_phase = "7FE4D7802E01CE820006D2EA"

# Find file references for shared files
shared_refs = {}
content.scan(/([A-F0-9]{24}) \/\* (#{shared_files.join('|')}) \*\/ = \{isa = PBXFileReference;[^}]+\}/) do |match|
  file_id = match[0]
  file_name = match[1]
  shared_refs[file_name] = file_id
end

# Check if these files are in widget target
widget_build_files = []
shared_refs.each do |file_name, file_ref_id|
  # Check if build file exists for widget target
  unless content.include?("/* #{file_name} in Sources */ = {isa = PBXBuildFile; fileRef = #{file_ref_id}")
    # Need to add build file for widget
    build_file_id = SecureRandom.hex(12).upcase
    build_file = "\t\t#{build_file_id} /* #{file_name} in Sources */ = {isa = PBXBuildFile; fileRef = #{file_ref_id} /* #{file_name} */; };"
    
    # Add to build files section
    content.sub!(/(\/\* End PBXBuildFile section \*\/)/) do
      "#{build_file}\n#{$1}"
    end
    
    widget_build_files << "\t\t\t\t#{build_file_id} /* #{file_name} in Sources */,"
    
    puts "Added #{file_name} to widget target"
  end
end

# Add to widget sources build phase if needed
if widget_build_files.any? && content =~ /(#{widget_sources_phase} \/\* Sources \*\/ = \{[^}]*files = \()([^)]*)(\);)/m
  current_files = $2
  content.sub!(/(#{widget_sources_phase} \/\* Sources \*\/ = \{[^}]*files = \()([^)]*)(\);)/m) do
    "#{$1}#{$2}\n#{widget_build_files.join("\n")}#{$3}"
  end
end

File.write(project_file, content)

puts "✅ Fixed widget extension sharing:"
puts "   - Checked #{shared_files.length} shared files"
puts "   - Added #{widget_build_files.length} files to widget target"