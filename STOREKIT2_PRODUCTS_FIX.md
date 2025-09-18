# StoreKit2 Products Loading Fix

## Problem
Products aren't loading when running the app on a physical device because:
1. StoreKit configuration files only work in the Simulator by default
2. On physical devices, the app fetches from App Store Connect
3. The products don't exist in App Store Connect yet

## Immediate Solution - Test in Simulator

Run this command to test in the simulator:
```bash
# Open Xcode and run on Simulator
open Growth.xcodeproj
# Then select an iPhone simulator and press Run
```

## Alternative Solution - Enable Local Testing on Device

If you need to test on a physical device before products are in App Store Connect:

### Step 1: Update the scheme to use local testing
The schemes have been updated to reference the Products.storekit file at:
- Debug scheme: `Growth.xcscheme`
- Release scheme: `Growth Production.xcscheme`

### Step 2: Run with StoreKit Testing
1. In Xcode, select your device
2. Go to Product → Scheme → Edit Scheme
3. Under Run → Options:
   - Ensure "StoreKit Configuration" shows "Products.storekit"
   - This enables local testing even on physical devices
4. Clean build folder (Shift+Cmd+K)
5. Run the app

### Step 3: If still not working, use Simulator
The most reliable way to test with local StoreKit configuration:
1. Select any iPhone simulator in Xcode
2. Run the app
3. Products will load from the Products.storekit file

## For Production/TestFlight

When ready for production:
1. Create products in App Store Connect with these exact IDs:
   - `com.growthlabs.growthmethod.subscription.premium.weekly`
   - `com.growthlabs.growthmethod.subscription.premium.quarterly`
   - `com.growthlabs.growthmethod.subscription.premium.yearly`
2. Submit for review or keep in "Ready to Submit" state
3. Products will automatically load from App Store Connect

## Verification
To verify the fix is working:
1. Run in Simulator
2. Open Settings → Subscription
3. You should see the three subscription options with prices

## Current Status
✅ Products.storekit file configured correctly
✅ Schemes updated to reference the configuration file
✅ Product IDs match between code and configuration
⚠️ Physical device testing requires App Store Connect products
✅ Simulator testing will work immediately