# Xcode Configuration for Development APNs Key

## Changes Already Made
✅ Updated `Growth/Growth.entitlements` - Changed `aps-environment` from "production" to "development"
✅ Updated `GrowthTimerWidget/GrowthTimerWidget.entitlements` - Changed `aps-environment` from "production" to "development"

## Remaining Xcode Configuration Steps

### 1. Open Project in Xcode
```bash
open /Users/tradeflowj/Desktop/Dev/growth-fresh/Growth.xcodeproj
```

### 2. Switch to Development Provisioning Profile

#### For Main App Target (Growth):
1. Select the **Growth** project in the navigator
2. Select the **Growth** target
3. Go to **Signing & Capabilities** tab
4. Under **Signing**:
   - Ensure "Automatically manage signing" is checked
   - Xcode should automatically update to use a Development provisioning profile
   - You should see "Xcode Managed Profile" or "iOS Team Development Profile"

#### For Widget Target (GrowthTimerWidget):
1. Select the **GrowthTimerWidget** target
2. Go to **Signing & Capabilities** tab
3. Under **Signing**:
   - Ensure "Automatically manage signing" is checked
   - Should also update to Development provisioning profile

### 3. Verify Push Notifications Capability
For both targets, ensure Push Notifications capability shows:
- ✅ Push Notifications
- Environment should show "development" (matches entitlements)

### 4. Clean Build Folder
- Menu: **Product > Clean Build Folder** (⇧⌘K)
- Or from command line:
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/Growth-*
```

### 5. Build and Run
1. Select your physical device (not simulator - Live Activities need real device)
2. Build and run the app (⌘R)
3. Make sure the device is connected via USB or trusted for wireless debugging

### 6. Important Build Settings to Verify

In **Build Settings** for both targets, search for and verify:
- **Code Signing Identity**: Should be "Apple Development" (not "Apple Distribution")
- **Development Team**: Should be set to your team (62T6J77P6R)
- **Provisioning Profile**: Should show "Automatic" or a development profile

### 7. Testing After Build
1. Run the app on your device
2. Start a timer
3. Check if Live Activity appears and updates properly
4. Monitor Firebase logs: `firebase functions:log --only updateLiveActivity`

## Troubleshooting

### If Provisioning Profile Issues:
1. Go to Xcode Preferences > Accounts
2. Select your Apple ID
3. Click "Download Manual Profiles"
4. Try building again

### If Still Getting 403 Errors:
- Verify the development key (378FZMBP8L) exists in Apple Developer portal
- Check it has APNs capability enabled
- Ensure it's not revoked

### Command Line Build (Alternative):
```bash
cd /Users/tradeflowj/Desktop/Dev/growth-fresh
xcodebuild -project Growth.xcodeproj \
  -scheme Growth \
  -configuration Debug \
  -destination 'platform=iOS,name=Your Device Name' \
  clean build
```

## Summary
The key changes for development APNs:
1. ✅ Entitlements changed to `development`
2. ⏳ Need to use Development provisioning profiles in Xcode
3. ⏳ Clean and rebuild with development configuration
4. ⏳ Test on physical device with development build