# Remove Firebase Debug Logging from Xcode Console

## The Problem
You've added `FIRDebugEnabled` (or similar) to your Xcode scheme, and now Firebase verbose logging won't stop even after removing it. This is because Xcode caches scheme settings.

## Complete Solution

### Step 1: Remove ALL Firebase Debug Environment Variables

1. In Xcode, go to **Product → Scheme → Edit Scheme**
2. Select the **Run** action on the left
3. Go to the **Arguments** tab
4. Under **Environment Variables**, remove or disable ALL of these:
   - `FIRDebugEnabled`
   - `FIRAnalyticsDebugEnabled`
   - `FirebaseDebugLogging`
   - `FIRFirestoreLoggingEnabled`
   - Any other Firebase-related variables

5. Also check the **Launch Arguments** section and remove any Firebase-related arguments

### Step 2: Add Variables to DISABLE Logging

In the same Environment Variables section, ADD these to force disable logging:
- `FIRDebugDisabled` = `1`
- `FirebaseDebugLogging` = `0`
- `FIRFirestoreLoggingEnabled` = `0`

### Step 3: Clean Everything

1. **Close Xcode completely**
2. Run these commands in Terminal:

```bash
# Kill any Xcode processes
killall Xcode 2>/dev/null || true

# Clean all derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/Growth-*

# Clean module cache
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex

# Clean Xcode caches
rm -rf ~/Library/Caches/com.apple.dt.Xcode
```

### Step 4: Reset Simulator (if using)

If you're testing on simulator:
1. Open Simulator
2. Device → Erase All Content and Settings

### Step 5: Rebuild

1. Open Xcode
2. Hold Option key and go to Product menu
3. Select "Clean Build Folder..." (this is deeper than regular clean)
4. Build and run

## Alternative: Nuclear Option

If the above doesn't work, do this:

1. Delete the file: `~/Library/Developer/Xcode/DerivedData/Growth-*/Build/Products/Debug-iphonesimulator/Growth.app`
2. Delete: `Growth.xcodeproj/xcuserdata/`
3. Delete: `Growth.xcodeproj/project.xcworkspace/xcuserdata/`
4. Restart your Mac
5. Rebuild

## Verify It Worked

When you run the app, you should only see:
- Your app's print statements
- Error-level Firebase logs (if any)
- NO verbose Firebase transaction logs
- NO [FirebaseFirestore][I-FST000001] messages

## Prevention

To prevent this in the future:
1. Use the code-based configuration we set up earlier
2. Avoid using `FIRDebugEnabled` environment variable
3. If you need temporary debug logs, use `FIRDebugDisabled = 0` to re-enable them temporarily