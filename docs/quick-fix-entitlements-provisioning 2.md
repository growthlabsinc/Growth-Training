# Quick Fix: Entitlements & Provisioning Profile

## Immediate Steps to Fix Your Configuration

### 1. Fix Entitlements in Build Settings

1. Select **Growth** target
2. Go to **Build Settings** tab
3. Search for: `CODE_SIGN_ENTITLEMENTS`
4. Set the values:
   - Debug: `Growth/Growth.entitlements`
   - Release: `Growth/Growth.Production.entitlements`

### 2. Switch to Manual Signing for Release

1. Stay on **Growth** target
2. Click **Signing & Capabilities** tab
3. At the top, you'll see configuration selector (currently shows "Debug")
4. Change it to **"All"** or **"Release"**
5. For Release configuration:
   - **Uncheck** "Automatically manage signing"
   - Team: Keep as "Growth Labs, Inc"
   - Provisioning Profile: Click dropdown → "Import Profile..." → Select your `.mobileprovision` file
   - OR: Click "Download Manual Profiles" if you've already created it online

### 3. Create Provisioning Profile (if not done)

Quick steps in Apple Developer Portal:
1. Go to https://developer.apple.com/account
2. Click "Certificates, IDs & Profiles"
3. Click "Profiles" → "+" button
4. Choose "App Store" → Continue
5. Select App ID: `com.growthlabs.growthmethod`
6. Select your Distribution certificate
7. Name it: `Growth App Store Distribution`
8. Download and double-click to install

### 4. Verify Configuration

After making changes:
```bash
# Check if entitlements are set
xcodebuild -showBuildSettings -configuration Release | grep CODE_SIGN_ENTITLEMENTS

# Should show:
# CODE_SIGN_ENTITLEMENTS = Growth/Growth.Production.entitlements
```

### 5. Common Issues

**"No eligible profiles for Growth Labs, Inc"**
- Solution: Xcode → Settings → Accounts → Select your account → "Download Manual Profiles"

**Still showing automatic signing for Release**
- Make sure you've selected "Release" or "All" configurations at the top of Signing & Capabilities tab
- The configuration selector is easy to miss - it's at the very top of the pane

**Can't see provisioning profile in dropdown**
- Download the `.mobileprovision` file from Apple Developer portal
- Double-click it to install
- Restart Xcode if needed

Once these steps are complete, your Release build will use manual signing with the proper provisioning profile!