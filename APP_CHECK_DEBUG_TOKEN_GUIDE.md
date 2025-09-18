# App Check Debug Token Configuration Guide

## Finding Your Debug Token

### Method 1: Check App Launch Logs
1. **Clean Build**: Product > Clean Build Folder (Shift+Cmd+K)
2. **Delete App**: Delete the app from simulator
3. **Run App**: Build and run the app
4. **Look for Token** in the first 10 seconds of logs:
   ```
   🔑 App Check Debug Token:
   YOUR-DEBUG-TOKEN-HERE
   ```

### Method 2: Add Launch Button
If you can't find the token in logs, add this temporary button to test:

```swift
// In any SwiftUI view (e.g., SettingsView)
Button("Get App Check Token") {
    AppCheckDebugHelper.shared.refreshDebugToken()
}
```

### Method 3: Check Xcode Console Filters
1. Make sure console is not filtered
2. Clear console before running
3. Look for these patterns:
   - `Firebase App Check Debug Token:`
   - `App Check Debug Token:`
   - `🔑 App Check Debug Token:`

## Configuring App Check in Firebase Console

### Option A: Add Debug Token (Recommended)
1. Go to: https://console.firebase.google.com/project/growth-70a85/appcheck/apps
2. Find your iOS app (com.growthlabs.growthmethod)
3. Click the three dots menu → "Manage debug tokens"
4. Click "Add debug token"
5. Paste your token and give it a name like "Dev Simulator"
6. Save

### Option B: Temporarily Disable App Check (Quick Fix)
1. Go to: https://console.firebase.google.com/project/growth-70a85/appcheck/apis
2. Find "Cloud Functions"
3. Click on it
4. Change enforcement from "Enforced" to "Unenforced"
5. Save

**⚠️ Important**: Only use Option B temporarily for testing. Re-enable enforcement after adding your debug token.

## Fixing the Firebase Function

The function currently has `consumeAppCheckToken: false`. This needs to be changed:

### Current (Not Working):
```javascript
exports.updateLiveActivitySimplified = onCall(
    { 
        region: 'us-central1',
        consumeAppCheckToken: false  // ❌ This bypasses App Check
    },
```

### Fixed Version:
```javascript
exports.updateLiveActivitySimplified = onCall(
    { 
        region: 'us-central1',
        consumeAppCheckToken: true   // ✅ This enforces App Check
    },
```

Or simply remove the line (defaults to true):
```javascript
exports.updateLiveActivitySimplified = onCall(
    { 
        region: 'us-central1'
    },
```

## Verifying It Works

After configuration:
1. Start a timer
2. Try pause/resume from Live Activity
3. Check Xcode console for:
   - ✅ "Push update sent" (no 403 errors)
   - ✅ "Update Live Activity: [activityId] - Action: update"

## Debug Token Persistence

- Debug tokens are stored in UserDefaults
- They persist across app launches
- They're unique per device/simulator
- If you reset simulator, you'll get a new token

## Troubleshooting

If still seeing 403 errors:
1. Verify token is added to Firebase Console
2. Wait 1-2 minutes for changes to propagate
3. Try force-refreshing the token
4. Check you're using the correct Firebase project
5. Ensure bundle ID matches exactly