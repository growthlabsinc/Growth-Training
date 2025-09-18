#!/bin/bash

echo "🔧 Removing ALL provisioning profile settings..."

# 1. Close Xcode
echo "📱 Ensuring Xcode is closed..."
osascript -e 'quit app "Xcode"' 2>/dev/null || true
sleep 2

# 2. Clean workspace settings
echo "🧹 Cleaning workspace settings..."
find . -path "*/xcuserdata/*" -name "*.xcscheme" -delete 2>/dev/null
find . -path "*/xcshareddata/*" -name "*.xcscheme" -exec sed -i '' '/<ProvisioningStyle>/d' {} \; 2>/dev/null

# 3. Remove any .xcworkspace user data
echo "🗑️  Removing xcworkspace user data..."
rm -rf Growth.xcodeproj/project.xcworkspace/xcuserdata/
rm -rf Growth.xcodeproj/xcuserdata/

# 4. Clean pbxproj file completely
echo "📝 Cleaning project file..."
/usr/bin/ruby <<'EOF'
require 'xcodeproj'

project = Xcodeproj::Project.open('Growth.xcodeproj')

# Remove ALL provisioning profile related settings from all configurations
project.targets.each do |target|
  puts "Cleaning target: #{target.name}"
  
  target.build_configurations.each do |config|
    # List of all possible provisioning profile keys
    provisioning_keys = [
      'PROVISIONING_PROFILE',
      'PROVISIONING_PROFILE_SPECIFIER',
      'PROVISIONING_PROFILE[sdk=iphoneos*]',
      'PROVISIONING_PROFILE_SPECIFIER[sdk=iphoneos*]',
      'PROVISIONING_PROFILE[sdk=*]',
      'PROVISIONING_PROFILE_SPECIFIER[sdk=*]'
    ]
    
    # Remove each key
    provisioning_keys.each do |key|
      if config.build_settings.has_key?(key)
        config.build_settings.delete(key)
        puts "  Removed #{key} from #{config.name}"
      end
    end
    
    # Ensure automatic signing
    config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
    config.build_settings['DEVELOPMENT_TEAM'] = '62T6J77P6R'
  end
end

# Also check project-level build settings
project.build_configurations.each do |config|
  ['PROVISIONING_PROFILE', 'PROVISIONING_PROFILE_SPECIFIER'].each do |key|
    config.build_settings.delete(key) if config.build_settings.has_key?(key)
  end
end

project.save
puts "\n✅ All provisioning profile settings removed!"
EOF

# 5. Clear ALL Xcode caches
echo "🚮 Clearing all Xcode caches..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Growth-*
rm -rf ~/Library/Caches/com.apple.dt.Xcode
defaults delete com.apple.dt.Xcode 2>/dev/null || true

# 6. Remove build settings from xcconfig files if they exist
echo "🔍 Checking xcconfig files..."
for file in *.xcconfig; do
  if [ -f "$file" ]; then
    echo "  Cleaning $file..."
    sed -i '' '/PROVISIONING_PROFILE/d' "$file" 2>/dev/null || true
  fi
done

echo ""
echo "✅ Complete provisioning profile cleanup done!"
echo ""
echo "⚠️  IMPORTANT: Next steps:"
echo "1. Open Xcode"
echo "2. For EACH target (Growth and GrowthTimerWidgetExtension):"
echo "   a. Go to Signing & Capabilities"
echo "   b. UNCHECK 'Automatically manage signing'"
echo "   c. Wait 2 seconds"
echo "   d. CHECK 'Automatically manage signing' again"
echo "   e. Select your team"
echo "3. Then archive: Product → Archive"
echo ""
echo "This will force Xcode to completely reset its signing configuration."