# Setup Automatic dSYM Upload in Xcode

## Step-by-Step Instructions

### 1. Open Xcode Project
- Open `Growth.xcodeproj` in Xcode

### 2. Add Build Phase
1. Select the **Growth** target (main app target)
2. Go to **Build Phases** tab
3. Click the **+** button → **New Run Script Phase**
4. Name it: **"Upload dSYMs to Firebase Crashlytics"**
5. Drag it to run **AFTER** "Compile Sources" but **BEFORE** any other upload scripts

### 3. Add This Script
```bash
# Type a script or drag a script file from your workspace to insert its path.
# This script uploads dSYMs to Firebase Crashlytics automatically

echo "Checking for dSYM upload to Firebase Crashlytics..."

# Only run on Release builds (App Store/TestFlight)
if [ "${CONFIGURATION}" = "Release" ] || [ "${CONFIGURATION}" = "Production" ]; then
    
    # Path to the Info.plist
    GOOGLE_PLIST="${PROJECT_DIR}/Growth/Resources/Plist/GoogleService-Info.plist"
    
    # Check if plist exists
    if [ ! -f "$GOOGLE_PLIST" ]; then
        echo "Warning: GoogleService-Info.plist not found at expected location"
        exit 0
    fi
    
    # Find the upload-symbols script (SPM location)
    UPLOAD_SYMBOLS="${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/upload-symbols"
    
    # Alternative locations
    if [ ! -f "$UPLOAD_SYMBOLS" ]; then
        # Try CocoaPods location
        UPLOAD_SYMBOLS="${PODS_ROOT}/FirebaseCrashlytics/upload-symbols"
    fi
    
    if [ ! -f "$UPLOAD_SYMBOLS" ]; then
        # Try another SPM location
        UPLOAD_SYMBOLS="${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/upload-symbols"
    fi
    
    # Check if upload script exists
    if [ ! -f "$UPLOAD_SYMBOLS" ]; then
        echo "Warning: upload-symbols script not found"
        echo "Searched locations:"
        echo "  - ${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/"
        echo "  - ${PODS_ROOT}/FirebaseCrashlytics/"
        exit 0
    fi
    
    echo "Found upload script at: $UPLOAD_SYMBOLS"
    
    # Upload dSYMs
    echo "Uploading dSYMs from: ${DWARF_DSYM_FOLDER_PATH}"
    "$UPLOAD_SYMBOLS" -gsp "$GOOGLE_PLIST" -p ios "${DWARF_DSYM_FOLDER_PATH}"
    
    echo "dSYM upload complete"
else
    echo "Skipping dSYM upload for ${CONFIGURATION} configuration"
fi
```

### 4. Configure Build Phase Settings
- **Shell**: `/bin/sh`
- **Show environment variables in build log**: ✅ Check this for debugging
- **Run script only when installing**: ❌ Leave unchecked
- **Input Files**: Leave empty
- **Output Files**: Leave empty

### 5. Also Add for Widget Extension
1. Select **GrowthTimerWidgetExtension** target
2. Repeat steps 2-4 with the same script
3. This ensures widget crashes are also symbolicated

## Verify It's Working

### During Archive & Upload:
1. Archive your app (Product → Archive)
2. In the build log, search for "dSYM upload"
3. You should see:
   ```
   Uploading dSYMs from: /path/to/dSYMs
   Successfully uploaded Crashlytics symbols
   ```

### After TestFlight Upload:
1. Check Firebase Console → Crashlytics
2. Click on "dSYMs" tab
3. Your new build's UUID should appear as "Uploaded"

## Alternative: Fastlane Integration

If you use Fastlane for deployment, add to your `Fastfile`:

```ruby
lane :beta do
  # Build and upload to TestFlight
  build_app(
    scheme: "Growth",
    export_method: "app-store"
  )
  
  # Upload dSYMs to Firebase
  upload_symbols_to_crashlytics(
    dsym_path: "./Growth.app.dSYM.zip",
    gsp_path: "./Growth/Resources/Plist/GoogleService-Info.plist"
  )
  
  # Upload to TestFlight
  upload_to_testflight
end
```

## Troubleshooting

### If dSYMs Still Show as Missing:

1. **Check Bitcode Settings**:
   - If Bitcode is enabled, Apple recompiles your app
   - You MUST download dSYMs from App Store Connect after processing
   - Go to TestFlight → Build → Download dSYM

2. **Verify Build Settings**:
   - Debug Information Format: `DWARF with dSYM File`
   - Generate Debug Symbols: `YES`
   - Strip Debug Symbols: `YES` (for Release only)

3. **Manual Upload After TestFlight**:
   ```bash
   # Download from App Store Connect first
   # Then run:
   ./upload_specific_dsym.sh ~/Downloads/dSYMs
   ```

## Benefits of Automatic Upload

✅ No more "Missing dSYM" warnings
✅ Crashes are immediately symbolicated
✅ Better crash insights from day one
✅ No manual intervention needed
✅ Works for both app and widget crashes