#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'Growth.xcodeproj'
project = Xcodeproj::Project.open(project_path)

puts "Reverting Widget Extension to Automatic Signing..."

# Find the widget extension target
widget_target = project.targets.find { |t| t.name == 'GrowthTimerWidgetExtension' }

if widget_target.nil?
  puts "❌ Widget extension target not found"
  exit 1
end

puts "✅ Found widget extension target: #{widget_target.name}"

# Fix build configurations for Release to use automatic signing
widget_target.build_configurations.each do |config|
  if config.name == 'Release'
    puts "\nReverting Release configuration to automatic signing..."
    
    # Set the bundle identifier
    config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.growthlabs.growthmethod.GrowthTimerWidget'
    
    # Set the deployment target
    config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.1'
    
    # Revert to automatic code signing
    config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
    config.build_settings.delete('CODE_SIGN_IDENTITY')
    config.build_settings.delete('PROVISIONING_PROFILE_SPECIFIER')
    config.build_settings['DEVELOPMENT_TEAM'] = '62T6J77P6R'
    
    # Set entitlements
    config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'GrowthTimerWidget.Production.entitlements'
    
    # Ensure proper module name
    config.build_settings['PRODUCT_MODULE_NAME'] = 'GrowthTimerWidgetExtension'
    
    # Set optimization
    config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-O'
    
    puts "  - Bundle ID: com.growthlabs.growthmethod.GrowthTimerWidget"
    puts "  - Deployment target: 16.1"
    puts "  - Code signing: Automatic"
    puts "  - Development Team: 62T6J77P6R"
    puts "  - Entitlements: GrowthTimerWidget.Production.entitlements"
  elsif config.name == 'Debug'
    puts "\nEnsuring Debug configuration uses automatic signing..."
    
    # Ensure Debug also uses automatic signing
    config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
    config.build_settings.delete('CODE_SIGN_IDENTITY')
    config.build_settings.delete('PROVISIONING_PROFILE_SPECIFIER')
    config.build_settings['DEVELOPMENT_TEAM'] = '62T6J77P6R'
    
    puts "  - Code signing: Automatic"
    puts "  - Development Team: 62T6J77P6R"
  end
end

# Find main app target and ensure it also uses automatic signing
main_target = project.targets.find { |t| t.name == 'Growth' }

if main_target
  puts "\n✅ Found main app target: #{main_target.name}"
  
  main_target.build_configurations.each do |config|
    if config.name == 'Release'
      puts "\nEnsuring main app Release uses automatic signing..."
      config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
      config.build_settings.delete('PROVISIONING_PROFILE_SPECIFIER')
      config.build_settings['DEVELOPMENT_TEAM'] = '62T6J77P6R'
      puts "  - Code signing: Automatic"
    end
  end
  
  # Check if widget is embedded
  embed_phase = main_target.copy_files_build_phases.find do |phase|
    phase.name == 'Embed App Extensions' || phase.dst_subfolder_spec == '13'
  end
  
  if embed_phase
    widget_in_embed = embed_phase.files.any? { |f| f.display_name&.include?('GrowthTimerWidget') }
    
    if widget_in_embed
      puts "\n✅ Widget extension is properly embedded"
    else
      puts "\n⚠️  Widget extension not found in embed phase - needs manual fix in Xcode"
    end
  else
    puts "\n⚠️  No 'Embed App Extensions' build phase found - needs manual fix in Xcode"
  end
end

# Save the project
project.save

puts "\n✅ Project updated successfully!"
puts "\n🎯 AUTOMATIC SIGNING RESTORED"
puts "\nXcode will now automatically manage provisioning profiles for:"
puts "- Main app: com.growthlabs.growthmethod"
puts "- Widget: com.growthlabs.growthmethod.GrowthTimerWidget"
puts "\nNext steps:"
puts "1. Open Xcode"
puts "2. Clean build folder (Shift+Cmd+K)"
puts "3. Select 'Growth Production' scheme"
puts "4. Archive (Product > Archive)"
puts "5. Upload to TestFlight"
puts "\nXcode will automatically create and use the correct provisioning profiles."