# Provisioning Profile & Entitlements Setup Guide

## Overview

This guide helps you create and install the App Store Distribution provisioning profile and configure entitlements correctly in Xcode.

## Part 1: Create App Store Distribution Profile

### Prerequisites
- Apple Developer account with App Store access
- App ID created in Apple Developer portal
- Distribution certificate installed in Keychain

### Step 1: Access Apple Developer Portal
1. Go to [developer.apple.com](https://developer.apple.com)
2. Sign in with your Apple ID
3. Navigate to "Certificates, Identifiers & Profiles"

### Step 2: Create App ID (if not exists)
1. Click "Identifiers" → "+"
2. Select "App IDs" → Continue
3. Select "App" → Continue
4. Configure:
   - Description: `Growth Method`
   - Bundle ID: `com.growthlabs.growthmethod`
   - Capabilities:
     - [x] Push Notifications
     - [x] Sign In with Apple
     - [x] App Groups (configure as `group.com.growthlabs.growthmethod`)
     - [x] Associated Domains

### Step 3: Create Distribution Certificate (if needed)
1. Click "Certificates" → "+"
2. Select "Apple Distribution" → Continue
3. Follow the CSR creation instructions
4. Download and install the certificate

### Step 4: Create App Store Provisioning Profile
1. Click "Profiles" → "+"
2. Select "App Store" under Distribution → Continue
3. Select your App ID: `com.growthlabs.growthmethod` → Continue
4. Select your Distribution Certificate → Continue
5. Name it: `Growth App Store Distribution`
6. Generate and download

### Step 5: Install Provisioning Profile
1. Double-click the downloaded `.mobileprovision` file
2. Xcode will automatically install it

## Part 2: Configure Entitlements in Xcode

### Step 1: Verify Entitlements Files Exist
Check that these files are in your project:
- `Growth/Growth.entitlements` (for Debug)
- `Growth/Growth.Production.entitlements` (for Release)

### Step 2: Link Entitlements in Build Settings
1. Select the Growth target
2. Go to "Build Settings" tab
3. Search for "Code Signing Entitlements"
4. Set values:
   - Debug: `Growth/Growth.entitlements`
   - Release: `Growth/Growth.Production.entitlements`

### Step 3: Configure Signing & Capabilities
1. Select the Growth target
2. Go to "Signing & Capabilities" tab
3. For Debug configuration:
   - [x] Automatically manage signing
   - Team: Growth Labs, Inc
   - Bundle ID: `com.growthlabs.growthmethod.dev`

4. For Release configuration:
   - [ ] Automatically manage signing (uncheck)
   - Team: Growth Labs, Inc
   - Bundle ID: `com.growthlabs.growthmethod`
   - Provisioning Profile: `Growth App Store Distribution`
   - Signing Certificate: `Apple Distribution`

### Step 4: Add Required Capabilities
In "Signing & Capabilities" tab, add these capabilities:
1. Click "+" → Add Capability
2. Add:
   - Push Notifications
   - Sign In with Apple
   - App Groups (configure as `group.com.growthlabs.growthmethod`)
   - Associated Domains (add `applinks:growth-app.com`)

## Part 3: Widget Extension Configuration

### Step 1: Create Widget App ID
1. In Apple Developer portal → Identifiers → "+"
2. Bundle ID: `com.growthlabs.growthmethod.GrowthTimerWidget`
3. Enable App Groups capability

### Step 2: Create Widget Provisioning Profile
1. Profiles → "+"
2. Select "App Store" under Distribution
3. Select widget App ID
4. Name it: `Growth Widget App Store Distribution`

### Step 3: Configure Widget in Xcode
Repeat Part 2 steps for the GrowthTimerWidget target

## Troubleshooting

### "No profiles for 'Growth Labs, Inc' were found"
1. Ensure you're signed in to the correct Apple Developer account
2. Xcode → Settings → Accounts → Download Manual Profiles
3. Check that your account has the App Manager or Admin role

### "Provisioning profile doesn't match bundle identifier"
1. Verify bundle ID in target settings matches the App ID
2. Regenerate provisioning profile if needed
3. Clean build folder: Product → Clean Build Folder

### "Missing entitlements"
1. Ensure entitlements files are added to the project
2. Check "Code Signing Entitlements" build setting
3. Verify file paths are correct

## Quick Command Reference

```bash
# List installed provisioning profiles
ls ~/Library/MobileDevice/Provisioning\ Profiles/

# View profile details
security cms -D -i ~/Library/MobileDevice/Provisioning\ Profiles/[profile-uuid].mobileprovision

# Clear provisioning profile cache
rm -rf ~/Library/MobileDevice/Provisioning\ Profiles/*
```

## Next Steps

After completing setup:
1. Build the app: Product → Build
2. Archive for App Store: Product → Archive
3. Validate in Organizer
4. Upload to App Store Connect

The app is now properly configured for App Store distribution!