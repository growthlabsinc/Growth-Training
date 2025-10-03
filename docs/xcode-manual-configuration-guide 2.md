# Xcode Manual Configuration Guide

## Overview

This guide walks through manually configuring Xcode with the build settings created in Story 25.2. These settings ensure proper separation between debug and release builds, optimized performance, and App Store compliance.

## Prerequisites

- Xcode 15.0 or later
- Apple Developer account with App Store access
- Distribution certificate and provisioning profile created
- Build configuration files created (Debug.xcconfig, Release.xcconfig)

## Configuration Files Location

The build configuration files are located at:
```
BuildConfigurations/
├── Debug.xcconfig
└── Release.xcconfig
```

## Step 1: Link Configuration Files to Project

### 1.1 Open Project Settings
1. Open `Growth.xcodeproj` in Xcode
2. Select the project (not target) in the navigator
3. Click on the "Info" tab

### 1.2 Set Configuration Files
1. Under "Configurations", you should see:
   - Debug
   - Release

2. For each configuration:
   - Click the arrow to expand
   - For "Growth (project)":
     - Debug → Select `BuildConfigurations/Debug.xcconfig`
     - Release → Select `BuildConfigurations/Release.xcconfig`

3. Repeat for the target level if needed

## Step 2: Verify Build Settings

### 2.1 Check Bundle Identifier
1. Select the Growth target
2. Go to "Build Settings" tab
3. Search for "Product Bundle Identifier"
4. Verify:
   - Debug: `com.growthlabs.growthmethod.dev`
   - Release: `com.growthlabs.growthmethod`

### 2.2 Verify Code Signing
1. Search for "Code Signing" in Build Settings
2. Confirm:
   - Debug:
     - Code Signing Style: Automatic
     - Code Signing Identity: Apple Development
   - Release:
     - Code Signing Style: Manual
     - Code Signing Identity: Apple Distribution
     - Provisioning Profile: Growth App Store Distribution

### 2.3 Check Optimization Settings
1. Search for "Optimization" in Build Settings
2. Verify:
   - Debug: `-Onone` (None)
   - Release: `-O` (Optimize for Speed)

## Step 3: Configure Schemes

### 3.1 Edit Current Scheme
1. Click on scheme selector (next to Stop button)
2. Select "Edit Scheme..."

### 3.2 Configure Run Action (Debug)
1. Select "Run" from left sidebar
2. Build Configuration: Debug
3. Debug executable: ✓ Checked

### 3.3 Configure Archive Action (Release)
1. Select "Archive" from left sidebar
2. Build Configuration: Release
3. Reveal Archive in Organizer: ✓ Checked

### 3.4 Create Production Scheme (Optional)
1. Click "Duplicate Scheme"
2. Name it "Growth Production"
3. Set all actions to use Release configuration

## Step 4: Set Up Entitlements

### 4.1 Link Entitlements Files
1. Select the Growth target
2. Go to "Signing & Capabilities" tab
3. Verify entitlements:
   - Debug uses: `Growth/Growth.entitlements`
   - Release uses: `Growth/Growth.Production.entitlements`

### 4.2 Verify Capabilities
Ensure these are enabled:
- Push Notifications (production environment for Release)
- Sign in with Apple
- App Groups (`group.com.growthlabs.growthmethod`)
- Associated Domains

## Step 5: Firebase Configuration

### 5.1 Verify GoogleService-Info Files
Ensure these files exist:
```
Growth/Resources/Plist/
├── dev.GoogleService-Info.plist      (for Debug)
├── staging.GoogleService-Info.plist   (unused currently)
└── GoogleService-Info.plist          (for Release)
```

### 5.2 Check Build Phase Script
1. Select Growth target
2. Go to "Build Phases" tab
3. Find "Copy Firebase Config" script
4. Verify it copies the correct file based on configuration

## Step 6: Widget Extension Configuration

### 6.1 Apply Settings to Widget
1. Select "GrowthTimerWidget" target
2. Repeat steps 2-4 for the widget extension
3. Ensure bundle IDs match:
   - Debug: `com.growthlabs.growthmethod.dev.GrowthTimerWidget`
   - Release: `com.growthlabs.growthmethod.GrowthTimerWidget`

### 6.2 Share App Groups
Verify both targets use the same app group:
- `group.com.growthlabs.growthmethod`

## Step 7: Validate Configuration

### 7.1 Build for Debug
1. Select a simulator
2. Product → Build
3. Check for build success
4. Verify bundle ID in logs

### 7.2 Archive for Release
1. Select "Any iOS Device"
2. Product → Archive
3. Wait for archive to complete
4. Organizer should open automatically

### 7.3 Validate Archive
In Organizer:
1. Select the archive
2. Click "Validate App"
3. Follow prompts to validate with App Store

## Common Issues and Solutions

### Issue: "No provisioning profile found"
**Solution**: 
1. Open Apple Developer portal
2. Create App Store distribution profile
3. Download and install in Xcode
4. Select in Release configuration

### Issue: "Code signing identity not found"
**Solution**:
1. Xcode → Settings → Accounts
2. Download manual signing certificates
3. Ensure distribution certificate is installed

### Issue: "Entitlements don't match"
**Solution**:
1. Verify entitlements file paths in build settings
2. Check that capabilities match provisioning profile
3. Regenerate profiles if needed

### Issue: "Firebase config not found"
**Solution**:
1. Check build phase script execution
2. Verify GoogleService-Info.plist exists
3. Clean build folder and rebuild

## Build Settings Reference

### Key Debug Settings
```
PRODUCT_BUNDLE_IDENTIFIER = com.growthlabs.growthmethod.dev
CODE_SIGN_STYLE = Automatic
SWIFT_OPTIMIZATION_LEVEL = -Onone
DEBUG_INFORMATION_FORMAT = dwarf
ENABLE_TESTABILITY = YES
```

### Key Release Settings
```
PRODUCT_BUNDLE_IDENTIFIER = com.growthlabs.growthmethod
CODE_SIGN_STYLE = Manual
SWIFT_OPTIMIZATION_LEVEL = -O
DEBUG_INFORMATION_FORMAT = dwarf-with-dsym
STRIP_SWIFT_SYMBOLS = YES
```

## Final Checklist

- [ ] Configuration files linked in project settings
- [ ] Bundle identifiers correct for each configuration
- [ ] Code signing configured (automatic for Debug, manual for Release)
- [ ] Entitlements files linked correctly
- [ ] Firebase configuration files in place
- [ ] Widget extension configured similarly
- [ ] Archive validates successfully
- [ ] No build warnings related to signing

## Next Steps

After completing manual configuration:

1. **Test Debug Build**
   - Run on simulator
   - Verify dev environment connection
   - Check debug features work

2. **Test Release Build**
   - Create archive
   - Validate with App Store
   - Test on real device via TestFlight

3. **Prepare for Submission**
   - Install distribution certificate
   - Create App Store provisioning profile
   - Configure App Store Connect

This configuration ensures clean separation between development and production builds while maintaining App Store compliance.