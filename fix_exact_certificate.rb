#!/usr/bin/env ruby
# Fix Xcode to use the exact certificate from the provisioning profile

require 'xcodeproj'

puts "🔧 Fixing Xcode to use the correct certificate\n\n"

# The certificate SHA1 from your provisioning profile
CORRECT_CERT_SHA1 = "93ACE079DBB37C8362E80B87EDD6D385BF7DF52E"

project = Xcodeproj::Project.open('Growth.xcodeproj')

# Function to set exact certificate
def set_exact_certificate(target, cert_sha1)
  puts "Configuring #{target.name}..."
  
  target.build_configurations.each do |config|
    if config.name == "Release"
      # For manual signing with specific certificate
      config.build_settings['CODE_SIGN_STYLE'] = 'Manual'
      config.build_settings['DEVELOPMENT_TEAM'] = '62T6J77P6R'
      
      # Use the exact certificate SHA1
      config.build_settings['CERTIFICATE_SHA1'] = cert_sha1
      config.build_settings['CODE_SIGN_IDENTITY'] = "Apple Distribution: Growth Labs, Inc (62T6J77P6R)"
      config.build_settings['CODE_SIGN_IDENTITY[sdk=iphoneos*]'] = "Apple Distribution: Growth Labs, Inc (62T6J77P6R)"
      
      # Keep the profile names
      if target.name == "Growth"
        config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = 'Growth Labs Connect'
      elsif target.name == "GrowthTimerWidgetExtension"
        config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = 'Growth Labs Widget Connect'
      end
      
      puts "  ✓ #{config.name}: Set to use certificate #{cert_sha1[0..7]}..."
    elsif config.name == "Debug"
      config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
      config.build_settings.delete('CERTIFICATE_SHA1')
      config.build_settings.delete('CODE_SIGN_IDENTITY[sdk=iphoneos*]')
      puts "  ✓ #{config.name}: Automatic signing"
    end
  end
end

# Fix both targets
['Growth', 'GrowthTimerWidgetExtension'].each do |target_name|
  target = project.targets.find { |t| t.name == target_name }
  if target
    set_exact_certificate(target, CORRECT_CERT_SHA1)
  end
end

project.save

puts "\n✅ Fixed to use certificate: #{CORRECT_CERT_SHA1}"
puts "\nIMPORTANT:"
puts "1. Close Xcode completely"
puts "2. Run: rm -rf ~/Library/Developer/Xcode/DerivedData/*"
puts "3. Reopen Xcode"
puts "4. The errors should now be resolved"
puts "\nIf errors persist:"
puts "- Go to Keychain Access"
puts "- Find 'Apple Distribution: Growth Labs, Inc'"
puts "- Check you have the one with fingerprint: 93:AC:E0:79..."