#!/bin/bash

echo "🔧 Fixing Archive and Distribution Issues..."

# 1. Clean all build artifacts
echo "📧 Cleaning build artifacts..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Growth-*
rm -rf build/
rm -rf Build/
rm -rf .build/

# 2. Clear provisioning profiles cache
echo "🔐 Clearing provisioning profiles cache..."
rm -rf ~/Library/MobileDevice/Provisioning\ Profiles/

# 3. Reset Swift Package Manager cache
echo "📦 Resetting Swift Package Manager..."
rm -rf .swiftpm/
rm -rf ~/Library/Caches/org.swift.swiftpm/

# 4. Fix code signing identity for distribution
echo "✏️ Updating code signing for distribution..."
/usr/bin/ruby <<EOF
require 'xcodeproj'

project = Xcodeproj::Project.open('Growth.xcodeproj')

# Update all targets for proper distribution signing
project.targets.each do |target|
  next if target.name.include?("Tests")
  
  target.build_configurations.each do |config|
    if config.name == "Release"
      # Remove any manual signing artifacts
      config.build_settings.delete('CODE_SIGN_IDENTITY[sdk=iphoneos*]')
      config.build_settings.delete('PROVISIONING_PROFILE')
      config.build_settings.delete('PROVISIONING_PROFILE_SPECIFIER')
      config.build_settings.delete('PROVISIONING_PROFILE_SPECIFIER[sdk=iphoneos*]')
      
      # Set proper automatic signing
      config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
      config.build_settings['DEVELOPMENT_TEAM'] = '62T6J77P6R'
      # Let Xcode choose the correct identity
      config.build_settings.delete('CODE_SIGN_IDENTITY')
    end
  end
end

project.save
puts "✅ Updated code signing settings for distribution"
EOF

# 5. Verify entitlements files exist
echo "🔍 Checking entitlements..."
if [ ! -f "Growth/Growth.entitlements" ]; then
    echo "⚠️  Warning: Growth.entitlements not found!"
fi

if [ ! -f "GrowthTimerWidgetExtension.entitlements" ]; then
    echo "⚠️  Warning: GrowthTimerWidgetExtension.entitlements not found!"
fi

# 6. Check for GoogleService-Info.plist
echo "🔍 Checking Firebase configuration..."
if [ ! -f "Growth/Resources/Plist/GoogleService-Info.plist" ]; then
    echo "⚠️  Warning: GoogleService-Info.plist not found!"
    echo "   Copying from production config..."
    cp Growth/Resources/Plist/GoogleService-Info.plist.backup-old-bundle-id Growth/Resources/Plist/GoogleService-Info.plist 2>/dev/null || echo "   Could not copy backup"
fi

# 7. Refresh Xcode's understanding of the project
echo "🔄 Refreshing Xcode project..."
xcodebuild -list -project Growth.xcodeproj > /dev/null 2>&1

echo ""
echo "✅ Archive preparation complete!"
echo ""
echo "📋 Next steps:"
echo "1. Open Xcode"
echo "2. Sign out and sign back in to your Apple ID:"
echo "   - Xcode → Settings → Accounts"
echo "   - Remove your account and add it back"
echo "3. Select 'Any iOS Device' as the destination"
echo "4. Product → Archive"
echo "5. In Organizer, select 'Distribute App'"
echo "6. Choose 'App Store Connect'"
echo ""
echo "💡 If you still only see 'Custom':"
echo "   - Ensure you're signed in with an account that has App Manager or Admin role"
echo "   - Check that your team's membership is active at developer.apple.com"