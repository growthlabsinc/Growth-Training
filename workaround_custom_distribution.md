# Workaround: Using Custom Distribution

Since you're only seeing "Custom" as an option, you can still upload to App Store Connect using this method:

## Steps:

1. **In the distribution dialog:**
   - Select "Custom" 
   - Click "Next"

2. **On the next screen:**
   - Select "App Store Connect" as the destination
   - Choose your team: "Growth Labs, Inc (62T6J77P6R)"
   - Click "Next"

3. **Export Options:**
   - Distribution certificate: Should auto-select
   - Include bitcode: Uncheck (not needed)
   - Strip Swift symbols: Check
   - Upload symbols: Check
   - Click "Next"

4. **Review:**
   - Verify the settings
   - Click "Export" or "Upload"

5. **If Export was chosen:**
   - Save the .ipa file
   - Upload using Transporter app:
     - Download from Mac App Store
     - Sign in with your Apple ID
     - Drag the .ipa file to upload

## Alternative: Command Line Upload

If the above doesn't work, you can use the command line:

```bash
# First, export the archive
xcodebuild -exportArchive \
  -archivePath ~/Library/Developer/Xcode/Archives/[DATE]/Growth.xcarchive \
  -exportPath ~/Desktop/GrowthExport \
  -exportOptionsPlist ExportOptions.plist

# Then upload using altool
xcrun altool --upload-app \
  -f ~/Desktop/GrowthExport/Growth.ipa \
  -t ios \
  -u jon@growthlabs.coach \
  -p @keychain:AC_PASSWORD
```

## Why This Happens:

The "App Store Connect" option only appears when:
1. Your Apple ID has proper role access in App Store Connect
2. The app record exists in App Store Connect
3. Xcode can verify your access to the specific app

Using "Custom" with App Store Connect destination achieves the same result.