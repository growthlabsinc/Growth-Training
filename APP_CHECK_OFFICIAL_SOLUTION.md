# App Check Debug Token - Official Solution

Based on Firebase's official documentation, here's the correct way to get your debug token:

## Step 1: Enable Debug Logging

You need to add the `-FIRDebugEnabled` launch argument:

1. In Xcode, go to **Product → Scheme → Edit Scheme**
2. Select **Run** from the left menu
3. Select the **Arguments** tab
4. In **Arguments Passed On Launch**, click the **+** button
5. Add: `-FIRDebugEnabled`
6. Click **Close**

## Step 2: Get the Debug Token

1. **Clean Build**: Product → Clean Build Folder (Shift+Cmd+K)
2. **Delete the app** from simulator
3. **Run the app** again
4. Look in the Xcode console for a line like:
   ```
   [Firebase/AppCheck][I-FAA001001] Firebase App Check Debug Token: 123a4567-b89c-12d3-e456-789012345678
   ```

## Step 3: Register the Token

1. Go to Firebase Console: https://console.firebase.google.com/project/growth-70a85/appcheck/apps
2. Click on your iOS app
3. Click the overflow menu (⋮) → **Manage debug tokens**
4. Click **Add debug token**
5. Paste the token from the console
6. Give it a name (e.g., "iOS Simulator Development")
7. Click **Save**

## Why Your Current Setup Isn't Working

Looking at your logs, you have:
```
🔐 Firebase App Check configured with DEBUG provider (Debug build)
```

But you're missing the debug token in the logs because you don't have `-FIRDebugEnabled` in your launch arguments. This flag is required to see the debug token.

## Quick Fix

If you can't find the token after adding `-FIRDebugEnabled`, you can:

1. **Generate your own token**:
   ```bash
   uuidgen
   ```

2. **Set it manually** before FirebaseApp.configure():
   ```swift
   #if DEBUG
   let debugToken = "YOUR-UUID-HERE"
   UserDefaults.standard.set(debugToken, forKey: "FIRAAppCheckDebugToken")
   #endif
   ```

3. **Add the same token** to Firebase Console

## Important Notes

- The debug token is stored in UserDefaults under the key `FIRAAppCheckDebugToken`
- Each simulator/device gets its own unique token
- Tokens persist until you reset the simulator or delete the app
- Never use debug provider or tokens in production builds