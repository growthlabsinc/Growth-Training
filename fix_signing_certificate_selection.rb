#!/usr/bin/env ruby
# Force Xcode to use the certificate that's in the provisioning profile

require 'xcodeproj'

puts "🔧 Fixing certificate selection to match provisioning profile\n\n"

project = Xcodeproj::Project.open('Growth.xcodeproj')

# Function to clear specific certificate selection
def fix_certificate_selection(target)
  puts "Fixing #{target.name}..."
  
  target.build_configurations.each do |config|
    # Remove ALL certificate-specific settings
    keys_to_remove = []
    config.build_settings.each do |key, value|
      if key.include?("CODE_SIGN_IDENTITY") && key != "CODE_SIGN_ENTITLEMENTS"
        keys_to_remove << key
      end
    end
    
    keys_to_remove.each do |key|
      config.build_settings.delete(key)
      puts "  Removed #{key}"
    end
    
    # For Release, don't specify ANY certificate - let it match the profile
    if config.name == "Release"
      # Don't set CODE_SIGN_IDENTITY at all - let Xcode pick from profile
      puts "  #{config.name}: Will use certificate from provisioning profile"
    elsif config.name == "Debug"
      # For Debug, use automatic
      config.build_settings['CODE_SIGN_IDENTITY'] = 'iPhone Developer'
      puts "  #{config.name}: Set to iPhone Developer"
    end
  end
end

# Fix both targets
['Growth', 'GrowthTimerWidgetExtension'].each do |target_name|
  target = project.targets.find { |t| t.name == target_name }
  if target
    fix_certificate_selection(target)
  end
end

project.save

puts "\n✅ Fixed! Certificate will now be selected from provisioning profile"
puts "\nIMPORTANT: In Xcode, for each target:"
puts "1. Go to Build Settings"
puts "2. Search for 'CODE_SIGN_IDENTITY'"
puts "3. For Release, it should be empty or show 'Automatic'"
puts "4. This allows Xcode to use the certificate embedded in the profile"