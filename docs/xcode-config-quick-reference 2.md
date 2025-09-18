# Xcode Configuration Quick Reference

## 🚀 Quick Setup Steps

### 1. Link Configuration Files
**Project Info Tab → Configurations**
- Debug → `BuildConfigurations/Debug.xcconfig`
- Release → `BuildConfigurations/Release.xcconfig`

### 2. Key Build Settings to Verify

| Setting | Debug | Release |
|---------|-------|---------|
| Bundle ID | `com.growthlabs.growthmethod.dev` | `com.growthlabs.growthmethod` |
| Code Sign Style | Automatic | Manual |
| Code Sign Identity | Apple Development | Apple Distribution |
| Swift Optimization | `-Onone` | `-O` |
| Strip Symbols | NO | YES |

### 3. Scheme Configuration
**Edit Scheme → Archive → Build Configuration**: Release

### 4. Entitlements
- Debug: `Growth/Growth.entitlements`
- Release: `Growth/Growth.Production.entitlements`

## 🔍 Quick Checks

```bash
# Verify xcconfig files are linked
grep -r "xcconfig" Growth.xcodeproj/project.pbxproj

# Check current configuration
xcodebuild -showBuildSettings -configuration Debug | grep PRODUCT_BUNDLE_IDENTIFIER
xcodebuild -showBuildSettings -configuration Release | grep PRODUCT_BUNDLE_IDENTIFIER
```

## ⚠️ Common Gotchas

1. **Widget Bundle ID** - Must append `.GrowthTimerWidget`
2. **Provisioning Profile** - Name must match exactly: "Growth App Store Distribution"
3. **Firebase Config** - Different files for Debug/Release
4. **App Groups** - Both targets must use `group.com.growthlabs.growthmethod`

## 📱 Test Commands

```bash
# Debug build
xcodebuild -project Growth.xcodeproj -scheme Growth -configuration Debug build

# Release archive
xcodebuild -project Growth.xcodeproj -scheme Growth -configuration Release archive
```

## 🎯 Final Validation

1. Archive the app: `Product → Archive`
2. In Organizer: `Validate App`
3. Check for green checkmarks ✅

If validation passes, you're ready for App Store submission!