#!/usr/bin/env ruby
# Fix bundle identifier for App Store distribution

require 'xcodeproj'

project = Xcodeproj::Project.open('Growth.xcodeproj')

# Fix main app bundle identifier
main_target = project.targets.find { |t| t.name == 'Growth' }
if main_target
  main_target.build_configurations.each do |config|
    # Set production bundle ID for Release, dev for Debug
    if config.name == 'Release'
      config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.growthlabs.growthmethod'
      puts "✅ Set Release bundle ID to: com.growthlabs.growthmethod"
    else
      config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.growthlabs.growthmethod.dev'
      puts "✅ Set Debug bundle ID to: com.growthlabs.growthmethod.dev"
    end
  end
end

# Fix widget bundle identifier
widget_target = project.targets.find { |t| t.name == 'GrowthTimerWidgetExtension' }
if widget_target
  widget_target.build_configurations.each do |config|
    if config.name == 'Release'
      config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.growthlabs.growthmethod.GrowthTimerWidget'
      puts "✅ Set Widget Release bundle ID to: com.growthlabs.growthmethod.GrowthTimerWidget"
    else
      config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.growthlabs.growthmethod.dev.GrowthTimerWidget'
      puts "✅ Set Widget Debug bundle ID to: com.growthlabs.growthmethod.dev.GrowthTimerWidget"
    end
  end
end

project.save
puts ""
puts "✅ Bundle identifiers fixed!"
puts "   Release builds will use production bundle IDs"
puts "   Debug builds will use .dev bundle IDs"