# StoreKit Troubleshooting Guide - Physical Device Testing

## 🎯 Root Cause Identified

**The primary issue**: Using the **"Growth"** scheme on physical devices, which forces the app to use the local `Products.storekit` file instead of connecting to App Store Connect.

## 🚀 Immediate Fix

### Step 1: Switch to Production Scheme
1. Open Xcode
2. Click the scheme selector (top left, next to play/stop buttons)
3. Select **"Growth Production"** instead of "Growth"
4. Build and run on your physical device

### Scheme Differences:
- ❌ **"Growth" scheme**: Uses local `Products.storekit` file (simulator only)
- ✅ **"Growth Production" scheme**: Connects to App Store Connect (physical devices)

## 🔍 Enhanced Debugging Added

I've added comprehensive debugging that will help identify issues:

### Console Output to Look For:
```
🚀 App Launch: Initializing StoreKit...
🏭 ========== Production StoreKit Initialization ==========
🏭 Production Environment: ✅ Yes (or ⚠️ No for TestFlight)
🏭 Checking network connectivity...
🏭 Network connectivity: ✅ Good
🏭 Checking App Store authentication...
🏭 Can make payments: ✅ Yes
🏭 Syncing with App Store...
🏭 App Store sync: ✅ Success
🏭 Loading products for production...
🏭 Attempt 1 of 3...
🏭 ✅ Successfully loaded 3 products!
   - com.growthlabs.growthmethod.subscription.premium.weekly
   - com.growthlabs.growthmethod.subscription.premium.quarterly
   - com.growthlabs.growthmethod.subscription.premium.yearly
📱 StoreKit Status: 3 products loaded
```

### If Products Still Don't Load:
```
🏭 ❌ Failed to load products after all attempts
🏭 Troubleshooting steps for production:
   1. Verify products are in 'Approved' state in App Store Connect
   2. Ensure Bundle ID matches exactly: com.growthlabs.growthmethod
   3. Check that the app is properly signed for distribution
   4. Verify the user is signed into their Apple ID
   5. Check App Store Connect for any pending agreements
```

## 🛠 Debug Tools Available

### Manual Product Refresh
1. Go to **Settings → Development Tools → Subscription Debug**
2. Tap **"Refresh Products from App Store"**
3. Check the product count and status

### Force Production Initialization
1. In the same debug view, tap **"Force Production Initialization"**
2. This will re-run the enhanced diagnostic process

## ✅ Verification Steps

### 1. Check App Store Connect
- Products must be in **"Ready to Submit"** or **"Approved"** state
- Bundle ID must match exactly: `com.growthlabs.growthmethod`
- No pending agreements in "Agreements, Tax, and Banking"

### 2. Device Configuration
- User must be signed into their Apple ID
- In-App Purchases must be enabled (Settings → Screen Time → Content & Privacy Restrictions)
- Network connection must be active

### 3. TestFlight Specific
- For TestFlight builds, you need a **Sandbox Account**
- Go to Settings → App Store → Sandbox Account
- Sign in with a test account from App Store Connect

## 🔧 Common Issues and Solutions

### Issue: "Can make payments: ❌ No"
**Solution**: Check Settings → Screen Time → Content & Privacy Restrictions → iTunes & App Store Purchases

### Issue: "Network connectivity: ❌ Failed"
**Solution**: Check device internet connection, try cellular if on Wi-Fi (or vice versa)

### Issue: "App Store sync: ⚠️ Failed"
**Solution**: Normal for some environments, app should still work

### Issue: Products load in simulator but not on device
**Solution**: You're using the wrong scheme - switch to "Growth Production"

## 📊 Apple's Recommended Implementation vs Current

### What Your App Does Well:
✅ Correct `Product.products(for:)` API usage  
✅ Proper product ID configuration  
✅ Good error handling and diagnostics  

### Differences from Apple Sample:
⚠️ More complex architecture (multiple StoreKit services)  
⚠️ Advanced retry logic (not needed for basic functionality)  
✅ Enhanced debugging (better than Apple's sample)  

## 🎯 Testing Checklist

- [ ] Switch to "Growth Production" scheme
- [ ] Run on physical device
- [ ] Check console for "🏭 Production StoreKit Initialization"
- [ ] Verify "✅ Successfully loaded 3 products"
- [ ] Test subscription paywall shows products with prices
- [ ] Test purchase flow (if needed)

## 🆘 If Still Not Working

1. **Check exact error messages** in console
2. **Verify App Store Connect** product status
3. **Try different physical device** to rule out device-specific issues
4. **Check Bundle ID** matches exactly in Xcode and App Store Connect
5. **Test with TestFlight build** using sandbox account

## 📱 Expected Results

After switching to the correct scheme:
- Console shows successful product loading
- Subscription paywall displays 3 products:
  - Weekly: $4.99
  - Quarterly: $29.99  
  - Yearly: $49.99
- No more "⚠️ StoreKit returned empty products array" warnings

The enhanced debugging will provide clear feedback about exactly what's happening during the product loading process.