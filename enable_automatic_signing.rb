#!/usr/bin/env ruby
# This script enables automatic signing for App Store distribution

require 'xcodeproj'

project_path = 'Growth.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Update main app target
main_target = project.targets.find { |t| t.name == 'Growth' }
if main_target
  main_target.build_configurations.each do |config|
    config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
    config.build_settings.delete('CODE_SIGN_IDENTITY[sdk=iphoneos*]')
    config.build_settings.delete('PROVISIONING_PROFILE_SPECIFIER')
    config.build_settings['DEVELOPMENT_TEAM'] = '62T6J77P6R'
  end
  puts "✅ Updated Growth target to automatic signing"
end

# Update widget extension target
widget_target = project.targets.find { |t| t.name == 'GrowthTimerWidgetExtension' }
if widget_target
  widget_target.build_configurations.each do |config|
    config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
    config.build_settings.delete('CODE_SIGN_IDENTITY[sdk=iphoneos*]')
    config.build_settings.delete('PROVISIONING_PROFILE_SPECIFIER')
    config.build_settings['DEVELOPMENT_TEAM'] = '62T6J77P6R'
  end
  puts "✅ Updated GrowthTimerWidgetExtension target to automatic signing"
end

project.save
puts "✅ Project saved with automatic signing enabled"
puts "\nNext steps:"
puts "1. Open Xcode and select your team in Signing & Capabilities"
puts "2. Archive again"
puts "3. In Organizer, you should now see 'App Store Connect' as a distribution option"