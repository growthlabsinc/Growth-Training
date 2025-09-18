#!/bin/bash

# Script to fix the Crashlytics dSYM upload build phase warning
# This adds proper input/output files to the build phase

cat << 'EOF'
================================================================================
Crashlytics Build Phase Fix
================================================================================

This script will help fix the warning about the Crashlytics dSYM upload script
running on every build.

The build phase needs to specify:
1. Input Files: The dSYM files that trigger the upload
2. Output Files: A marker file to track completion

To fix this in Xcode:

1. Open Growth.xcodeproj in Xcode
2. Select the Growth target
3. Go to Build Phases tab
4. Find the "Run Script" phase for Crashlytics dSYM upload
5. Expand it and add:

INPUT FILES:
${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}
${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH}

OUTPUT FILES:
${DERIVED_FILE_DIR}/crashlytics-upload-complete.marker

Or alternatively, if you want it to run every build regardless:
- Uncheck "Based on dependency analysis" checkbox

================================================================================

Here's the updated script with a marker file creation:
================================================================================
EOF

cat << 'SCRIPT'
#!/bin/bash
# This script uploads dSYMs to Firebase Crashlytics automatically

echo "Checking for dSYM upload to Firebase Crashlytics..."

# Only run on Release builds (App Store/TestFlight)
if [ "${CONFIGURATION}" = "Release" ] || [ "${CONFIGURATION}" = "Production" ]; then
    
    # Path to the Info.plist
    GOOGLE_PLIST="${PROJECT_DIR}/Growth/Resources/Plist/GoogleService-Info.plist"
    
    # Check if plist exists
    if [ ! -f "$GOOGLE_PLIST" ]; then
        echo "Warning: GoogleService-Info.plist not found at expected location"
        # Create marker file even on error to prevent re-runs
        echo "plist_not_found" > "${DERIVED_FILE_DIR}/crashlytics-upload-complete.marker"
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
        # Create marker file even on error to prevent re-runs
        echo "script_not_found" > "${DERIVED_FILE_DIR}/crashlytics-upload-complete.marker"
        exit 0
    fi
    
    echo "Found upload script at: $UPLOAD_SYMBOLS"
    
    # Upload dSYMs
    echo "Uploading dSYMs from: ${DWARF_DSYM_FOLDER_PATH}"
    "$UPLOAD_SYMBOLS" -gsp "$GOOGLE_PLIST" -p ios "${DWARF_DSYM_FOLDER_PATH}"
    
    # Create marker file to indicate completion
    echo "upload_complete_$(date +%s)" > "${DERIVED_FILE_DIR}/crashlytics-upload-complete.marker"
    
    echo "dSYM upload complete"
else
    echo "Skipping dSYM upload for ${CONFIGURATION} configuration"
    # Create marker file for non-release builds too
    echo "skipped_${CONFIGURATION}" > "${DERIVED_FILE_DIR}/crashlytics-upload-complete.marker"
fi
SCRIPT

echo ""
echo "================================================================================
The updated script is shown above. Copy it to replace your current build script.
================================================================================
"