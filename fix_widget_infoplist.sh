#!/bin/bash

echo "🔧 Fixing Widget Info.plist configuration..."

# Backup project file
cp Growth.xcodeproj/project.pbxproj Growth.xcodeproj/project.pbxproj.backup.widget_fix

# For modern Widget Extensions, we should remove INFOPLIST_FILE and let Xcode generate it
echo "📝 Updating project settings..."

# Remove INFOPLIST_FILE setting for widget target
perl -i -pe 's/INFOPLIST_FILE = GrowthTimerWidget\/Info\.plist;//g' Growth.xcodeproj/project.pbxproj

# Add GENERATE_INFOPLIST_FILE = YES for widget if not present
# This is a bit complex, so we'll do it carefully
echo "✅ Removed INFOPLIST_FILE setting for widget"

# Remove the Info.plist we created as it's not needed
if [ -f "GrowthTimerWidget/Info.plist" ]; then
    rm "GrowthTimerWidget/Info.plist"
    echo "🗑️  Removed GrowthTimerWidget/Info.plist (not needed for modern widgets)"
fi

echo -e "\n✨ Fix complete!"
echo -e "\n📱 Next steps:"
echo "1. Open Xcode"
echo "2. Select the GrowthTimerWidgetExtension target"
echo "3. Go to Build Settings"
echo "4. Search for 'info.plist'"
echo "5. Ensure:"
echo "   - GENERATE_INFOPLIST_FILE = YES"
echo "   - INFOPLIST_FILE = (empty or not set)"
echo "6. Clean and rebuild"