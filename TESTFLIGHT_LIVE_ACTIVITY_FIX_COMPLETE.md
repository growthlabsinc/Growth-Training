# TestFlight Live Activity Fix Complete

## Issues Fixed

### 1. Widget Extension Sandbox Violations ✅
**Error**: `Sandbox: BackgroundShortcutRunner deny(1) file-issue-extension`

**Fix Applied**:
- Added `NSExtensionPrincipalClass` to widget Info.plist
- Created production entitlements with time-sensitive notifications

### 2. App Intent Registration Failure ✅
**Error**: `Failed to load a definition for com.growthlabs.growthmethod`

**Fix Applied**:
- Added `NSUserActivityTypes` to main app Info.plist
- Registered all timer control intents

### 3. Bundle Configuration ✅
**Fix Applied**:
- Set correct bundle ID: `com.growthlabs.growthmethod.GrowthTimerWidget`
- Created production entitlements file

## Files Modified

1. **GrowthTimerWidget/Info.plist**
   - Added `NSExtensionPrincipalClass` pointing to `GrowthTimerWidgetBundle`

2. **Growth/Resources/Plist/App/Info.plist**
   - Added `NSUserActivityTypes` array with all timer intents

3. **GrowthTimerWidget.Production.entitlements** (NEW)
   - Created production entitlements with app group and time-sensitive notifications

4. **fix_widget_testflight.rb** (NEW)
   - Script to fix Xcode project settings

## Manual Steps Required

### 1. Run the Fix Script
```bash
cd /Users/tradeflowj/Desktop/Dev/growth-backup-22aug2025
ruby fix_widget_testflight.rb
```

### 2. In Apple Developer Portal
1. Create a new App ID for the widget:
   - Bundle ID: `com.growthlabs.growthmethod.GrowthTimerWidget`
   - Enable capabilities: App Groups

2. Create provisioning profile:
   - Name: "Growth Widget App Store"
   - Type: App Store Distribution
   - App ID: Select the widget bundle ID
   - Certificate: Your distribution certificate

3. Download and install the provisioning profile

### 3. In Xcode
1. Open `Growth.xcodeproj`
2. Select the widget extension target
3. Go to "Signing & Capabilities"
4. For Release configuration:
   - Set "Manual" signing
   - Select the new provisioning profile
5. Verify widget is in "Embed App Extensions" build phase
6. Clean build folder: `Shift+Cmd+K`

### 4. Archive and Upload
```bash
# Archive with production scheme
xcodebuild -scheme "Growth Production" -configuration Release archive

# Or use Xcode:
# Product > Archive
# Select "Growth Production" scheme first
```

## Verification

After uploading to TestFlight, check console for:

✅ No more sandbox violations
✅ No more "Failed to load definition" errors
✅ Live Activity appears when timer starts
✅ Buttons work (pause/resume/stop)

## Console Output When Working

```
✅ Widget extension loaded: com.growthlabs.growthmethod.GrowthTimerWidget
✅ TimerControlIntent registered
🎮 TimerControlIntent.perform() called
📡 Darwin notification posted
✅ Timer state updated
```

## Troubleshooting

If still not working:

1. **Check provisioning profile**:
   - Must include widget bundle ID
   - Must have app group capability

2. **Check bundle IDs**:
   - Main app: `com.growthlabs.growthmethod`
   - Widget: `com.growthlabs.growthmethod.GrowthTimerWidget`

3. **Check entitlements**:
   - Both must have same app group
   - Widget needs time-sensitive notifications for iOS 17+

4. **Clean everything**:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```

## Important Notes

- Widget extension MUST be embedded in the main app
- Bundle IDs must follow the pattern: main app ID + extension name
- Production provisioning profiles are required for TestFlight
- Live Activities require iOS 16.1+ on physical devices