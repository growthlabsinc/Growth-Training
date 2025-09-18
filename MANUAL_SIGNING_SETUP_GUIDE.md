# Manual Signing Setup Guide for Growth App

Since automatic signing is not working, follow these steps to set up manual signing for App Store distribution.

## Prerequisites

1. **Apple Distribution Certificate**
   - Name: "Apple Distribution: Jon Webb (62T6J77P6R)" or similar
   - Type: Apple Distribution
   - Must be installed in your keychain

2. **Provisioning Profiles**
   - Main App: "Growth App Store Distribution"
   - Widget: "Growth Timer Widget App Store"
   - Type: App Store Distribution
   - Team: Growth Labs, Inc (62T6J77P6R)

## Step 1: Check/Create Provisioning Profiles

1. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/profiles/list)
2. Look for these profiles:
   - **Growth App Store Distribution**
   - **Growth Timer Widget App Store**

3. If missing, create them:
   
   ### For Main App:
   - Click "+" to create new profile
   - Select "App Store" distribution
   - Select App ID: "Growth" or "com.growthlabs.growthmethod"
   - Select Certificate: Your Apple Distribution certificate
   - Name it: "Growth App Store Distribution"
   - Download the profile

   ### For Widget:
   - Click "+" to create new profile
   - Select "App Store" distribution
   - Select App ID: "GrowthTimerWidgetExtension" or "com.growthlabs.growthmethod.GrowthTimerWidget"
   - Select Certificate: Your Apple Distribution certificate
   - Name it: "Growth Timer Widget App Store"
   - Download the profile

4. **Install Profiles**: Double-click each downloaded profile to install

## Step 2: Run Manual Signing Configuration

Run the setup script:
```bash
ruby setup_manual_signing_complete.rb
```

## Step 3: Verify in Xcode

1. Open `Growth.xcodeproj` in Xcode
2. Select the Growth target
3. Go to "Signing & Capabilities" tab
4. Verify:
   - [ ] "Automatically manage signing" is UNCHECKED
   - [ ] Team shows "Growth Labs, Inc"
   - [ ] Signing Certificate shows "Apple Distribution"
   - [ ] Provisioning Profile shows "Growth App Store Distribution"

5. Select the GrowthTimerWidgetExtension target
6. Verify:
   - [ ] "Automatically manage signing" is UNCHECKED
   - [ ] Team shows "Growth Labs, Inc"
   - [ ] Signing Certificate shows "Apple Distribution"
   - [ ] Provisioning Profile shows "Growth Timer Widget App Store"

## Step 4: Clean Build Folder

1. In Xcode: Product → Clean Build Folder (Shift+Cmd+K)
2. Or run: `rm -rf ~/Library/Developer/Xcode/DerivedData/Growth-*`

## Step 5: Archive for Distribution

1. Select "Any iOS Device (arm64)" as destination
2. Product → Archive
3. Wait for archive to complete
4. In Organizer, click "Distribute App"
5. You should now see "App Store Connect" option

## Troubleshooting

### If profiles don't appear in Xcode:
```bash
# Refresh provisioning profiles
rm -rf ~/Library/MobileDevice/Provisioning\ Profiles/
# Then re-download from Developer Portal
```

### If still showing "Custom" only:
1. Check that your Apple ID in Xcode has the "Account Holder" or "Admin" role
2. Verify bundle IDs match exactly:
   - Main app: `com.growthlabs.growthmethod`
   - Widget: `com.growthlabs.growthmethod.GrowthTimerWidget`

### Certificate Issues:
```bash
# List certificates
security find-identity -v -p codesigning

# Look for:
# "Apple Distribution: Jon Webb (62T6J77P6R)"
```

## Manual Override (if script doesn't work)

1. Open Xcode
2. Select project in navigator
3. Select "Growth" target
4. Go to "Build Settings" tab
5. Search for "signing"
6. Set these values:
   - Code Signing Identity: "Apple Distribution"
   - Code Signing Style: "Manual"
   - Development Team: "62T6J77P6R"
   - Provisioning Profile: "Growth App Store Distribution"

7. Repeat for "GrowthTimerWidgetExtension" target with:
   - Provisioning Profile: "Growth Timer Widget App Store"