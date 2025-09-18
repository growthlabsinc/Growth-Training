#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'Growth.xcodeproj'
project = Xcodeproj::Project.open(project_path)

puts "Fixing Widget Extension for TestFlight..."

# Find the widget extension target
widget_target = project.targets.find { |t| t.name == 'GrowthTimerWidgetExtension' }

if widget_target.nil?
  puts "❌ Widget extension target not found"
  exit 1
end

puts "✅ Found widget extension target: #{widget_target.name}"

# Fix build configurations for Release
widget_target.build_configurations.each do |config|
  if config.name == 'Release'
    puts "\nFixing Release configuration for widget..."
    
    # Set the bundle identifier
    config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.growthlabs.growthmethod.GrowthTimerWidget'
    
    # Set the deployment target
    config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.1'
    
    # Set code signing for production
    config.build_settings['CODE_SIGN_STYLE'] = 'Manual'
    config.build_settings['CODE_SIGN_IDENTITY'] = 'Apple Distribution'
    config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = 'Growth Widget App Store'
    config.build_settings['DEVELOPMENT_TEAM'] = '62T6J77P6R'
    
    # Set entitlements
    config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'GrowthTimerWidget.Production.entitlements'
    
    # Ensure proper module name
    config.build_settings['PRODUCT_MODULE_NAME'] = 'GrowthTimerWidgetExtension'
    
    # Set optimization
    config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-O'
    
    puts "  - Bundle ID: com.growthlabs.growthmethod.GrowthTimerWidget"
    puts "  - Deployment target: 16.1"
    puts "  - Code signing: Manual (Distribution)"
    puts "  - Entitlements: GrowthTimerWidget.Production.entitlements"
  end
end

# Find main app target
main_target = project.targets.find { |t| t.name == 'Growth' }

if main_target
  puts "\n✅ Found main app target: #{main_target.name}"
  
  # Check if widget is embedded
  embed_phase = main_target.copy_files_build_phases.find do |phase|
    phase.name == 'Embed App Extensions' || phase.dst_subfolder_spec == '13'
  end
  
  if embed_phase
    widget_in_embed = embed_phase.files.any? { |f| f.display_name&.include?('GrowthTimerWidget') }
    
    if widget_in_embed
      puts "✅ Widget extension is already embedded"
    else
      puts "⚠️  Widget extension not found in embed phase - needs manual fix in Xcode"
    end
  else
    puts "⚠️  No 'Embed App Extensions' build phase found - needs manual fix in Xcode"
  end
end

# Save the project
project.save

puts "\n✅ Project updated successfully!"
puts "\nNext steps:"
puts "1. Open Xcode"
puts "2. Clean build folder (Shift+Cmd+K)"
puts "3. Archive with 'Growth Production' scheme"
puts "4. Upload to TestFlight"
puts "\nIMPORTANT: You may need to:"
puts "- Create a provisioning profile for 'com.growthlabs.growthmethod.GrowthTimerWidget' in Apple Developer portal"
puts "- Download and install the provisioning profile"
puts "- Ensure the widget extension is included in the 'Embed App Extensions' build phase"