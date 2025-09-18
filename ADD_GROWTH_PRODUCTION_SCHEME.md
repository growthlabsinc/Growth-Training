# How to Add Growth Production Scheme to Xcode

The Growth Production scheme already exists but isn't showing in Xcode. Follow these steps:

## Method 1: Refresh Schemes (Recommended)
1. Click on "Manage Schemes..." (as shown in your screenshot)
2. In the Manage Schemes window:
   - Look for "Growth Production" in the list
   - If it's there but unchecked, check the box next to it
   - Make sure the "Shared" checkbox is also checked
   - Click "Close"

## Method 2: Force Xcode to Reload
1. Close Xcode completely
2. Run this command in Terminal:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```
3. Reopen Xcode and the project
4. The scheme should now appear

## Method 3: If Scheme Still Missing
1. Click "Manage Schemes..."
2. Click the "+" button at bottom left
3. Select:
   - Target: Growth
   - Name: Growth Production
4. Click "OK"
5. Select the new scheme and click "Edit..."
6. Set Build Configuration to "Release" for all actions
7. Make sure "Shared" checkbox is checked

## Verify the Scheme
After adding, you should see in the scheme selector:
- Growth (Debug scheme)
- Growth Production (Release scheme)
- GrowthTimerWidgetExtension

## Current Status
✅ Scheme file exists: `Growth Production.xcscheme`
✅ Scheme is in management plist
✅ Scheme is shared (in xcshareddata)

The scheme should be visible after following Method 1 or 2.