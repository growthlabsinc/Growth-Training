# Manual Fix for Xcode Path Issues

If the automated script doesn't work, try these manual steps:

## Method 1: Re-add Project to Xcode
1. Close Xcode completely
2. In Finder, navigate to `/Users/tradeflowj/Desktop/Growth/`
3. Double-click `Growth.xcodeproj` to open it in Xcode
4. Xcode should now recognize the correct path

## Method 2: Fix via Xcode UI
1. In Xcode, select the Growth project in the navigator
2. Go to **File → Project Settings**
3. Look for "Derived Data" location
4. If it shows the old path, click "Advanced"
5. Select "Default" or "Unique" 
6. Click "Done"

## Method 3: Complete Reset
1. Close Xcode
2. In Terminal:
   ```bash
   cd /Users/tradeflowj/Desktop/Growth
   
   # Remove all Xcode-specific files
   find . -name "*.xcuserstate" -delete
   find . -name "xcuserdata" -type d -exec rm -rf {} +
   
   # Remove workspace data
   rm -rf Growth.xcodeproj/project.xcworkspace/xcuserdata
   rm -rf Growth.xcodeproj/project.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist
   
   # Clear all Xcode caches
   rm -rf ~/Library/Developer/Xcode/DerivedData/*
   rm -rf ~/Library/Caches/com.apple.dt.Xcode/*
   
   # Restart Xcode
   killall Xcode 2>/dev/null || true
   ```
3. Open the project fresh from the correct location

## Method 4: Check Build Settings
1. Select the Growth target
2. Go to Build Settings tab
3. Search for "SRCROOT"
4. If you see any custom values, delete them to use defaults
5. Also check:
   - CODE_SIGN_ENTITLEMENTS = Growth/Growth.entitlements
   - Any other paths should be relative, not absolute

## Verification
After applying any fix:
1. Clean Build Folder (Cmd+Shift+K)
2. Build the project
3. Check that build succeeds without path errors