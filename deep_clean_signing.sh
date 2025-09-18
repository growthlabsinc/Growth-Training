#!/bin/bash

echo "🧹 Deep cleaning all signing settings..."

# 1. Kill Xcode if running
echo "📱 Closing Xcode..."
osascript -e 'quit app "Xcode"' 2>/dev/null || true
sleep 2

# 2. Clean ALL Xcode caches
echo "🗑️  Cleaning all Xcode caches..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Growth-*
rm -rf ~/Library/Caches/com.apple.dt.Xcode
rm -rf ~/Library/Developer/Xcode/UserData/IDEEditorInteractivityHistory
rm -rf ~/Library/Developer/Xcode/UserData/IDEFindNavigatorScopes.plist

# 3. Remove any xcuserdata that might have signing overrides
echo "🔧 Removing user-specific project data..."
find . -name "*.xcodeproj" -exec rm -rf {}/project.xcworkspace/xcuserdata \; 2>/dev/null
find . -name "*.xcodeproj" -exec rm -rf {}/xcuserdata \; 2>/dev/null

# 4. Reset project signing at the project level
echo "🔐 Resetting all signing configurations..."
/usr/bin/ruby <<'EOF'
require 'xcodeproj'

project = Xcodeproj::Project.open('Growth.xcodeproj')

# Clean all targets
project.targets.each do |target|
  next if target.name.include?("Tests")
  
  puts "Cleaning target: #{target.name}"
  
  target.build_configurations.each do |config|
    # Remove ALL code signing related settings
    keys_to_remove = config.build_settings.keys.select { |k| k.include?("CODE_SIGN") && !k.include?("ENTITLEMENTS") }
    keys_to_remove.each { |k| config.build_settings.delete(k) }
    
    # Remove provisioning profile settings
    config.build_settings.delete("PROVISIONING_PROFILE")
    config.build_settings.delete("PROVISIONING_PROFILE_SPECIFIER")
    config.build_settings.keys.select { |k| k.include?("PROVISIONING_PROFILE") }.each { |k| config.build_settings.delete(k) }
    
    # Set only the essential signing settings
    config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
    config.build_settings['DEVELOPMENT_TEAM'] = '62T6J77P6R'
    
    puts "  ✓ #{config.name}: Automatic signing, Team: 62T6J77P6R"
  end
end

# Also clean project-level settings
project.build_configurations.each do |config|
  keys_to_remove = config.build_settings.keys.select { |k| k.include?("CODE_SIGN_IDENTITY") }
  keys_to_remove.each { |k| config.build_settings.delete(k) }
  config.build_settings.delete("PROVISIONING_PROFILE_SPECIFIER")
end

project.save
puts "\n✅ Project signing reset complete!"
EOF

echo ""
echo "✅ Deep clean complete!"
echo ""
echo "📋 Next steps:"
echo "1. Open Xcode fresh"
echo "2. Wait for indexing to complete"
echo "3. Select 'Any iOS Device (arm64)' as destination"
echo "4. Product → Clean Build Folder (Shift+Cmd+K)"
echo "5. Product → Archive"
echo ""
echo "The 'Apple Distribution' conflict should now be completely resolved."