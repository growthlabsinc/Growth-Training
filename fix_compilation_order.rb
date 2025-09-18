#!/usr/bin/env ruby

project_file = "/Users/tradeflowj/Desktop/Dev/growth-backup-22aug2025/Growth.xcodeproj/project.pbxproj"
content = File.read(project_file)

# Find the Sources build phase for main target
main_target_sources_regex = /(7F45FC5B2DCD768A00B4BEC9 \/\* Sources \*\/ = \{[^}]*files = \()([^)]*)(\);)/m
widget_target_sources_regex = /(7FE4D7802E01CE820006D2EA \/\* Sources \*\/ = \{[^}]*files = \()([^)]*)(\);)/m

# Extract current source files
main_sources = []
widget_sources = []

if content =~ main_target_sources_regex
  main_sources = $2.split("\n").map(&:strip).reject(&:empty?)
end

if content =~ widget_target_sources_regex
  widget_sources = $2.split("\n").map(&:strip).reject(&:empty?)
end

# Categorize files by priority (models first, then services, then viewmodels, then views)
priority_files = {
  1 => [], # Models - compile first
  2 => [], # Services - compile second
  3 => [], # ViewModels - compile third
  4 => [], # Views and others - compile last
}

widget_priority_files = {
  1 => [], # Shared models
  2 => [], # Widget-specific files
}

# Sort main target files by priority
main_sources.each do |file_entry|
  if file_entry.include?("Core/Models/") || file_entry.include?("Models/")
    priority_files[1] << file_entry
  elsif file_entry.include?("Core/Services/") || file_entry.include?("Services/")
    priority_files[2] << file_entry
  elsif file_entry.include?("ViewModels/") || file_entry.include?("ViewModel")
    priority_files[3] << file_entry
  else
    priority_files[4] << file_entry
  end
end

# Sort widget files
widget_sources.each do |file_entry|
  if file_entry.include?("AppGroupConstants") || file_entry.include?("TimerActivityAttributes")
    widget_priority_files[1] << file_entry
  else
    widget_priority_files[2] << file_entry
  end
end

# Rebuild sorted source lists
sorted_main_sources = []
priority_files.keys.sort.each do |priority|
  sorted_main_sources.concat(priority_files[priority].sort)
end

sorted_widget_sources = []
widget_priority_files.keys.sort.each do |priority|
  sorted_widget_sources.concat(widget_priority_files[priority].sort)
end

# Update main target sources
content.sub!(main_target_sources_regex) do
  "#{$1}\n#{sorted_main_sources.join("\n")}\n\t\t\t#{$3}"
end

# Update widget target sources if exists
if content =~ widget_target_sources_regex
  content.sub!(widget_target_sources_regex) do
    "#{$1}\n#{sorted_widget_sources.join("\n")}\n\t\t\t#{$3}"
  end
end

File.write(project_file, content)

puts "✅ Fixed compilation order:"
puts "   - Models: #{priority_files[1].length} files (compile first)"
puts "   - Services: #{priority_files[2].length} files (compile second)"
puts "   - ViewModels: #{priority_files[3].length} files (compile third)"
puts "   - Views/Others: #{priority_files[4].length} files (compile last)"
puts "   - Widget files: #{sorted_widget_sources.length} files"