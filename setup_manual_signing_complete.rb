#!/usr/bin/env ruby
# Complete manual signing setup for App Store distribution

require 'xcodeproj'

# ANSI color codes
RED = "\e[31m"
GREEN = "\e[32m"
YELLOW = "\e[33m"
BLUE = "\e[34m"
RESET = "\e[0m"

puts "#{BLUE}🔧 Setting up manual signing for App Store distribution#{RESET}\n\n"

# Configuration
TEAM_ID = '62T6J77P6R'
MAIN_BUNDLE_ID = 'com.growthlabs.growthmethod'
WIDGET_BUNDLE_ID = 'com.growthlabs.growthmethod.GrowthTimerWidget'
MAIN_PROFILE = 'Growth App Store Distribution'
WIDGET_PROFILE = 'Growth Timer Widget App Store'

begin
  project = Xcodeproj::Project.open('Growth.xcodeproj')
  
  # Function to configure manual signing
  def configure_target_for_manual_signing(target, team_id, bundle_id, profile_name)
    puts "#{BLUE}Configuring #{target.name}...#{RESET}"
    
    target.build_configurations.each do |config|
      # Clear existing settings first
      settings_to_remove = []
      config.build_settings.each do |key, value|
        if key.include?("PROVISIONING") || key.include?("CODE_SIGN")
          unless key == "CODE_SIGN_ENTITLEMENTS"
            settings_to_remove << key
          end
        end
      end
      
      settings_to_remove.each { |key| config.build_settings.delete(key) }
      
      # Set bundle identifier
      config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = bundle_id
      
      # Configure manual signing
      config.build_settings['CODE_SIGN_STYLE'] = 'Manual'
      config.build_settings['DEVELOPMENT_TEAM'] = team_id
      
      if config.name == 'Debug'
        # Debug configuration
        config.build_settings['CODE_SIGN_IDENTITY'] = 'Apple Development'
        config.build_settings['CODE_SIGN_IDENTITY[sdk=iphoneos*]'] = 'Apple Development'
        # Leave profile empty for automatic matching in Debug
        config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = ''
        puts "  #{GREEN}✓ #{config.name}: Development signing#{RESET}"
      else
        # Release configuration (for App Store)
        config.build_settings['CODE_SIGN_IDENTITY'] = 'Apple Distribution'
        config.build_settings['CODE_SIGN_IDENTITY[sdk=iphoneos*]'] = 'Apple Distribution'
        config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = profile_name
        puts "  #{GREEN}✓ #{config.name}: Distribution signing with '#{profile_name}'#{RESET}"
      end
    end
  end
  
  # Configure main app target
  growth_target = project.targets.find { |t| t.name == 'Growth' }
  if growth_target
    configure_target_for_manual_signing(growth_target, TEAM_ID, MAIN_BUNDLE_ID, MAIN_PROFILE)
  else
    puts "#{RED}❌ Could not find Growth target#{RESET}"
    exit 1
  end
  
  # Configure widget target
  widget_target = project.targets.find { |t| t.name == 'GrowthTimerWidgetExtension' }
  if widget_target
    configure_target_for_manual_signing(widget_target, TEAM_ID, WIDGET_BUNDLE_ID, WIDGET_PROFILE)
  else
    puts "#{YELLOW}⚠️  Widget target not found (this might be okay if you don't have a widget)#{RESET}"
  end
  
  # Update ExportOptions.plist for manual signing
  puts "\n#{BLUE}Updating ExportOptions.plist...#{RESET}"
  
  export_options_content = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>#{TEAM_ID}</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>signingCertificate</key>
    <string>Apple Distribution</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>#{MAIN_BUNDLE_ID}</key>
        <string>#{MAIN_PROFILE}</string>
        <key>#{WIDGET_BUNDLE_ID}</key>
        <string>#{WIDGET_PROFILE}</string>
    </dict>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>thinning</key>
    <string>&lt;thin-for-all-variants&gt;</string>
    <key>generateAppStoreInformation</key>
    <true/>
    <key>manageAppVersionAndBuildNumber</key>
    <true/>
</dict>
</plist>
XML
  
  File.write('ExportOptions.plist', export_options_content)
  puts "#{GREEN}✓ ExportOptions.plist updated#{RESET}"
  
  # Save project
  project.save
  
  puts "\n#{GREEN}✅ Manual signing configuration complete!#{RESET}"
  
  # Check for installed profiles
  puts "\n#{BLUE}Checking for installed provisioning profiles...#{RESET}"
  profiles_path = File.expand_path("~/Library/MobileDevice/Provisioning Profiles")
  
  if Dir.exist?(profiles_path)
    profiles = Dir.glob("#{profiles_path}/*.mobileprovision")
    puts "Found #{profiles.count} provisioning profile(s) installed"
    
    # Try to find our specific profiles
    main_found = false
    widget_found = false
    
    profiles.each do |profile|
      content = `security cms -D -i "#{profile}" 2>/dev/null`
      if content.include?(MAIN_BUNDLE_ID) && content.include?("ProvisionsAllDevices")
        main_found = true
      end
      if content.include?(WIDGET_BUNDLE_ID) && content.include?("ProvisionsAllDevices")
        widget_found = true
      end
    end
    
    puts "#{main_found ? GREEN + '✓' : RED + '✗'} #{MAIN_PROFILE} #{main_found ? 'found' : 'NOT FOUND'}#{RESET}"
    puts "#{widget_found ? GREEN + '✓' : RED + '✗'} #{WIDGET_PROFILE} #{widget_found ? 'found' : 'NOT FOUND'}#{RESET}"
  else
    puts "#{YELLOW}⚠️  No provisioning profiles directory found#{RESET}"
  end
  
  # Final instructions
  puts "\n#{YELLOW}📋 Next Steps:#{RESET}"
  puts "1. #{BLUE}Download missing profiles:#{RESET}"
  puts "   https://developer.apple.com/account/resources/profiles/list"
  puts ""
  puts "2. #{BLUE}Required profiles:#{RESET}"
  puts "   • #{MAIN_PROFILE} (Type: App Store)"
  puts "   • #{WIDGET_PROFILE} (Type: App Store)"
  puts ""
  puts "3. #{BLUE}Install profiles:#{RESET}"
  puts "   Double-click each downloaded .mobileprovision file"
  puts ""
  puts "4. #{BLUE}In Xcode:#{RESET}"
  puts "   • Clean Build Folder (Shift+Cmd+K)"
  puts "   • Select 'Any iOS Device (arm64)' as destination"
  puts "   • Product → Archive"
  puts ""
  puts "5. #{BLUE}In Organizer:#{RESET}"
  puts "   • Click 'Distribute App'"
  puts "   • You should see 'App Store Connect' option"
  
rescue => e
  puts "#{RED}❌ Error: #{e.message}#{RESET}"
  puts e.backtrace
  exit 1
end