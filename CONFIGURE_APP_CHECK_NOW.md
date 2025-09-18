# Configure App Check in Firebase Console - Required Steps

## Why App Check is Important
App Check protects your Firebase backend from:
- Unauthorized API access
- Billing fraud from abuse
- Data tampering
- Bot attacks

## Steps to Configure App Check Properly

### 1. Open Firebase Console
Go to: https://console.firebase.google.com/project/growth-70a85/appcheck

### 2. Register Your App
1. Click on the **"Apps"** tab
2. You should see your app listed: **com.growthlabs.growthmethod**
3. Click on the app name or "Register" button

### 3. Configure Providers

#### For Production (DeviceCheck):
1. Select **DeviceCheck** as the provider
2. No additional configuration needed - it works automatically
3. Click **Save**

#### For Debug/Development:
1. Also enable the **Debug** provider
2. Run your app in Xcode
3. Look for this in the console:
   ```
   App Check debug token retrieved (add this to Firebase Console if needed): [TOKEN]
   ```
4. Copy the token
5. In Firebase Console → Click "Manage debug tokens"
6. Add the token with a name like "Development iPhone"
7. Click **Save**

### 4. Verify Configuration
After saving:
- The app should show as "Registered" with a green checkmark
- Both DeviceCheck and Debug providers should be enabled

### 5. Keep Enforcement Enabled
- Go to the **"APIs"** tab
- Ensure **Cloud Functions** shows as "Enforced"
- This ensures only authenticated apps can call your functions

## What Happens After Configuration

Once properly configured:
1. The "App not registered" errors will stop
2. Firebase Functions will accept requests from your app
3. Live Activity push updates will work correctly
4. Your backend remains secure with App Check protection

## Important Notes

- **DO NOT** disable App Check enforcement - it's a critical security feature
- Each debug device needs its own debug token added
- Production apps use DeviceCheck automatically (no tokens needed)
- App Check tokens are automatically refreshed by the SDK

## Quick Test
After configuration, run your app and start a timer. You should see:
- ✅ No "App not registered" errors
- ✅ Firebase Functions execute successfully
- ✅ Live Activity updates work properly

The app code is already properly configured - you just need to complete the Firebase Console setup!