#!/usr/bin/env ruby

require 'xcodeproj'
require 'pathname'

# Open the project
project_path = 'Growth.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
main_target = project.targets.find { |t| t.name == 'Growth' }
unless main_target
  puts "❌ Could not find Growth target"
  exit 1
end

# Get the Growth group
growth_group = project.main_group.children.find { |g| g.name == 'Growth' }
unless growth_group
  puts "❌ Could not find Growth group"
  exit 1
end

# Find or create Core group
core_group = growth_group.children.find { |g| g.name == 'Core' }
unless core_group
  core_group = growth_group.new_group('Core')
  puts "📁 Created Core group"
end

# Find or create Models group
models_group = core_group.children.find { |g| g.name == 'Models' }
unless models_group
  models_group = core_group.new_group('Models')
  puts "📁 Created Models group"
end

# Files to add
model_files = [
  'Growth/Core/Models/SubscriptionProduct.swift',
  'Growth/Core/Models/SubscriptionTier.swift',
  'Growth/Core/Models/SubscriptionState.swift'
]

model_files.each do |file_path|
  file_name = File.basename(file_path)
  
  # Check if file already exists in project
  existing_file = models_group.children.find { |f| f.path == file_name }
  
  if existing_file
    puts "✓ #{file_name} already in project"
  else
    # Add file reference
    file_ref = models_group.new_reference(file_path)
    file_ref.name = file_name
    
    # Add to target
    main_target.add_file_references([file_ref])
    
    puts "✅ Added #{file_name} to project and target"
  end
end

# Save the project
project.save
puts "💾 Project saved successfully"