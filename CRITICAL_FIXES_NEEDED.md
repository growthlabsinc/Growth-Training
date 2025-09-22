# Critical Fixes Needed for Growth Training App

## Priority 1: App Crash Issues (CRITICAL)

### ✅ 1. Google Sign-In URL Scheme
**Status:** FIXED
- Updated Info.plist with correct URL scheme for growth-training-app project
- Changed from: `com.googleusercontent.apps.645068839446-ornmecs6mg94okaqlp11oj6ouu1af74r`
- Changed to: `com.googleusercontent.apps.997901246801-t5it06c0qjaqusqsifu31lskb4aj56gu`

## Priority 2: Firebase Configuration Issues

### 2. Bundle Identifier Mismatch
**Error:** `Unknown bundle identifier 'com.growthlabs.growthtraining'`
**Fix Needed:**
- The app is using bundle ID `com.growthlabs.growthtraining`
- Firebase is configured for `com.growthlabs.growthmethod`
- Need to ensure consistent bundle ID across project

### 3. Firebase Initialization
**Error:** `The default Firebase app has not yet been configured`
**Fix Needed:**
- Firebase is being called before `FirebaseApp.configure()`
- Check initialization order in AppDelegate/GrowthAppApp.swift

### 4. App Check Debug Token
**Error:** `App attestation failed. PERMISSION_DENIED`
**Debug Token:** `43E06779-F6BE-4933-A06A-B52A25DE19F1`
**Fix Needed:**
1. Go to: https://console.firebase.google.com/project/growth-training-app/appcheck/apps
2. Click on iOS app
3. Click "Manage debug tokens"
4. Add token: `43E06779-F6BE-4933-A06A-B52A25DE19F1`

## Priority 3: UI Issues

### 5. NaN Values in CoreGraphics
**Error:** Multiple "invalid numeric value (NaN)" errors
**Likely Causes:**
- Division by zero in layout calculations
- Uninitialized values in animations
- Progress indicators with invalid percentages

### 6. Constraint Issues
**Error:** Autolayout constraint conflicts in keyboard/assistant view
**Fix:** Review keyboard handling and input accessory views

## Priority 4: StoreKit Issues

### 7. No Products Loaded
**Error:** `✅ Loaded 0 products`
**Fix Needed:**
- Configure products in App Store Connect
- Ensure bundle ID matches in StoreKit configuration
- Check sandbox environment settings

### 8. No Active Account
**Error:** `Error Domain=ASDErrorDomain Code=509 "No active account"`
**Fix:** Sign in to sandbox account in simulator settings

## Priority 5: Network/Connection Issues

### 9. Connection Endpoint Warnings
**Warning:** Multiple `Connection has no local endpoint` messages
**Note:** These are typically simulator-related and can be ignored

### 10. CoreTelephony XPC Errors
**Error:** Connection to `com.apple.commcenter.coretelephony.xpc` failed
**Note:** Normal in simulator (no telephony support)

## Immediate Actions Required

### Step 1: Register App Check Token
```bash
# Token to register in Firebase Console
43E06779-F6BE-4933-A06A-B52A25DE19F1
```

### Step 2: Fix Bundle Identifier
Update project settings to use consistent bundle ID:
- Either change app to use `com.growthlabs.growthmethod`
- Or update Firebase to use `com.growthlabs.growthtraining`

### Step 3: Fix Firebase Initialization
Ensure `FirebaseApp.configure()` is called before any Firebase service usage

### Step 4: Add -FIRDebugEnabled Flag
1. In Xcode: Product → Scheme → Edit Scheme
2. Select Run → Arguments
3. Add `-FIRDebugEnabled` to Arguments Passed On Launch

## Testing After Fixes

1. Clean build folder (⌘+Shift+K)
2. Delete app from simulator
3. Run fresh build
4. Verify:
   - App doesn't crash on launch
   - Firebase connects successfully
   - Google Sign-In works
   - No NaN errors in console

## Firebase Project Info
- **Project ID:** growth-training-app
- **Bundle ID Expected:** com.growthlabs.growthmethod (or needs update)
- **Google Sign-In Client ID:** 997901246801-t5it06c0qjaqusqsifu31lskb4aj56gu