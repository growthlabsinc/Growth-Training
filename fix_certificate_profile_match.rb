#!/usr/bin/env ruby
# Fix certificate and profile mismatch

require 'xcodeproj'
require 'json'

# Colors
RED = "\e[31m"
GREEN = "\e[32m"
YELLOW = "\e[33m"
BLUE = "\e[34m"
RESET = "\e[0m"

puts "#{BLUE}🔧 Fixing Certificate-Profile Mismatch#{RESET}\n\n"

# Get the latest certificate (by creation date)
puts "#{BLUE}Finding your latest Apple Distribution certificate...#{RESET}"
cert_output = `security find-identity -v -p codesigning | grep "Apple Distribution: Growth Labs"`
certs = cert_output.split("\n").map { |line| line.match(/([A-F0-9]{40})/) ? $1 : nil }.compact

if certs.empty?
  puts "#{RED}❌ No Apple Distribution certificates found!#{RESET}"
  exit 1
end

# Use the last certificate (usually the newest)
latest_cert = certs.last
puts "#{GREEN}✓ Using certificate: #{latest_cert}#{RESET}"

# Open project
project = Xcodeproj::Project.open('Growth.xcodeproj')

# Configuration
TEAM_ID = '62T6J77P6R'
MAIN_BUNDLE_ID = 'com.growthlabs.growthmethod'
WIDGET_BUNDLE_ID = 'com.growthlabs.growthmethod.GrowthTimerWidget'

# Fix function
def fix_target_signing(target, team_id, bundle_id, profile_name, cert_sha)
  puts "\n#{BLUE}Fixing #{target.name}...#{RESET}"
  
  target.build_configurations.each do |config|
    if config.name == 'Release'
      # Clear all existing signing settings
      keys_to_remove = config.build_settings.keys.select { |k| k.include?('CODE_SIGN') || k.include?('PROVISIONING') }
      keys_to_remove.each { |key| config.build_settings.delete(key) unless key == 'CODE_SIGN_ENTITLEMENTS' }
      
      # Set manual signing with specific certificate
      config.build_settings['CODE_SIGN_STYLE'] = 'Manual'
      config.build_settings['DEVELOPMENT_TEAM'] = team_id
      config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = bundle_id
      
      # Use generic Apple Distribution (Xcode will match with the profile's certificate)
      config.build_settings['CODE_SIGN_IDENTITY'] = 'Apple Distribution'
      config.build_settings['CODE_SIGN_IDENTITY[sdk=iphoneos*]'] = 'Apple Distribution'
      
      # Set the profile name only
      config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = profile_name
      
      # Remove any specific certificate references
      config.build_settings.delete('CODE_SIGN_IDENTITY[sdk=*]')
      config.build_settings.delete('PROVISIONING_PROFILE')
      
      puts "  #{GREEN}✓ #{config.name} configured with profile: #{profile_name}#{RESET}"
    elsif config.name == 'Debug'
      # For Debug, use automatic signing
      config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
      config.build_settings['DEVELOPMENT_TEAM'] = team_id
      config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = bundle_id
      config.build_settings.delete('PROVISIONING_PROFILE_SPECIFIER')
      config.build_settings.delete('CODE_SIGN_IDENTITY[sdk=iphoneos*]')
      puts "  #{GREEN}✓ #{config.name} set to automatic signing#{RESET}"
    end
  end
end

# Fix main app
main_target = project.targets.find { |t| t.name == 'Growth' }
if main_target
  fix_target_signing(main_target, TEAM_ID, MAIN_BUNDLE_ID, 'Growth App Store Distribution', latest_cert)
end

# Fix widget
widget_target = project.targets.find { |t| t.name == 'GrowthTimerWidgetExtension' }
if widget_target
  fix_target_signing(widget_target, TEAM_ID, WIDGET_BUNDLE_ID, 'Growth Timer Widget App Store', latest_cert)
end

# Save
project.save

puts "\n#{BLUE}Cleaning provisioning profile cache...#{RESET}"
# Force Xcode to re-read profiles
`rm -rf ~/Library/MobileDevice/Provisioning\\ Profiles/*.mobileprovision 2>/dev/null`
puts "#{GREEN}✓ Profile cache cleared#{RESET}"

puts "\n#{GREEN}✅ Certificate-Profile mismatch fixed!#{RESET}"
puts "\n#{YELLOW}Next steps:#{RESET}"
puts "1. Open Xcode"
puts "2. Go to Xcode → Settings → Accounts"
puts "3. Click 'Download Manual Profiles'"
puts "4. For each target in Signing & Capabilities:"
puts "   - The provisioning profile dropdown should now show your profiles"
puts "   - If not, click the dropdown and select 'Download Profile...'"
puts "   - Navigate to your downloaded .mobileprovision files"
puts "5. Archive your project"

puts "\n#{BLUE}If still having issues:#{RESET}"
puts "- Make sure your profiles were created with certificate: #{latest_cert[0..7]}..."
puts "- You can verify this in the Apple Developer portal"