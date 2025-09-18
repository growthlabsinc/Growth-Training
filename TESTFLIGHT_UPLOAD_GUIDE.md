# TestFlight Upload Guide for Growth App

## Prerequisites

Before starting, ensure you have:
- [ ] Apple Developer account with correct permissions
- [ ] Xcode 15 or later
- [ ] Valid App Store Connect access
- [ ] App Icons in all required sizes
- [ ] Bundle ID: `com.growthlabs.growthmethod`

## Current App Information
- **Bundle ID**: com.growthlabs.growthmethod
- **Current Version**: 1.0
- **Current Build**: 1

## Step-by-Step Instructions

### Step 1: Prepare Your App for Release

1. **Open the project in Xcode**:
   ```bash
   cd /Users/tradeflowj/Desktop/Dev/growth-fresh
   open Growth.xcodeproj
   ```

2. **Update Version/Build Number** (if needed):
   - Select the Growth project in navigator
   - Select the Growth target
   - Go to General tab
   - Update "Version" (e.g., 1.0.1) if releasing a new version
   - Update "Build" (e.g., 2) - must be incremented for each upload

3. **Clean Build Folder**:
   - Menu: Product → Clean Build Folder (⇧⌘K)

### Step 2: Configure Code Signing

1. **Select the Growth target** → Signing & Capabilities tab
2. **Ensure these settings**:
   - Team: Your Team (62T6J77P6R)
   - Bundle Identifier: com.growthlabs.growthmethod
   - Automatically manage signing: ✓ (checked)
   - Signing Certificate: Apple Distribution

3. **Repeat for Widget Extension**:
   - Select GrowthTimerWidgetExtension target
   - Ensure same team is selected
   - Bundle ID should be: com.growthlabs.growthmethod.GrowthTimerWidget

### Step 3: Set Build Configuration to Release

1. **Select Growth scheme** (next to stop button)
2. **Edit Scheme** (click scheme → Edit Scheme...)
3. **Run tab** → Build Configuration: Release
4. **Archive tab** → Build Configuration: Release
5. Click "Close"

### Step 4: Archive the App

1. **Select target device**: 
   - Click device selector (next to scheme)
   - Choose "Any iOS Device (arm64)"

2. **Create Archive**:
   - Menu: Product → Archive
   - Wait for build to complete (may take 5-10 minutes)
   - Organizer window will open automatically

### Step 5: Validate the Archive

1. In the **Organizer window**:
   - Select your new archive
   - Click "Validate App"
   
2. **Distribution options**:
   - Select "App Store Connect"
   - Click "Next"
   
3. **Destination**:
   - Select "Upload"
   - Click "Next"
   
4. **App Store Connect distribution options**:
   - ✓ Include bitcode for iOS content
   - ✓ Upload your app's symbols
   - Click "Next"
   
5. **Signing**:
   - Select "Automatically manage signing"
   - Click "Next"
   
6. Review and click **"Validate"**
   - Fix any validation errors before proceeding

### Step 6: Upload to App Store Connect

1. After successful validation:
   - Click "Distribute App"
   
2. **Distribution method**:
   - Select "App Store Connect"
   - Click "Next"
   
3. **Destination**:
   - Select "Upload"
   - Click "Next"
   
4. Use same options as validation:
   - ✓ Include bitcode
   - ✓ Upload symbols
   - Automatically manage signing
   
5. Click **"Upload"**
   - Upload progress will be shown
   - May take 5-15 minutes

### Step 7: Configure in App Store Connect

1. **Go to App Store Connect**:
   - Visit https://appstoreconnect.apple.com
   - Sign in with your Apple ID

2. **Select your app** (Growth)

3. **Go to TestFlight tab**

4. **Wait for processing**:
   - Build will appear as "Processing" 
   - Usually takes 10-30 minutes
   - You'll get an email when ready

5. **Once processed, configure build**:
   - Click on the build number
   - Fill in required information:
     - What to Test
     - Test Information
   - Answer Export Compliance (usually "No" unless using encryption)

### Step 8: Add Test Information

1. **In the build details**:
   - Add "What to Test" notes
   - Example:
     ```
     New Features:
     - Live Activity timer support
     - Improved performance
     
     Please test:
     - Starting/stopping timers
     - Live Activity updates
     - Push notifications
     ```

2. **Group Testing** (optional):
   - Create test groups
   - Add tester emails
   - Select build for testing

### Step 9: Submit for Beta App Review (if needed)

1. If distributing to external testers:
   - Fill in Beta App Review Information
   - Submit for review
   - Usually approved within 24-48 hours

2. For internal testing:
   - Available immediately after processing
   - Up to 100 internal testers

### Common Issues and Solutions

#### Issue: "No accounts with App Store Connect access"
- Ensure your Apple ID has App Store Connect access
- Check team membership in Apple Developer portal

#### Issue: "Profile doesn't include the aps-environment entitlement"
- Check push notification capability is enabled
- Regenerate provisioning profiles if needed

#### Issue: "Invalid Bundle ID"
- Ensure bundle ID matches App Store Connect
- Current: com.growthlabs.growthmethod

#### Issue: Archive button grayed out
- Ensure "Any iOS Device" is selected
- Not a simulator

#### Issue: Missing required icons
- Check Assets.xcassets has all icon sizes
- Required: 1024x1024 for App Store

### Post-Upload Checklist

- [ ] Build appears in App Store Connect TestFlight tab
- [ ] Build status changes from "Processing" to "Ready to Test"
- [ ] Export compliance answered
- [ ] Test information added
- [ ] Internal testers added (if applicable)
- [ ] TestFlight public link created (if needed)

### Testing the Build

1. **Install TestFlight app** on test devices
2. **Accept invite** (check email)
3. **Install the app** from TestFlight
4. **Test critical features**:
   - Timer functionality
   - Live Activities
   - Push notifications (will work with production APNs)
   - All main app flows

### Important Notes

- Build numbers must be unique and incrementing
- Version numbers should follow semantic versioning (1.0.0)
- TestFlight builds expire after 90 days
- Maximum 10,000 external testers
- Production push tokens will be generated (not development)

<function_calls>
<invoke name="TodoWrite">
<parameter name="todos">[{"id": "1", "content": "Verify app version and build number", "status": "in_progress", "priority": "high"}, {"id": "2", "content": "Check code signing and provisioning profiles", "status": "pending", "priority": "high"}, {"id": "3", "content": "Archive the app in Xcode", "status": "pending", "priority": "high"}, {"id": "4", "content": "Upload to App Store Connect", "status": "pending", "priority": "high"}, {"id": "5", "content": "Configure TestFlight settings", "status": "pending", "priority": "medium"}]