# Development APNs Fix Complete

## The Issue
The Firebase function was detecting the environment as "production" because:
- Bundle ID: `com.growthlabs.growthmethod` → maps to production
- But we're using a development APNs key (378FZMBP8L)
- This mismatch caused the function to use production APNs server with a development key

## The Fix Applied
1. ✅ **Entitlements Updated**: Changed `aps-environment` to "development" in both:
   - `Growth/Growth.entitlements`
   - `GrowthTimerWidget/GrowthTimerWidget.entitlements`

2. ✅ **LiveActivityManager Updated**: 
   - File: `Growth/Features/Timer/Services/LiveActivityManager.swift`
   - Line 482: Force environment to "development" when storing push tokens
   - This ensures Firebase functions receive `environment: "development"` and use the correct APNs server

## What You Need to Do in Xcode

1. **Clean Build Folder**
   - Product → Clean Build Folder (⇧⌘K)

2. **Ensure Debug Configuration**
   - Click and hold scheme name → Edit Scheme
   - Under Run → Info → Build Configuration: **Debug**

3. **Build and Run**
   - Select your physical device
   - Build and run (⌘R)
   - The app will now:
     - Use development provisioning profile (automatic)
     - Store push tokens with `environment: "development"`
     - Firebase functions will use development APNs server

## How It Works
- When a Live Activity starts, the push token is stored with `environment: "development"`
- Firebase function reads this and uses `api.development.push.apple.com`
- The development APNs key (378FZMBP8L) will now work correctly

## Testing
1. Start a timer in the app
2. Check Firebase logs: `firebase functions:log --only updateLiveActivity`
3. You should see:
   ```
   🔧 APNs Environment Detection:
   - Environment: development
   - Bundle ID: com.growthlabs.growthmethod
   - Using DEVELOPMENT APNs server first
   ```

## Reverting Later
When you get a production APNs key:
1. Revert entitlements to "production"
2. Remove the force development line in LiveActivityManager.swift
3. Update Firebase secrets with production key