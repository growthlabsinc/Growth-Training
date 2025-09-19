# GoogleService-Info.plist Integration Instructions

## File Location
✅ The new `GoogleService-Info.plist` has been placed at:
```
Growth/Resources/Plist/GoogleService-Info.plist
```

## Firebase Project Details
- **Project ID**: growth-training-app
- **Bundle ID**: com.growthlabs.growthtraining
- **Project Number**: 997901246801

## Xcode Integration Steps

### Step 1: Open the Project
```bash
open /Users/tradeflowj/Desktop/Dev/growth-training/Growth.xcodeproj
```

### Step 2: Add File to Xcode Project
1. In Xcode, navigate to the project navigator (left sidebar)
2. Find: `Growth` → `Resources` → `Plist` folder
3. Check if `GoogleService-Info.plist` is already referenced:
   - If YES: Skip to Step 3
   - If NO: Continue with adding the file

#### To Add the File:
1. Right-click on the `Plist` folder
2. Select "Add Files to 'Growth'..."
3. Navigate to: `Growth/Resources/Plist/`
4. Select `GoogleService-Info.plist`
5. Ensure these options are checked:
   - ✅ Copy items if needed (should be unchecked since file is already in place)
   - ✅ Add to targets: **Growth** (main app target)
   - ❌ Do NOT add to: **GrowthTimerWidgetExtension** (widget doesn't need Firebase)

### Step 3: Verify Target Membership
1. Select `GoogleService-Info.plist` in the project navigator
2. Open the File Inspector (right sidebar)
3. Under "Target Membership", ensure:
   - ✅ Growth (main app)
   - ❌ GrowthTimerWidgetExtension

### Step 4: Verify Build Phases
1. Select the `Growth` project in navigator
2. Select the `Growth` target
3. Go to "Build Phases" tab
4. Expand "Copy Bundle Resources"
5. Verify `GoogleService-Info.plist` is in the list
6. If missing, click "+" and add it

### Step 5: Clean and Build
```bash
# In Xcode:
# Clean Build Folder: ⌘+Shift+K
# Build: ⌘+B
```

## Multi-Environment Setup

The project supports multiple environments with different plist files:

| Environment | File | Status |
|------------|------|---------|
| Production | `GoogleService-Info.plist` | ✅ Added (new Firebase project) |
| Development | `dev.GoogleService-Info.plist` | ⚠️ Using old project |
| Staging | `staging.GoogleService-Info.plist` | ⚠️ Using old project |

### FirebaseClient.swift Configuration
The app automatically selects the correct plist based on the build configuration:

```swift
// In FirebaseClient.swift
private func configureFirebase() {
    let plistName: String
    #if DEBUG
        plistName = "dev.GoogleService-Info"
    #elseif STAGING
        plistName = "staging.GoogleService-Info"
    #else
        plistName = "GoogleService-Info"  // Production (just added)
    #endif
}
```

## Testing the Integration

### 1. Verify Firebase Initialization
Run the app and check the console for:
```
Firebase configured successfully
```

### 2. Check for Errors
Look for any Firebase configuration errors in the Xcode console

### 3. Verify Connection
The app should connect to the new Firebase project:
- Project: `growth-training-app`
- Instead of the old: `growth-70a85`

## Troubleshooting

### If Firebase Fails to Initialize:
1. Verify the plist is in the app bundle:
   - Check "Copy Bundle Resources" in Build Phases
2. Ensure correct file name (case-sensitive)
3. Clean DerivedData if needed:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```

### If Wrong Project Connects:
1. Check build configuration (Debug/Release)
2. Verify the correct plist is being loaded in `FirebaseClient.swift`
3. Clean and rebuild the project

## Next Steps
After successful integration:
1. Test authentication flow
2. Verify Firestore connection
3. Check Analytics dashboard for events
4. Monitor App Check dashboard

## Important Notes
- The production plist connects to the NEW Firebase project: `growth-training-app`
- Development and staging plists still use the OLD project pending migration
- Do NOT commit the plist files to public repositories (they contain API keys)