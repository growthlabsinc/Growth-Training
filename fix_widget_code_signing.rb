#!/usr/bin/env ruby
# Fix widget extension code signing identity conflict

require 'xcodeproj'

project = Xcodeproj::Project.open('Growth.xcodeproj')

# Fix widget extension target
widget_target = project.targets.find { |t| t.name == 'GrowthTimerWidgetExtension' }
if widget_target
  widget_target.build_configurations.each do |config|
    # Remove ALL code signing identity settings to let Xcode manage them
    config.build_settings.delete('CODE_SIGN_IDENTITY')
    config.build_settings.delete('CODE_SIGN_IDENTITY[sdk=iphoneos*]')
    config.build_settings.delete('CODE_SIGN_IDENTITY[sdk=macosx*]')
    
    # Ensure automatic signing
    config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
    config.build_settings['DEVELOPMENT_TEAM'] = '62T6J77P6R'
    
    puts "✅ Fixed #{config.name} configuration for GrowthTimerWidgetExtension"
  end
end

# Also fix main app to ensure consistency
main_target = project.targets.find { |t| t.name == 'Growth' }
if main_target
  main_target.build_configurations.each do |config|
    # Remove ALL code signing identity settings
    config.build_settings.delete('CODE_SIGN_IDENTITY')
    config.build_settings.delete('CODE_SIGN_IDENTITY[sdk=iphoneos*]')
    config.build_settings.delete('CODE_SIGN_IDENTITY[sdk=macosx*]')
    
    # Ensure automatic signing
    config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
    config.build_settings['DEVELOPMENT_TEAM'] = '62T6J77P6R'
    
    puts "✅ Fixed #{config.name} configuration for Growth"
  end
end

project.save
puts "\n✅ Code signing identity conflicts resolved!"
puts "   Both targets now use automatic signing without manual identity overrides"