# Fix: Products Not Loading on Physical Device

## Problem
Products are not loading because you're using the wrong Xcode scheme. The console shows:
```
⚠️ StoreKit returned empty products array
```

## Root Cause
- **Growth scheme**: Has `Products.storekit` file configured - ONLY for simulator
- **Growth Production scheme**: No StoreKit file - uses App Store Connect

You're running on a physical device with the Growth scheme, which tries to use the local StoreKit configuration file instead of App Store Connect.

## Solution

### Immediate Fix
1. In Xcode, click the scheme selector (shows "Growth" currently)
2. Select **"Growth Production"** 
3. Build and run (⌘+R)

### For Different Environments

| Environment | Scheme to Use | StoreKit Config | Products Source |
|------------|---------------|-----------------|-----------------|
| Simulator | Growth | Products.storekit | Local file |
| Physical Device (Debug) | Growth Production | None | App Store Connect |
| TestFlight | Growth Production | None | App Store Connect |
| App Store | Growth Production | None | App Store Connect |

### Verification Steps
After switching to Growth Production scheme:
1. Run on your physical device
2. Look for this in console:
   ```
   ✅ Loaded 3 products
   ```
3. Navigate to subscription screen
4. Products should appear with prices

## Why This Happens
- StoreKit configuration files (.storekit) are for **local testing only**
- Physical devices must connect to **App Store Connect** for product data
- The Growth scheme is configured for simulator testing with local data
- The Growth Production scheme connects to real App Store Connect data

## TestFlight Upload Process
```bash
# Always use Production scheme for TestFlight
1. Select "Growth Production" scheme
2. Select "Any iOS Device" as destination
3. Product → Archive
4. Window → Organizer
5. Distribute App → App Store Connect → Upload
```

## Console Indicators

**Wrong (with StoreKit config on device):**
```
📱 StoreKit Environment:
   - Simulator: false  ← Running on device
   - Debug: true
⚠️ StoreKit returned empty products array
```

**Correct (without StoreKit config):**
```
📱 StoreKit Environment:
   - Simulator: false
   - Debug: false  ← Production build
✅ Loaded 3 products
```

## Additional Notes
- Products ARE configured correctly in App Store Connect
- The simplified StoreKit implementation is working properly
- The issue is purely about using the wrong scheme for the environment