# App Check 403 Error Investigation

## Current Status
We're experiencing persistent App Check 403 errors despite having registered debug tokens.

## Key Facts
1. **APNs Keys**: Both dev (55LZB28UY2) and prod (66LQV834DU) keys give the same App Check 403 error
2. **Debug Token**: F171E766-F296-44CB-913B-C89640E10AA0 is stored in UserDefaults
3. **Firebase Console**: User confirmed the token is registered
4. **App Configuration**: Shows "🔐 Firebase App Check configured with DEBUG provider (Debug build)"

## Recent Changes
- Restored dev APNs key (55LZB28UY2) and updated secrets
- Redeployed updateLiveActivitySimplified with dev key
- Both environments (dev and prod) use the same Firebase project: growth-70a85

## Debug Token Verification
```bash
# Token is stored correctly:
defaults read com.growthlabs.growthmethod FIRAAppCheckDebugToken
# Output: F171E766-F296-44CB-913B-C89640E10AA0
```

## Xcode Logs Show
```
🔐 Firebase App Check configured with DEBUG provider (Debug build)
Error getting App Check token; using placeholder token instead. Error: Error Domain=com.firebase.appCheck Code=0 "App attestation failed"
```

## Potential Issues to Check

### 1. Missing -FIRDebugEnabled Flag
The app might not be sending the debug token because the flag isn't set:
- Go to Xcode → Product → Scheme → Edit Scheme
- Select Run → Arguments
- Add `-FIRDebugEnabled` to Arguments Passed On Launch

### 2. Bundle ID Mismatch
Verify the bundle ID in Xcode matches Firebase:
- Xcode bundle ID: com.growthlabs.growthmethod
- Firebase expects: com.growthlabs.growthmethod ✓

### 3. Token Registration Timing
The token might not have propagated yet. Try:
- Wait a few minutes for propagation
- Restart the app completely
- Clean build folder (Cmd+Shift+K) and rebuild

### 4. Wrong Firebase App
Check if the app is connecting to the correct Firebase project:
- Both dev and prod use: growth-70a85
- Verify in Firebase Console that you're looking at the right project

## Next Steps
1. **Add -FIRDebugEnabled flag** (Priority: HIGH)
2. **Clean build and restart** after flag is added
3. **Generate new token** if still failing:
   ```bash
   # Delete existing token
   defaults delete com.growthlabs.growthmethod FIRAAppCheckDebugToken
   # Run app to generate new token
   # Register new token in Firebase Console
   ```

## Testing After Fix
1. Start the app with -FIRDebugEnabled flag
2. Check console for the debug token output
3. Verify no more 403 errors in logs
4. Test Firebase Functions calls work properly