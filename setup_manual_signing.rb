#!/usr/bin/env ruby
# Setup manual signing with correct certificates and profiles

require 'xcodeproj'

project = Xcodeproj::Project.open('Growth.xcodeproj')

# Configure Growth target for manual signing
growth_target = project.targets.find { |t| t.name == 'Growth' }
if growth_target
  growth_target.build_configurations.each do |config|
    config.build_settings['CODE_SIGN_STYLE'] = 'Manual'
    config.build_settings['DEVELOPMENT_TEAM'] = '62T6J77P6R'
    
    if config.name == 'Debug'
      # Debug uses development certificate
      config.build_settings['CODE_SIGN_IDENTITY'] = 'Apple Development'
      config.build_settings['CODE_SIGN_IDENTITY[sdk=iphoneos*]'] = 'Apple Development'
      config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = ''  # Let Xcode match automatically
    else  # Release
      # Release uses distribution certificate
      config.build_settings['CODE_SIGN_IDENTITY'] = 'Apple Distribution'
      config.build_settings['CODE_SIGN_IDENTITY[sdk=iphoneos*]'] = 'Apple Distribution'
      config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = 'Growth App Store Distribution'
    end
    
    puts "✅ Configured #{config.name} for Growth target"
  end
end

# Configure Widget target for manual signing
widget_target = project.targets.find { |t| t.name == 'GrowthTimerWidgetExtension' }
if widget_target
  widget_target.build_configurations.each do |config|
    config.build_settings['CODE_SIGN_STYLE'] = 'Manual'
    config.build_settings['DEVELOPMENT_TEAM'] = '62T6J77P6R'
    
    if config.name == 'Debug'
      # Debug uses development certificate
      config.build_settings['CODE_SIGN_IDENTITY'] = 'Apple Development'
      config.build_settings['CODE_SIGN_IDENTITY[sdk=iphoneos*]'] = 'Apple Development'
      config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = ''  # Let Xcode match automatically
    else  # Release
      # Release uses distribution certificate
      config.build_settings['CODE_SIGN_IDENTITY'] = 'Apple Distribution'
      config.build_settings['CODE_SIGN_IDENTITY[sdk=iphoneos*]'] = 'Apple Distribution'
      # You'll need to create/download the widget distribution profile
      config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = 'Growth Timer Widget App Store'
    end
    
    puts "✅ Configured #{config.name} for Widget target"
  end
end

project.save
puts "\n✅ Manual signing configured!"
puts "\n📋 Next steps:"
puts "1. Go to https://developer.apple.com/account/resources/profiles/list"
puts "2. Verify these profiles exist and are valid:"
puts "   - Growth App Store Distribution (for main app)"
puts "   - Growth Timer Widget App Store (for widget)"
puts "3. If missing, create them with:"
puts "   - Type: App Store"
puts "   - App ID: Your app's ID"
puts "   - Certificate: Apple Distribution (Jon Webb)"
puts "4. Download and double-click to install"
puts "5. Then try archiving again"