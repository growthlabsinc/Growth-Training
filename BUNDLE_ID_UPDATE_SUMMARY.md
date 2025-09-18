# Bundle Identifier Update Summary

## Date: 2025-07-09

## Overview
Successfully updated all bundle identifiers from `com.growth*` patterns to `com.growthlabs.growthmethod*`.

## Files Updated

### 1. Xcode Project Configuration
- **File**: `Growth.xcodeproj/project.pbxproj`
- **Changes**:
  - Main app: `com.growthtraining.Growth` → `com.growthlabs.growthmethod`
  - Tests: `com.growthtraining.GrowthTests` → `com.growthlabs.growthmethod.Tests`
  - UI Tests: `com.growthtraining.GrowthUITests` → `com.growthlabs.growthmethod.UITests`
  - Widget: `com.growthtraining.Growth.GrowthTimerWidget` → `com.growthlabs.growthmethod.GrowthTimerWidget`

### 2. App Group Updates
- **Files**:
  - `Growth/Core/Utilities/AppGroupConstants.swift`
  - `GrowthTimerWidget/AppGroupConstants.swift`
  - `Growth/Growth.entitlements`
  - `GrowthTimerWidget/GrowthTimerWidget.entitlements`
- **Changes**:
  - App group: `group.com.growth.shared` → `group.com.growthlabs.growthmethod`
  - UserDefaults keys: `com.growth.*` → `com.growthlabs.growthmethod.*`

### 3. Entitlements Updates
- **File**: `Growth/Growth.entitlements`
- **Changes**:
  - Associated domains: `growthtraining.com` → `growthlabs.coach`
  - Associated domains: `www.growthtraining.com` → `www.growthlabs.coach`

### 4. Environment Detection
- **File**: `Growth/Core/Utilities/EnvironmentDetector.swift`
- **Changes**:
  - Dev: `com.growth.dev` → `com.growthlabs.growthmethod.dev`
  - Staging: `com.growth.staging` → `com.growthlabs.growthmethod.staging`
  - Production: `com.growth` → `com.growthlabs.growthmethod`

### 5. Subscription Products
- **File**: `Growth/Core/Models/SubscriptionProduct.swift`
- **Changes**: All product IDs updated from `com.growth.subscription.*` to `com.growthlabs.growthmethod.subscription.*`

### 6. Security Service
- **File**: `Growth/Core/Services/SecurityService.swift`
- **Changes**: Keychain key updated from `com.growth.firebase.idToken` to `com.growthlabs.growthmethod.firebase.idToken`

### 7. Timer and Live Activity Services
- **Files**:
  - `Growth/Application/AppSceneDelegate.swift`
  - `GrowthTimerWidget/AppIntents/TimerControlIntent.swift`
  - `Growth/Features/Timer/Services/TimerService.swift`
  - `Growth/Features/Timer/Services/TimerIntentObserver.swift`
  - `Growth/Features/Timer/Services/LiveActivityBackgroundTaskManager.swift`
- **Changes**: 
  - Darwin notification names updated
  - Background task identifiers updated
  - UserDefaults suite names updated

### 8. Info.plist
- **File**: `Growth/Resources/Plist/App/Info.plist`
- **Changes**: Background task identifiers updated to `com.growthlabs.growthmethod.timer.*`

## Next Steps Required

1. **Firebase Configuration**:
   - Regenerate `GoogleService-Info.plist` files for all environments with new bundle IDs
   - Update Firebase project settings with new bundle identifiers

2. **App Store Connect**:
   - Create new App IDs with the new bundle identifiers
   - Generate new provisioning profiles
   - Update push notification certificates

3. **Associated Domains**:
   - Ensure `growthlabs.coach` has proper `apple-app-site-association` file
   - Update any backend configurations for universal links

4. **Testing**:
   - Clean build folder and DerivedData
   - Test all environments (dev, staging, production)
   - Verify widget functionality
   - Test push notifications
   - Verify Live Activities
   - Test in-app purchases with new product IDs

## Rollback Instructions
If needed, use the checkpoint created earlier:
```bash
git reset --hard bundle-id-update-checkpoint
```

## Verification Commands
```bash
# Check for any remaining old bundle IDs
grep -r "com\.growth\." --include="*.swift" --include="*.plist" --include="*.entitlements" --include="*.pbxproj" . | grep -v "growthlabs"

# Clean and rebuild
rm -rf ~/Library/Developer/Xcode/DerivedData/Growth-*
xcodebuild -project Growth.xcodeproj -scheme Growth -configuration Debug clean build
```