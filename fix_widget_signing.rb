#!/usr/bin/env ruby
# This script fixes widget extension signing issues

require 'xcodeproj'

project_path = 'Growth.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Fix widget extension target
widget_target = project.targets.find { |t| t.name == 'GrowthTimerWidgetExtension' }
if widget_target
  widget_target.build_configurations.each do |config|
    # Remove all manual signing settings
    config.build_settings.delete('PROVISIONING_PROFILE_SPECIFIER')
    config.build_settings.delete('PROVISIONING_PROFILE_SPECIFIER[sdk=iphoneos*]')
    config.build_settings.delete('CODE_SIGN_IDENTITY[sdk=iphoneos*]')
    
    # Set automatic signing
    config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
    config.build_settings['DEVELOPMENT_TEAM'] = '62T6J77P6R'
    
    # Ensure proper bundle identifier
    config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.growthlabs.growthmethod.GrowthTimerWidget'
  end
  puts "✅ Fixed GrowthTimerWidgetExtension signing settings"
end

# Also ensure main app is properly set
main_target = project.targets.find { |t| t.name == 'Growth' }
if main_target
  main_target.build_configurations.each do |config|
    config.build_settings.delete('PROVISIONING_PROFILE_SPECIFIER')
    config.build_settings.delete('PROVISIONING_PROFILE_SPECIFIER[sdk=iphoneos*]')
    config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
    config.build_settings['DEVELOPMENT_TEAM'] = '62T6J77P6R'
  end
  puts "✅ Verified Growth target signing settings"
end

project.save
puts "✅ Project saved successfully"
puts "\nNext steps:"
puts "1. Close and reopen the project in Xcode"
puts "2. Clean build folder (Shift+Cmd+K)"
puts "3. Try archiving again"