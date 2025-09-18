#!/usr/bin/env ruby
# Update project to use the actual profile names

require 'xcodeproj'

puts "🔧 Updating profile names to match your downloaded profiles...\n"

project = Xcodeproj::Project.open('Growth.xcodeproj')

# Update main app target
main_target = project.targets.find { |t| t.name == 'Growth' }
if main_target
  main_target.build_configurations.each do |config|
    if config.name == 'Release'
      config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = 'Growth Labs Connect'
      puts "✓ Updated Growth target to use 'Growth Labs Connect'"
    end
  end
end

# Update widget target
widget_target = project.targets.find { |t| t.name == 'GrowthTimerWidgetExtension' }
if widget_target
  widget_target.build_configurations.each do |config|
    if config.name == 'Release'
      config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = 'Growth Labs Widget Connect'
      puts "✓ Updated Widget target to use 'Growth Labs Widget Connect'"
    end
  end
end

project.save

# Also update ExportOptions.plist
export_options = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>62T6J77P6R</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>com.growthlabs.growthmethod</key>
        <string>Growth Labs Connect</string>
        <key>com.growthlabs.growthmethod.GrowthTimerWidget</key>
        <string>Growth Labs Widget Connect</string>
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

File.write('ExportOptions.plist', export_options)
puts "✓ Updated ExportOptions.plist"

puts "\n✅ Profile names updated!"
puts "\nNow you can:"
puts "1. Open Xcode"
puts "2. Clean Build Folder (Shift+Cmd+K)"
puts "3. Archive your project"
puts "4. Distribute to App Store Connect"