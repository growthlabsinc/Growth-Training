# Setup Automatic dSYM Upload to Firebase Crashlytics

## Add Build Phase in Xcode (One-Time Setup)

1. **Open Growth.xcodeproj in Xcode**

2. **Select the Growth target** → Build Phases tab

3. **Click the + button** → New Run Script Phase

4. **Name it**: "Upload dSYMs to Crashlytics"

5. **Add this script**:
```bash
# Upload dSYMs to Firebase Crashlytics
if [ "${CONFIGURATION}" = "Release" ] || [ "${CONFIGURATION}" = "Production" ]; then
    echo "Uploading dSYMs to Firebase Crashlytics..."
    
    # Find the upload-symbols script
    UPLOAD_SYMBOLS="${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/upload-symbols"
    
    if [ ! -f "$UPLOAD_SYMBOLS" ]; then
        echo "Warning: upload-symbols not found at expected location"
        exit 0
    fi
    
    # Upload dSYMs
    "$UPLOAD_SYMBOLS" -gsp "${PROJECT_DIR}/Growth/Resources/Plist/GoogleService-Info.plist" -p ios "${DWARF_DSYM_FOLDER_PATH}"
    
    echo "dSYM upload complete"
fi
```

6. **Make sure this script runs AFTER** "Compile Sources" but BEFORE "Upload Debug Symbols to Sentry" (if you have it)

## Alternative: Fastlane Integration

If you use Fastlane for deployment, add to your Fastfile:
```ruby
lane :upload_symbols do
  upload_symbols_to_crashlytics(
    dsym_path: "./Growth.app.dSYM.zip",
    gsp_path: "./Growth/Resources/Plist/GoogleService-Info.plist"
  )
end
```

## Manual Upload (When Needed)

Run the script we just created:
```bash
./upload_dsyms_to_firebase.sh
```

## Verify in Firebase Console

1. Go to: https://console.firebase.google.com/project/growth-70a85/crashlytics
2. Check that crashes now show symbolicated stack traces
3. The "unprocessed crashes" warning should disappear

## Troubleshooting

- **Missing dSYMs after App Store submission**: Download from App Store Connect → TestFlight → Build → Download dSYM
- **Bitcode enabled**: Apple recompiles your app, you MUST download dSYMs from App Store Connect
- **Check dSYM UUID matches**: Use `dwarfdump -u path/to/Growth.app.dSYM` to verify

## Benefits of Proper dSYM Upload

✅ See exact line numbers where crashes occur
✅ Method names instead of memory addresses  
✅ Better crash grouping and insights
✅ Faster debugging and fixes