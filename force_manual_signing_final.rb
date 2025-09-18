#!/usr/bin/env ruby
# Force manual signing and remove all automatic signing traces

require 'xcodeproj'

puts "🔧 Forcing manual signing configuration\n\n"

# Open the project
project = Xcodeproj::Project.open('Growth.xcodeproj')

# Function to completely remove automatic signing
def force_manual_signing(project, target, profile_name)
  puts "Configuring #{target.name}..."
  
  # First, remove ALL signing attributes from the target
  attributes = project.root_object.attributes['TargetAttributes']
  if attributes && attributes[target.uuid]
    attributes[target.uuid].delete('DevelopmentTeam')
    attributes[target.uuid].delete('ProvisioningStyle')
    attributes[target.uuid].delete('SystemCapabilities')
    puts "  Removed automatic signing attributes"
  end
  
  target.build_configurations.each do |config|
    # Clear ALL signing settings first
    keys_to_remove = []
    config.build_settings.each do |key, value|
      if key.include?("PROVISIONING") || key.include?("CODE_SIGN") || key.include?("DEVELOPMENT_TEAM")
        unless key == "CODE_SIGN_ENTITLEMENTS"
          keys_to_remove << key
        end
      end
    end
    
    keys_to_remove.each do |key|
      config.build_settings.delete(key)
    end
    
    # Now set manual signing
    config.build_settings['CODE_SIGN_STYLE'] = 'Manual'
    config.build_settings['DEVELOPMENT_TEAM'] = '62T6J77P6R'
    
    if config.name == "Release"
      # For Release, use distribution certificate and profile
      config.build_settings['CODE_SIGN_IDENTITY'] = 'iPhone Distribution'
      config.build_settings['CODE_SIGN_IDENTITY[sdk=iphoneos*]'] = 'iPhone Distribution'
      config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = profile_name
      puts "  ✓ #{config.name}: Manual signing with '#{profile_name}'"
    else
      # For Debug, also use manual but with development
      config.build_settings['CODE_SIGN_IDENTITY'] = 'iPhone Developer'
      config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = ''
      puts "  ✓ #{config.name}: Manual signing for development"
    end
  end
end

# Force manual signing for both targets
main_target = project.targets.find { |t| t.name == 'Growth' }
if main_target
  force_manual_signing(project, main_target, 'Growth Labs Connect')
end

widget_target = project.targets.find { |t| t.name == 'GrowthTimerWidgetExtension' }
if widget_target
  force_manual_signing(project, widget_target, 'Growth Labs Widget Connect')
end

# Save the project
project.save

puts "\n✅ Manual signing forced!"
puts "\n⚠️  CRITICAL STEPS:"
puts "1. Open Xcode"
puts "2. You'll see 'Automatically manage signing' is CHECKED"
puts "3. UNCHECK 'Automatically manage signing'"
puts "4. The fields will update to show:"
puts "   - Team: Growth Labs, Inc"
puts "   - Provisioning Profile: Growth Labs Connect"
puts "   - Signing Certificate: Apple Distribution"
puts "5. If it asks to 'Enable Manual Signing', click 'Enable'"
puts "6. Then try archiving"