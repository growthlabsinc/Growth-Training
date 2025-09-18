#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project = Xcodeproj::Project.open('Growth.xcodeproj')

# Find the main app target
app_target = project.targets.find { |t| t.name == "Growth" }
widget_target = project.targets.find { |t| t.name == "GrowthTimerWidgetExtension" }

if app_target.nil?
  puts "❌ Could not find Growth target"
  exit 1
end

puts "Found targets:"
puts "  - Main app: #{app_target.name}" if app_target
puts "  - Widget: #{widget_target.name}" if widget_target

# Update build configurations for both Debug and Release
['Debug', 'Release'].each do |config_name|
  puts "\n📝 Updating #{config_name} configuration..."
  
  # Update main app target
  if app_target
    config = app_target.build_configurations.find { |c| c.name == config_name }
    if config
      # Switch to automatic signing
      config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
      config.build_settings['CODE_SIGN_IDENTITY'] = 'Apple Development'
      config.build_settings['DEVELOPMENT_TEAM'] = 'ZLL8QZ4FCR'
      config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = ''
      config.build_settings.delete('PROVISIONING_PROFILE')
      
      # Ensure proper bundle identifier
      config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.growthlabs.growthmethod'
      
      puts "  ✅ Updated Growth target #{config_name} to automatic signing"
    end
  end
  
  # Update widget target
  if widget_target
    config = widget_target.build_configurations.find { |c| c.name == config_name }
    if config
      # Switch to automatic signing
      config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
      config.build_settings['CODE_SIGN_IDENTITY'] = 'Apple Development'
      config.build_settings['DEVELOPMENT_TEAM'] = 'ZLL8QZ4FCR'
      config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = ''
      config.build_settings.delete('PROVISIONING_PROFILE')
      
      # Ensure proper bundle identifier
      config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.growthlabs.growthmethod.GrowthTimerWidget'
      
      puts "  ✅ Updated GrowthTimerWidgetExtension target #{config_name} to automatic signing"
    end
  end
end

# Also update the project-level build settings
project.build_configurations.each do |config|
  puts "\n📝 Updating project-level #{config.name} configuration..."
  config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
  config.build_settings['DEVELOPMENT_TEAM'] = 'ZLL8QZ4FCR'
  config.build_settings.delete('PROVISIONING_PROFILE_SPECIFIER')
  config.build_settings.delete('PROVISIONING_PROFILE')
  puts "  ✅ Updated project-level configuration"
end

# Save the project
project.save
puts "\n✅ Project saved successfully!"
puts "\n🎯 Next steps:"
puts "1. Open Xcode"
puts "2. Clean build folder (Shift+Cmd+K)"
puts "3. Select your device"
puts "4. Build and run with Growth scheme"