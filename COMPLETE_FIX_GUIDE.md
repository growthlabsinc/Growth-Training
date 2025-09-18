# Complete Fix Guide: Provisioning Profile & StoreKit Issues

## Issues Fixed
1. ❌ "Attempted to install a Beta profile without the proper entitlement"
2. ❌ StoreKit products not loading on physical device
3. ❌ Mixed manual/automatic signing causing conflicts

## Solutions Applied

### 1. ✅ Enabled Automatic Signing
- Ran `enable_automatic_signing_new.rb` script
- All targets now use automatic signing with team 62T6J77P6R
- Xcode will manage provisioning profiles automatically

### 2. ✅ Fixed Scheme Selection
- **For Physical Device**: Must use "Growth Production" scheme
- **For Simulator**: Can use "Growth" scheme with StoreKit config

## Next Steps (In Order)

### Step 1: Clean Build Folder
```
In Xcode: Product → Clean Build Folder (⇧⌘K)
```

### Step 2: Select Correct Scheme
1. Click the scheme selector (next to device selector)
2. Choose **"Growth Production"** (NOT "Growth")
3. This removes the StoreKit config file that blocks App Store Connect

### Step 3: Trust Your Device (if needed)
```
On iPhone: Settings → General → VPN & Device Management
→ Developer App → Trust "Growth Labs, Inc"
```

### Step 4: Build and Run
```
Press ⌘+R to build and run
```

## What Each Scheme Does

| Scheme | StoreKit Config | Use Case | Products Source |
|--------|-----------------|----------|-----------------|
| **Growth** | Products.storekit | Simulator testing | Local file |
| **Growth Production** | None | Physical device/TestFlight | App Store Connect |

## Why The Error Happened

1. **Wrong Scheme**: Using "Growth" scheme on physical device
   - Has StoreKit config file attached
   - Tries to use local products instead of App Store Connect
   
2. **Signing Issues**: Mixed manual/automatic signing
   - Some targets had manual provisioning profiles
   - Now all use automatic signing

3. **Certificate Issues**: Multiple revoked certificates
   - Old certificates were revoked
   - Automatic signing will use the valid one

## Verification Checklist

After building with Growth Production scheme:

✅ Console should show:
```
📱 StoreKit Environment:
   - Simulator: false
   - Debug: false  ← Production build
✅ Loaded 3 products  ← Products from App Store Connect
```

✅ Subscription screen shows:
- 3 products with prices
- Can tap to purchase

❌ If still seeing errors:
1. Make sure you selected "Growth Production" scheme
2. Clean build folder (⇧⌘K)
3. Delete app from device
4. Build and run again

## TestFlight Upload Process

When ready for TestFlight:
```bash
1. Select "Growth Production" scheme
2. Select "Any iOS Device (arm64)"
3. Product → Archive
4. Window → Organizer → Distribute App
5. App Store Connect → Upload
```

## Summary

The fix was simple:
1. **Enable automatic signing** → Let Xcode manage provisioning
2. **Use correct scheme** → "Growth Production" for physical devices
3. **Clean and rebuild** → Fresh start with correct settings

Your products ARE configured correctly in App Store Connect. The app just needs to connect to them using the right scheme!