#!/usr/bin/env ruby
# Force automatic signing by removing ALL manual signing settings

require 'xcodeproj'

project = Xcodeproj::Project.open('Growth.xcodeproj')

# Process all targets
project.targets.each do |target|
  puts "Processing target: #{target.name}"
  
  target.build_configurations.each do |config|
    # Remove ALL signing-related settings
    settings_to_remove = []
    
    config.build_settings.each do |key, value|
      if key.include?("CODE_SIGN") || key.include?("PROVISIONING")
        unless key == "CODE_SIGN_ENTITLEMENTS" # Keep entitlements
          settings_to_remove << key
        end
      end
    end
    
    # Remove the settings
    settings_to_remove.each do |key|
      config.build_settings.delete(key)
      puts "  Removed #{key} from #{config.name}"
    end
    
    # Set ONLY automatic signing
    config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
    config.build_settings['DEVELOPMENT_TEAM'] = '62T6J77P6R'
    
    puts "  #{config.name}: Set to Automatic signing with team 62T6J77P6R"
  end
end

project.save
puts "\n✅ Forced automatic signing for all targets!"
puts "\n⚠️  CRITICAL: You MUST now:"
puts "1. Open Xcode"
puts "2. Click on each target that shows errors"
puts "3. In Signing & Capabilities, toggle 'Automatically manage signing' OFF then ON"
puts "4. This will regenerate the proper automatic provisioning profiles"