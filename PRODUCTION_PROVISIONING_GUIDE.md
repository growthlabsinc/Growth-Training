# Production Provisioning Profile Update Guide

## Current Status
The app is currently using **development** provisioning profiles with:
- Bundle ID: `com.growthlabs.growthmethod`
- APS Environment: `development`
- This causes BadDeviceToken errors when push notifications are sent to production APNs servers

## Steps to Update to Production Provisioning

### 1. Update Entitlements Files

#### Main App Entitlements
File: `Growth/Growth.entitlements`
```xml
<key>aps-environment</key>
<string>production</string>  <!-- Change from "development" to "production" -->
```

#### Widget Entitlements  
File: `GrowthTimerWidget/GrowthTimerWidget.entitlements`
```xml
<key>aps-environment</key>
<string>production</string>  <!-- Change from "development" to "production" -->
```

### 2. Clean Build Folder
```bash
# In Xcode: Product > Clean Build Folder
# Or via command line:
rm -rf ~/Library/Developer/Xcode/DerivedData/Growth-*
```

### 3. Update Provisioning Profiles in Xcode

1. Open `Growth.xcodeproj` in Xcode
2. Select the `Growth` target
3. Go to "Signing & Capabilities" tab
4. Ensure "Automatically manage signing" is checked
5. Xcode will automatically generate new provisioning profiles with production entitlements

### 4. Repeat for Widget Target

1. Select the `GrowthTimerWidget` target
2. Go to "Signing & Capabilities" tab
3. Ensure "Automatically manage signing" is checked
4. Xcode will update the widget's provisioning profile

### 5. Archive and Upload

1. Select "Any iOS Device" as the destination
2. Product > Archive
3. In the Organizer, select the archive
4. Click "Distribute App"
5. Choose "App Store Connect" (for production)
6. Xcode will use the production provisioning profile

### 6. Update Firebase Functions (Already Done)

The Firebase functions have already been updated to handle both development and production APNs servers with automatic retry logic, so they'll work correctly once the app uses production provisioning.

## Important Notes

### Bundle ID Remains the Same
- The bundle ID `com.growthlabs.growthmethod` stays the same
- Only the provisioning profile type changes from development to production

### APNs Server Selection
- Development provisioning: Uses `api.development.push.apple.com`
- Production provisioning: Uses `api.push.apple.com`
- Push tokens are tied to the provisioning profile type

### Testing Considerations
- Development builds (including TestFlight) can use development provisioning
- App Store releases MUST use production provisioning
- Ad Hoc distribution can use either (but typically production)

## Verification Steps

After updating:

1. Build and run the app
2. Check that push tokens are still being received
3. Verify Live Activity updates work correctly
4. The Firebase functions will automatically use the production APNs server

## Rollback Plan

If you need to revert to development provisioning:

1. Change both entitlements files back to:
   ```xml
   <key>aps-environment</key>
   <string>development</string>
   ```

2. Clean build folder and rebuild

The Firebase functions will continue to work due to the retry logic implemented.

## Environment-Specific Bundle IDs (Alternative Approach)

If you want to maintain separate provisioning for different environments, consider using different bundle IDs:

- Production: `com.growthlabs.growthmethod` (production provisioning)
- Development: `com.growthlabs.growthmethod.dev` (development provisioning)
- Staging: `com.growthlabs.growthmethod.staging` (development provisioning)

This approach allows you to have different provisioning profiles for each environment.