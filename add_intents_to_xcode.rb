#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'Growth.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main app target and widget extension target
main_target = project.targets.find { |t| t.name == 'Growth' }
widget_target = project.targets.find { |t| t.name == 'GrowthTimerWidgetExtension' }

if main_target.nil?
  puts "❌ Could not find Growth target"
  exit 1
end

if widget_target.nil?
  puts "❌ Could not find GrowthTimerWidgetExtension target"
  exit 1
end

puts "✅ Found targets:"
puts "  - Main: #{main_target.name}"
puts "  - Widget: #{widget_target.name}"

# Find or create the AppIntents group
main_group = project.main_group['Growth']
if main_group.nil?
  puts "❌ Could not find Growth group"
  exit 1
end

app_intents_group = main_group['AppIntents']
if app_intents_group.nil?
  puts "📁 Creating AppIntents group..."
  app_intents_group = main_group.new_group('AppIntents', 'Growth/AppIntents')
end

# Intent files to add
intent_files = [
  'PauseTimerIntent.swift',
  'ResumeTimerIntent.swift',
  'StopTimerAndOpenAppIntent.swift'
]

# Remove old references from widget group if they exist
widget_group = project.main_group['GrowthTimerWidget']
if widget_group
  intent_files.each do |filename|
    old_ref = widget_group.files.find { |f| f.path == filename }
    if old_ref
      puts "🗑️ Removing old reference: #{filename} from widget group"
      old_ref.remove_from_project
    end
  end
end

# Add intent files to both targets
intent_files.each do |filename|
  file_path = "Growth/AppIntents/#{filename}"
  
  # Check if file already exists in project
  existing_ref = app_intents_group.files.find { |f| f.path == filename }
  
  if existing_ref
    puts "📝 File already in project: #{filename}"
    file_ref = existing_ref
  else
    # Add file reference to project
    file_ref = app_intents_group.new_file(file_path)
    puts "➕ Added file to project: #{filename}"
  end
  
  # Add to main target build phase if not already there
  main_sources = main_target.source_build_phase
  unless main_sources.files.any? { |f| f.file_ref == file_ref }
    main_sources.add_file_reference(file_ref)
    puts "  ✅ Added to Growth target: #{filename}"
  else
    puts "  ℹ️ Already in Growth target: #{filename}"
  end
  
  # Add to widget target build phase if not already there
  widget_sources = widget_target.source_build_phase
  unless widget_sources.files.any? { |f| f.file_ref == file_ref }
    widget_sources.add_file_reference(file_ref)
    puts "  ✅ Added to GrowthTimerWidgetExtension target: #{filename}"
  else
    puts "  ℹ️ Already in GrowthTimerWidgetExtension target: #{filename}"
  end
end

# Save the project
project.save
puts "\n✅ Project updated successfully!"
puts "\n⚠️ Important: Clean build folder (Cmd+Shift+K) and rebuild the project"