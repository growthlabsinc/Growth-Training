# Production Build Guide

## Overview

This guide covers the complete process for creating production builds of the Growth app for App Store submission.

## Prerequisites

Before creating a production build, ensure you have:

1. ✅ Apple Developer account with Admin access
2. ✅ Distribution certificate installed in Keychain
3. ✅ App Store provisioning profile created
4. ✅ App record created in App Store Connect
5. ✅ Production Firebase configuration

## Build Configuration

### Files Created

1. **Production Entitlements**: `Growth/Growth.Production.entitlements`
   - Push notifications: production
   - App groups configured
   - Sign in with Apple enabled

2. **Build Configurations**: `BuildConfigurations/Release.xcconfig`
   - Optimization settings
   - Code stripping enabled
   - Production bundle ID

3. **Export Options**: `ExportOptions.plist`
   - App Store distribution method
   - Manual signing configuration
   - Symbol upload enabled

## Build Process

### 1. Pre-Build Cleanup

Run the debug cleanup script to identify issues:

```bash
./scripts/clean-debug-code.sh
```

This will:
- Find print statements
- Identify TODO/FIXME comments
- Locate development URLs
- Check for hardcoded secrets

### 2. Configure Xcode

1. Open `Growth.xcodeproj` in Xcode
2. Select the Growth scheme
3. Edit scheme → Archive → Build Configuration → Release
4. Ensure "Growth.Production.entitlements" is selected for Release builds

### 3. Update Version Numbers

1. Marketing Version: Update in Xcode or Info.plist
2. Build Number: Automatically set by build script

### 4. Create Production Build

Run the automated build script:

```bash
./scripts/build-release.sh
```

This script will:
- Increment build number
- Clean previous builds
- Optimize assets
- Create archive
- Export IPA for App Store
- Generate build report

### 5. Validate Build

After building, validate the IPA:

```bash
./scripts/validate-release-build.sh ./build/AppStore/Growth.ipa
```

This checks:
- Bundle identifier
- Code signing
- Architecture
- Debug symbols
- Common issues

## Manual Build Process

If you prefer to build manually in Xcode:

1. **Clean Build Folder**: Product → Clean Build Folder (⇧⌘K)
2. **Archive**: Product → Archive
3. **Wait** for archive to complete
4. **Distribute App** in Organizer:
   - Select "App Store Connect"
   - Choose "Upload" or "Export"
   - Use manual signing
   - Select provisioning profiles
5. **Upload** to App Store Connect

## Build Settings Reference

### Release Configuration

```
SWIFT_OPTIMIZATION_LEVEL = -O
GCC_OPTIMIZATION_LEVEL = s
SWIFT_COMPILATION_MODE = wholemodule
STRIP_INSTALLED_PRODUCT = YES
DEBUG_INFORMATION_FORMAT = dwarf-with-dsym
```

### Code Signing

```
CODE_SIGN_STYLE = Manual
CODE_SIGN_IDENTITY = Apple Distribution
DEVELOPMENT_TEAM = 62T6J77P6R
PRODUCT_BUNDLE_IDENTIFIER = com.growthlabs.growthmethod
```

## Firebase Configuration

The app automatically detects the environment:

- **Debug builds**: Uses development Firebase
- **Release builds**: Uses production Firebase

Ensure `GoogleService-Info.plist` exists for production.

## Common Issues

### Build Failures

1. **Code signing error**:
   - Check distribution certificate in Keychain
   - Verify provisioning profile is valid
   - Ensure team ID matches

2. **Archive not appearing**:
   - Check scheme configuration
   - Verify bundle ID matches App Store Connect
   - Clean derived data

3. **IPA too large**:
   - Run asset optimization
   - Check for unused frameworks
   - Enable app thinning

### Debug Code in Release

If debug code appears in release builds:

1. Check `SWIFT_ACTIVE_COMPILATION_CONDITIONS`
2. Ensure using `#if DEBUG` not `#ifdef DEBUG`
3. Verify Logger utility is used instead of print

## Post-Build Steps

1. **Upload to App Store Connect**:
   - Use Xcode Organizer
   - Or use Transporter app
   - Or use `xcrun altool`

2. **Submit for Review**:
   - Add build to version
   - Complete app information
   - Submit for review

3. **Monitor**:
   - Check processing status
   - Watch for email notifications
   - Review crash reports

## Build Automation

For CI/CD integration, use the provided scripts:

```bash
# Full automated build
./scripts/build-release.sh

# Just validation
./scripts/validate-release-build.sh [ipa-path]

# Debug cleanup
./scripts/clean-debug-code.sh
```

## Security Checklist

Before each release:

- [ ] No API keys in code
- [ ] No debug endpoints enabled
- [ ] Print statements removed/wrapped
- [ ] Proper certificate pinning
- [ ] App Transport Security configured
- [ ] Keychain items properly secured

## Version History

Keep track of releases:

| Version | Build | Date | Notes |
|---------|-------|------|-------|
| 1.0.0   | 1     | TBD  | Initial release |

## Support

For build issues:
1. Check Xcode build logs
2. Verify certificates and profiles
3. Review App Store Connect status
4. Consult Apple Developer forums