#!/usr/bin/env ruby
# Final fix - Remove specific certificate requirements

require 'xcodeproj'

puts "🔧 Final certificate fix - removing specific certificate requirements\n\n"

project = Xcodeproj::Project.open('Growth.xcodeproj')

# Function to fix certificate issues
def fix_certificates(target)
  puts "Fixing #{target.name}..."
  
  target.build_configurations.each do |config|
    if config.name == "Release"
      # Remove any specific certificate requirements
      config.build_settings.delete('CERTIFICATE_SHA1')
      config.build_settings.delete('CODE_SIGN_IDENTITY')
      config.build_settings.delete('CODE_SIGN_IDENTITY[sdk=iphoneos*]')
      config.build_settings.delete('CODE_SIGN_IDENTITY[sdk=*]')
      
      # Keep only essential settings
      config.build_settings['CODE_SIGN_STYLE'] = 'Manual'
      config.build_settings['DEVELOPMENT_TEAM'] = '62T6J77P6R'
      
      # Keep the profile specifier
      if target.name == "Growth"
        config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = 'Growth Labs Connect'
      elsif target.name == "GrowthTimerWidgetExtension"
        config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = 'Growth Labs Widget Connect'
      end
      
      puts "  ✓ #{config.name}: Removed certificate requirements"
    end
  end
end

# Fix both targets
['Growth', 'GrowthTimerWidgetExtension'].each do |target_name|
  target = project.targets.find { |t| t.name == target_name }
  if target
    fix_certificates(target)
  end
end

project.save

puts "\n✅ Certificate requirements removed!"
puts "\nWhat this does:"
puts "- Removes specific certificate requirements"
puts "- Lets Xcode use ANY valid certificate from the provisioning profile"
puts "- Should resolve the 'doesn't include signing certificate' error"
puts "\nNext steps:"
puts "1. In Xcode, click somewhere else then back to Signing & Capabilities"
puts "2. The error should clear"
puts "3. Try Product → Archive"