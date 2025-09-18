#!/bin/bash

echo "Fixing SRCROOT path issue..."

# Step 1: Close Xcode if running
echo "Please close Xcode before continuing..."
echo "Press Enter when Xcode is closed..."
read

# Step 2: Remove all derived data and caches
echo "Removing all Xcode caches..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Growth-*
rm -rf ~/Library/Caches/com.apple.dt.Xcode

# Step 3: Remove workspace user data
echo "Removing workspace user data..."
rm -rf Growth.xcodeproj/project.xcworkspace/xcuserdata/
rm -rf Growth.xcodeproj/xcuserdata/

# Step 4: Reset simulator if needed
echo "Resetting simulators (optional but recommended)..."
xcrun simctl shutdown all 2>/dev/null || true

# Step 5: Create correct workspace settings
echo "Creating corrected workspace settings..."
cat > Growth.xcodeproj/project.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>BuildLocationStyle</key>
    <string>UseTargetSettings</string>
    <key>DerivedDataLocationStyle</key>
    <string>Default</string>
    <key>IDEWorkspaceSharedSettings_AutocreateContextsIfNeeded</key>
    <true/>
</dict>
</plist>
EOF

echo ""
echo "Fix applied! Now follow these steps:"
echo "1. Open Terminal and navigate to: cd /Users/tradeflowj/Desktop/Growth"
echo "2. Open the project with: open Growth.xcodeproj"
echo "3. When Xcode opens, it should now use the correct path"
echo "4. Clean Build Folder: Product > Clean Build Folder (Cmd+Shift+K)"
echo "5. Build the project"
echo ""
echo "If the issue persists, you may need to:"
echo "- Select the project in navigator"
echo "- Go to File > Project Settings"
echo "- Change 'Derived Data' to 'Project-relative Location'"
echo "- Then change it back to 'Default'"