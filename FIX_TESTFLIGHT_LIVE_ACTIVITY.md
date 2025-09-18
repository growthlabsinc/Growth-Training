# Fix TestFlight Live Activity Issues

## Problems Identified

From the console errors, there are several critical issues:

1. **Sandbox Violation**: `Sandbox: BackgroundShortcutRunner deny(1) file-issue-extension`
   - The widget extension can't be accessed due to sandbox restrictions

2. **App Intent Registration Failure**: `Failed to load a definition for com.growthlabs.growthmethod`
   - The system can't find the app's intent definitions

3. **Timer Control Intent Error**: `TimerControlIntent finished with error {domain: NSCocoaErrorDomain, code: 3072}`
   - The intent is failing to execute

## Root Causes

1. **Widget Extension Bundle ID Issue**
   - The widget extension might not have the correct bundle identifier for production
   - Should be: `com.growthlabs.growthmethod.GrowthTimerWidget`

2. **Missing NSExtensionPrincipalClass**
   - The widget extension Info.plist is missing the principal class declaration

3. **App Intent Registration**
   - The app intents need to be properly registered in the main app's Info.plist

## Solutions

### 1. Fix Widget Extension Info.plist

Update `GrowthTimerWidget/Info.plist` to include:

```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.widgetkit-extension</string>
    <key>NSExtensionPrincipalClass</key>
    <string>$(PRODUCT_MODULE_NAME).GrowthTimerWidgetBundle</string>
</dict>
```

### 2. Add Required Entitlements for Production

Create/Update `GrowthTimerWidget.Production.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.growthlabs.growthmethod</string>
    </array>
    <!-- Required for Live Activities in production -->
    <key>com.apple.developer.usernotifications.time-sensitive</key>
    <true/>
</dict>
</plist>
```

### 3. Register App Intents in Main App Info.plist

Add to `Growth/Resources/Plist/App/Info.plist`:

```xml
<key>NSUserActivityTypes</key>
<array>
    <string>TimerControlIntent</string>
    <string>PauseTimerIntent</string>
    <string>ResumeTimerIntent</string>
    <string>StopTimerIntent</string>
</array>
```

### 4. Fix Build Settings

Ensure these settings in Xcode:

1. **Widget Extension Target**:
   - Product Bundle Identifier: `com.growthlabs.growthmethod.GrowthTimerWidget`
   - Deployment Target: iOS 16.1 (minimum for Live Activities)
   - Code Signing: Same team and provisioning as main app

2. **Build Phases**:
   - Ensure widget extension is included in "Embed App Extensions"
   - Check "Copy only when installing" is unchecked

### 5. Fix App Intent Declaration

Create a new file `Growth/Application/AppIntents.swift`:

```swift
import AppIntents

@available(iOS 16.0, *)
struct GrowthAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        // Register intents that should be available
        []
    }
}
```

## Verification Steps

1. Clean build folder: `Shift+Cmd+K`
2. Delete derived data
3. Archive with Growth Production scheme
4. Upload to TestFlight
5. Test on device with console open

## Expected Console Output (When Fixed)

```
✅ TimerControlIntent registered successfully
✅ Widget extension loaded: com.growthlabs.growthmethod.GrowthTimerWidget
✅ Live Activity created with ID: <activity_id>
```

## Critical Files to Check

- [ ] `GrowthTimerWidget/Info.plist` - Must have NSExtensionPrincipalClass
- [ ] `GrowthTimerWidgetExtension.entitlements` - Must match production requirements
- [ ] `Growth.Production.entitlements` - Must include widget extension capabilities
- [ ] Widget extension is properly embedded in main app target
- [ ] Bundle IDs are consistent (main app + ".GrowthTimerWidget")

## TestFlight Specific Requirements

1. **App Store Connect Configuration**:
   - Ensure app has "Live Activities" capability enabled
   - Widget extension must be included in the app bundle

2. **Provisioning Profiles**:
   - Both app and widget extension need valid production provisioning profiles
   - Profiles must include the app group capability

3. **Build Configuration**:
   - Widget extension must use Release configuration for TestFlight
   - Optimization level should match main app