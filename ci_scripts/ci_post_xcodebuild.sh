#!/bin/sh

# ci_post_xcodebuild.sh
# This script runs after the build phase
# It handles post-build tasks like uploading symbols

set -e  # Exit on error

echo "📦 Running post-build tasks for Growth app..."

# Check if build was successful
if [ "$CI_XCODEBUILD_EXIT_CODE" -ne 0 ]; then
    echo "❌ Build failed with exit code: $CI_XCODEBUILD_EXIT_CODE"
    exit 0  # Don't fail the workflow here, as build already failed
fi

echo "✅ Build completed successfully!"

# Upload dSYMs to Firebase Crashlytics (if available)
if [ -d "$CI_DERIVED_DATA_PATH" ]; then
    echo "🔍 Looking for dSYM files..."
    
    # Find all dSYM files
    find "$CI_DERIVED_DATA_PATH" -name "*.dSYM" -type d | while read -r dsym; do
        echo "📤 Found dSYM: $(basename "$dsym")"
        
        # If you have Crashlytics upload script, use it here
        # Example: ./scripts/upload-symbols.sh "$dsym"
    done
fi

# Archive build information
if [ ! -z "$CI_BUILD_NUMBER" ] && [ ! -z "$CI_WORKFLOW" ]; then
    echo "📝 Recording build information..."
    
    BUILD_INFO_FILE="build-info.json"
    cat > "$BUILD_INFO_FILE" << EOF
{
    "build_number": "$CI_BUILD_NUMBER",
    "workflow": "$CI_WORKFLOW",
    "branch": "$CI_BRANCH",
    "commit": "$CI_COMMIT",
    "xcode_version": "$CI_XCODE_VERSION",
    "build_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "scheme": "$CI_XCODE_SCHEME"
}
EOF
    
    echo "✅ Build info saved to $BUILD_INFO_FILE"
fi

# Run any post-build validation
echo "🧪 Running post-build validation..."

# Check if the app binary exists
if [ -f "$CI_APP_BINARY_PATH" ]; then
    echo "✅ App binary found at: $CI_APP_BINARY_PATH"
    
    # You can add additional checks here, such as:
    # - Binary size validation
    # - Architecture verification
    # - Entitlements check
else
    echo "⚠️  App binary not found at expected path"
fi

# Prepare artifacts for archiving
if [ ! -z "$CI_ARCHIVE_PATH" ]; then
    echo "📦 Archive created at: $CI_ARCHIVE_PATH"
    
    # You can process the archive here if needed
    # For example, extracting specific files or creating additional artifacts
fi

# Clean up temporary files
echo "🧹 Cleaning up temporary files..."
# Add any cleanup commands here

# Summary
echo "📊 Post-build summary:"
echo "   - Build Number: ${CI_BUILD_NUMBER:-N/A}"
echo "   - Product Name: ${CI_PRODUCT_NAME:-Growth}"
echo "   - Bundle ID: ${CI_BUNDLE_ID:-com.growth}"
echo "   - Archive Path: ${CI_ARCHIVE_PATH:-N/A}"

echo "✅ Post-build tasks complete!"

# Exit successfully
exit 0