# Fix Duplicate GoogleService-Info.plist Warning

## Issue
Xcode is warning about a duplicate GoogleService-Info.plist file in the Copy Bundle Resources build phase.

## Solution

### Option 1: Fix in Xcode (Recommended)
1. Open the project in Xcode
2. Select the Growth project in the navigator
3. Select the Growth target
4. Go to the "Build Phases" tab
5. Expand "Copy Bundle Resources"
6. Look for duplicate entries of `GoogleService-Info.plist`
7. Select one of the duplicates and click the "-" button to remove it
8. Keep only one instance of the file

### Option 2: Check for Multiple References
The project might have multiple GoogleService-Info.plist files for different environments. Check if you have:
- `Growth/Resources/Plist/GoogleService-Info.plist` (Production)
- `Growth/Resources/Plist/dev.GoogleService-Info.plist` (Development)
- `Growth/Resources/Plist/staging.GoogleService-Info.plist` (Staging)

If you have environment-specific files, ensure:
1. Only the main `GoogleService-Info.plist` is in Copy Bundle Resources
2. The environment-specific files are referenced but not copied
3. Your build scripts handle copying the correct file based on the build configuration

### Option 3: Clean and Rebuild
Sometimes this warning persists due to Xcode caching:
```bash
# Clean build folder
rm -rf ~/Library/Developer/Xcode/DerivedData/Growth-*

# Clean SPM cache if needed
rm -rf .build
rm -rf .swiftpm
```

Then rebuild the project.

## Note
This warning doesn't prevent the app from building or running. It's just informing you that Xcode is smart enough to skip the duplicate file during the build process.