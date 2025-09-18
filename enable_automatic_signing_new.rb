#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'Growth.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Team ID
team_id = '62T6J77P6R'

# Update main app target
main_target = project.targets.find { |t| t.name == 'Growth' }
if main_target
  puts "Updating Growth target to automatic signing..."
  main_target.build_configurations.each do |config|
    config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
    config.build_settings['DEVELOPMENT_TEAM'] = team_id
    config.build_settings.delete('PROVISIONING_PROFILE_SPECIFIER')
    config.build_settings['CODE_SIGN_IDENTITY'] = 'Apple Development'
    puts "  - #{config.name}: Set to automatic signing"
  end
end

# Update widget target
widget_target = project.targets.find { |t| t.name == 'GrowthTimerWidgetExtension' }
if widget_target
  puts "Updating Widget target to automatic signing..."
  widget_target.build_configurations.each do |config|
    config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
    config.build_settings['DEVELOPMENT_TEAM'] = team_id
    config.build_settings.delete('PROVISIONING_PROFILE_SPECIFIER')
    config.build_settings['CODE_SIGN_IDENTITY'] = 'Apple Development'
    puts "  - #{config.name}: Set to automatic signing"
  end
end

# Save the project
project.save

puts "\n✅ Automatic signing enabled for all targets!"
puts "\nNext steps:"
puts "1. Open Growth.xcodeproj in Xcode"
puts "2. Select your device"
puts "3. Build and run (⌘+R)"
puts "\nXcode will automatically create the correct provisioning profiles."