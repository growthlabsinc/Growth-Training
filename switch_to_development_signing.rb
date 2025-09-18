#!/usr/bin/env ruby

require 'xcodeproj'

puts "🔄 Switching to Development Signing for Local Testing"
puts "==================================================="
puts ""

# Open the project
project_path = 'Growth.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find main app target and widget target
app_target = project.targets.find { |t| t.name == "Growth" }
widget_target = project.targets.find { |t| t.name == "GrowthTimerWidgetExtension" }

if app_target.nil?
  puts "❌ Could not find Growth target"
  exit 1
end

puts "📱 Configuring for local device testing..."

# Switch to automatic signing for development
[app_target, widget_target].compact.each do |target|
  puts "\n🎯 Configuring #{target.name}..."
  
  target.build_configurations.each do |config|
    # Only modify Debug configuration for local testing
    if config.name == "Debug"
      puts "  📝 Updating #{config.name} configuration..."
      
      # Switch to automatic signing
      config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
      config.build_settings['DEVELOPMENT_TEAM'] = '62T6J77P6R'
      
      # Remove manual provisioning profile settings
      config.build_settings.delete('PROVISIONING_PROFILE_SPECIFIER')
      config.build_settings.delete('PROVISIONING_PROFILE')
      
      # Ensure development signing
      config.build_settings['CODE_SIGN_IDENTITY'] = 'Apple Development'
      
      puts "  ✅ Set to automatic signing"
    end
  end
end

# Save the project
project.save

puts "\n✅ Project configured for local testing!"
puts "\nNext steps:"
puts "1. Clean build folder (Shift+Cmd+K)"
puts "2. Build and run on your device"
puts "3. The app should install without the beta profile error"
puts "\n⚠️  Note: This only affects Debug builds. Release/Archive still uses manual signing."