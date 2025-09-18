#!/usr/bin/env ruby

require 'xcodeproj'
require 'pathname'

# Open the Xcode project
project_path = 'Growth.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target (Growth app)
main_target = project.targets.find { |t| t.name == 'Growth' }

unless main_target
  puts "❌ Could not find 'Growth' target"
  exit 1
end

puts "✅ Found Growth target"

# Files to add
analytics_files = [
  # Models
  'Growth/Core/Models/Analytics/AnalyticsModels.swift',
  'Growth/Core/Models/Analytics/ExperimentModels.swift',
  'Growth/Core/Models/Analytics/FunnelEvent.swift',
  
  # Services
  'Growth/Core/Services/Analytics/PaywallAnalyticsService.swift',
  'Growth/Core/Services/Analytics/PaywallExperimentService.swift',
  'Growth/Core/Services/Analytics/RevenueAttributionService.swift'
]

# Get or create the groups
main_group = project.main_group['Growth']
unless main_group
  puts "❌ Could not find 'Growth' group"
  exit 1
end

core_group = main_group['Core'] || main_group.new_group('Core')

# Handle Models/Analytics group
models_group = core_group['Models'] || core_group.new_group('Models')
analytics_models_group = models_group['Analytics'] || models_group.new_group('Analytics')

# Handle Services/Analytics group
services_group = core_group['Services'] || core_group.new_group('Services')
analytics_services_group = services_group['Analytics'] || services_group.new_group('Analytics')

files_added = 0
files_already_exist = 0

analytics_files.each do |file_path|
  full_path = Pathname.new(file_path)
  file_name = full_path.basename.to_s
  
  # Determine which group to add to
  target_group = if file_path.include?('Models/Analytics')
    analytics_models_group
  elsif file_path.include?('Services/Analytics')
    analytics_services_group
  else
    core_group
  end
  
  # Check if file already exists in the group
  existing_file = target_group.files.find { |f| f.path&.end_with?(file_name) }
  
  if existing_file
    puts "⚠️  #{file_name} already exists in project"
    
    # Check if it's in the target
    if main_target.source_build_phase.files.none? { |f| f.file_ref == existing_file }
      main_target.add_file_references([existing_file])
      puts "   ➕ Added #{file_name} to Growth target"
      files_added += 1
    else
      puts "   ✓ Already in Growth target"
      files_already_exist += 1
    end
  else
    # Add the file reference to the project
    file_ref = target_group.new_reference(file_path)
    
    # Add to the main target's compile sources
    main_target.add_file_references([file_ref])
    
    puts "✅ Added #{file_name} to project and Growth target"
    files_added += 1
  end
end

# Save the project
project.save

puts "\n" + "="*50
puts "📊 Summary:"
puts "   Files added to target: #{files_added}"
puts "   Files already in target: #{files_already_exist}"
puts "   Total analytics files: #{analytics_files.length}"
puts "="*50

if files_added > 0
  puts "\n✅ Project updated successfully!"
  puts "🔄 Please clean and rebuild the project in Xcode:"
  puts "   1. Open Xcode"
  puts "   2. Product → Clean Build Folder (⌘⇧K)"
  puts "   3. Product → Build (⌘B)"
else
  puts "\n✅ All files were already in the project"
end