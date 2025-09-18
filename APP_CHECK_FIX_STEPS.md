# App Check Debug Token Fix Steps

## The Problem
Your app is configured correctly for App Check debug mode, but Firebase is rejecting the debug token because it hasn't been registered in the Firebase Console yet.

## Quick Solution

### Step 1: Get Your Debug Token

**Option A: Use the App Check Debug View (Easiest)**
1. In the app, go to Settings > Developer Options > App Check Debug Token
2. Tap "Get Debug Token"
3. The token will be displayed (it should work even with the error message)

**Option B: Run the Script**
```bash
cd /Users/tradeflowj/Desktop/Dev/growth-fresh
./scripts/get-app-check-token.sh
```

**Option C: Check Xcode Console on Next Launch**
1. Clean Build (Shift+Cmd+K)
2. Delete app from simulator
3. Run the app
4. Look for this in the first few lines:
```
🔑 App Check Debug Token (from storage):
YOUR-TOKEN-HERE
```

### Step 2: Add Token to Firebase Console

1. Go to: https://console.firebase.google.com/project/growth-70a85/appcheck/apps
2. Find your iOS app (com.growthlabs.growthmethod)
3. Click the three dots menu (⋮) → "Manage debug tokens"
4. Click "Add debug token"
5. Paste your token
6. Give it a descriptive name like "iOS Simulator - Dev"
7. Click "Save"

### Step 3: Wait & Test

1. Wait 1-2 minutes for the token to propagate
2. Restart the app
3. Try the Live Activity pause/resume buttons
4. Check Xcode console - you should no longer see 403 errors

## Why This Happens

- App Check debug tokens are unique per device/simulator
- They're generated on first app launch and stored in UserDefaults
- Firebase needs to know about these tokens before accepting them
- Once registered, the token persists until you reset the simulator

## If Still Having Issues

1. **Token Not Found?**
   - Make sure you're running in Debug configuration
   - Check that you're on a simulator (not a real device in release mode)

2. **Still Getting 403 Errors?**
   - Double-check the token was added correctly in Firebase Console
   - Try deleting and re-adding the token
   - Verify you're in the correct Firebase project

3. **Temporary Workaround**
   - In Firebase Console > App Check > APIs > Cloud Functions
   - Temporarily set to "Unenforced" (remember to re-enable later!)

## Deploy Updated Function

Don't forget to deploy the updated function without consumeAppCheckToken:false:
```bash
cd functions
firebase deploy --only functions:updateLiveActivitySimplified
```