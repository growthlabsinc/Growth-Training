# Bundle Identifier Update Plan

## Overview
This document outlines the plan to update the bundle identifier from the current identifier patterns to `com.growthlabs.growthmethod` and update the associated domain to `www.growthlabs.coach`.

## Changes Required

### 1. Xcode Project File Updates (`Growth.xcodeproj/project.pbxproj`)

**Current bundle identifiers:**
- Main app: `com.growthtraining.Growth`
- Tests: `com.growthtraining.GrowthTests`
- UI Tests: `com.growthtraining.GrowthUITests`  
- Widget: `com.growthtraining.Growth.GrowthTimerWidget`

**Update to:**
- Main app: `com.growthlabs.growthmethod`
- Tests: `com.growthlabs.growthmethod.Tests`
- UI Tests: `com.growthlabs.growthmethod.UITests`
- Widget: `com.growthlabs.growthmethod.GrowthTimerWidget`

### 2. App Group Identifier Updates

**Current:** `group.com.growth.shared`

**Update to:** `group.com.growthlabs.growthmethod`

**Files to update:**
- `/Growth/Core/Utilities/AppGroupConstants.swift`
- `/GrowthTimerWidget/AppGroupConstants.swift`
- `/Growth/Growth.entitlements`
- `/GrowthTimerWidget/GrowthTimerWidget.entitlements`

### 3. Firebase Configuration

Update Firebase GoogleService-Info.plist files if they contain bundle ID references:
- `Growth/Resources/Plist/GoogleService-Info.plist`
- `Growth/Resources/Plist/dev.GoogleService-Info.plist`
- `Growth/Resources/Plist/staging.GoogleService-Info.plist`

**Note:** You may need to regenerate these files from Firebase Console with the new bundle identifiers.

### 4. Environment Detection (`/Growth/Core/Utilities/EnvironmentDetector.swift`)

Update bundle ID patterns:
- `com.growth.dev` → `com.growthlabs.growthmethod.dev`
- `com.growth.staging` → `com.growthlabs.growthmethod.staging`
- `com.growth` → `com.growthlabs.growthmethod`

### 5. Subscription Products (`/Growth/Core/Models/SubscriptionProduct.swift`)

Update product IDs:
- `com.growth.subscription.basic.monthly` → `com.growthlabs.growthmethod.subscription.basic.monthly`
- `com.growth.subscription.basic.yearly` → `com.growthlabs.growthmethod.subscription.basic.yearly`
- `com.growth.subscription.premium.monthly` → `com.growthlabs.growthmethod.subscription.premium.monthly`
- `com.growth.subscription.premium.yearly` → `com.growthlabs.growthmethod.subscription.premium.yearly`
- `com.growth.subscription.elite.monthly` → `com.growthlabs.growthmethod.subscription.elite.monthly`
- `com.growth.subscription.elite.yearly` → `com.growthlabs.growthmethod.subscription.elite.yearly`

### 6. App Group Constants Keys

Update UserDefaults keys in `AppGroupConstants.swift`:
- `com.growth.timerState` → `com.growthlabs.growthmethod.timerState`
- `com.growth.timerStartTime` → `com.growthlabs.growthmethod.timerStartTime`
- `com.growth.timerEndTime` → `com.growthlabs.growthmethod.timerEndTime`
- `com.growth.timerElapsedTime` → `com.growthlabs.growthmethod.timerElapsedTime`
- `com.growth.timerIsPaused` → `com.growthlabs.growthmethod.timerIsPaused`
- `com.growth.timerMethodName` → `com.growthlabs.growthmethod.timerMethodName`
- `com.growth.timerSessionType` → `com.growthlabs.growthmethod.timerSessionType`
- `com.growth.liveActivityId` → `com.growthlabs.growthmethod.liveActivityId`

### 7. Associated Domains (`/Growth/Growth.entitlements`)

Update associated domains:
- `webcredentials:growthtraining.com` → `webcredentials:growthlabs.coach`
- `webcredentials:www.growthtraining.com` → `webcredentials:www.growthlabs.coach`

### 8. Additional Files to Check

Search and update any hardcoded bundle ID references in:
- `/Growth/Core/Services/SecurityService.swift`
- `/Growth/Features/Timer/Services/TimerService.swift`
- `/Growth/Features/Timer/Services/TimerIntentObserver.swift`
- `/Growth/Features/Timer/Services/LiveActivityBackgroundTaskManager.swift`
- `/Growth/Application/AppSceneDelegate.swift`
- `/GrowthTimerWidget/AppIntents/TimerControlIntent.swift`

## Implementation Steps

1. **Backup the project** before making any changes
2. **Update Xcode project settings** through Xcode UI or by editing project.pbxproj
3. **Update all Swift files** with new bundle identifiers
4. **Update entitlements files** with new app group and domains
5. **Regenerate Firebase configuration files** with new bundle IDs
6. **Update App Store Connect** with new bundle identifiers and app groups
7. **Test thoroughly** on all environments (dev, staging, production)

## Important Considerations

1. **App Store Connect**: You'll need to update your App ID and provisioning profiles with the new bundle identifier
2. **Firebase**: Regenerate GoogleService-Info.plist files for each environment with the new bundle IDs
3. **Push Notifications**: Update push notification certificates for the new bundle identifier
4. **Keychain Access**: Any keychain items tied to the old bundle ID may need migration
5. **User Defaults**: Consider migration strategy for any data stored with old bundle ID keys
6. **Associated Domains**: Ensure `growthlabs.coach` is properly configured with apple-app-site-association file

## Testing Checklist

- [ ] App launches successfully
- [ ] Widget extension works
- [ ] Push notifications work
- [ ] Live Activities function properly
- [ ] App Groups data sharing works between app and widget
- [ ] Firebase services connect properly
- [ ] In-app purchases/subscriptions work
- [ ] Associated domains (universal links) work
- [ ] All environments (dev, staging, production) tested