#!/bin/bash

# Growth App - Production Build Script
# This script builds a release version of the app for App Store distribution

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="Growth"
SCHEME_NAME="Growth"
BUNDLE_ID="com.growthlabs.growthmethod"
TEAM_ID="62T6J77P6R"
BUILD_DIR="./build"
ARCHIVE_PATH="${BUILD_DIR}/${PROJECT_NAME}.xcarchive"
EXPORT_PATH="${BUILD_DIR}/AppStore"
EXPORT_OPTIONS_PATH="./ExportOptions.plist"
PRODUCT_NAME="Growth: Method"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Function to increment build number
increment_build_number() {
    print_status "Incrementing build number..."
    BUILD_NUMBER=$(date +%Y%m%d%H%M)
    agvtool new-version -all $BUILD_NUMBER
    print_success "Build number set to: $BUILD_NUMBER"
}

# Function to check for debug code
check_for_debug_code() {
    print_status "Checking for debug code..."
    
    # Check for print statements
    if grep -r "print(" --include="*.swift" Growth/ | grep -v "// Release OK" > /dev/null; then
        print_warning "Found print statements in code (use '// Release OK' to allow specific prints)"
    fi
    
    # Check for TODO/FIXME
    TODO_COUNT=$(grep -r "TODO\|FIXME" --include="*.swift" Growth/ | wc -l | tr -d ' ')
    if [ "$TODO_COUNT" -gt 0 ]; then
        print_warning "Found $TODO_COUNT TODO/FIXME comments in code"
    fi
    
    # Check for development URLs
    if grep -r "localhost\|127.0.0.1\|\.local" --include="*.swift" Growth/ | grep -v "// Release OK" > /dev/null; then
        print_warning "Found potential development URLs in code"
    fi
}

# Function to clean build artifacts
clean_build() {
    print_status "Cleaning build artifacts..."
    
    # Clean Xcode build
    xcodebuild clean \
        -project "${PROJECT_NAME}.xcodeproj" \
        -scheme "${SCHEME_NAME}" \
        -configuration Release \
        -quiet
    
    # Remove old build directory
    rm -rf "${BUILD_DIR}"
    mkdir -p "${BUILD_DIR}"
    
    # Clean derived data
    rm -rf ~/Library/Developer/Xcode/DerivedData/${PROJECT_NAME}-*
    
    print_success "Build artifacts cleaned"
}

# Function to optimize assets
optimize_assets() {
    print_status "Optimizing assets..."
    
    # Find all image assets
    ASSET_COUNT=$(find Growth/Assets.xcassets -name "*.png" -o -name "*.jpg" | wc -l | tr -d ' ')
    print_status "Found $ASSET_COUNT image assets"
    
    # Note: ImageOptim would be run here if installed
    if command -v imageoptim &> /dev/null; then
        imageoptim Growth/Assets.xcassets
        print_success "Assets optimized with ImageOptim"
    else
        print_warning "ImageOptim not installed - skipping asset optimization"
    fi
}

# Function to validate project settings
validate_settings() {
    print_status "Validating project settings..."
    
    # Check bundle identifier
    PLIST_BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" Growth/Resources/Plist/App/Info.plist)
    if [ "$PLIST_BUNDLE_ID" != '$(PRODUCT_BUNDLE_IDENTIFIER)' ]; then
        print_error "Bundle identifier mismatch in Info.plist"
        exit 1
    fi
    
    # Check team ID
    if ! xcodebuild -showBuildSettings -project "${PROJECT_NAME}.xcodeproj" -scheme "${SCHEME_NAME}" -configuration Release | grep "DEVELOPMENT_TEAM = ${TEAM_ID}" > /dev/null; then
        print_warning "Team ID may not be correctly set"
    fi
    
    print_success "Project settings validated"
}

# Function to build archive
build_archive() {
    print_status "Building archive..."
    
    xcodebuild archive \
        -project "${PROJECT_NAME}.xcodeproj" \
        -scheme "${SCHEME_NAME}" \
        -configuration Release \
        -archivePath "${ARCHIVE_PATH}" \
        -destination "generic/platform=iOS" \
        -allowProvisioningUpdates \
        PRODUCT_BUNDLE_IDENTIFIER="${BUNDLE_ID}" \
        DEVELOPMENT_TEAM="${TEAM_ID}" \
        CODE_SIGN_STYLE="Manual" \
        CODE_SIGN_IDENTITY="Apple Distribution" \
        | xcpretty
    
    if [ -d "${ARCHIVE_PATH}" ]; then
        print_success "Archive created successfully"
    else
        print_error "Archive creation failed"
        exit 1
    fi
}

# Function to validate archive
validate_archive() {
    print_status "Validating archive..."
    
    xcodebuild -validate-archive \
        -archivePath "${ARCHIVE_PATH}" \
        -quiet
    
    print_success "Archive validation passed"
}

# Function to export IPA
export_ipa() {
    print_status "Exporting IPA for App Store..."
    
    # Check if ExportOptions.plist exists
    if [ ! -f "${EXPORT_OPTIONS_PATH}" ]; then
        print_error "ExportOptions.plist not found at ${EXPORT_OPTIONS_PATH}"
        print_status "Creating default ExportOptions.plist..."
        create_export_options
    fi
    
    xcodebuild -exportArchive \
        -archivePath "${ARCHIVE_PATH}" \
        -exportPath "${EXPORT_PATH}" \
        -exportOptionsPlist "${EXPORT_OPTIONS_PATH}" \
        -allowProvisioningUpdates \
        | xcpretty
    
    if [ -f "${EXPORT_PATH}/${PROJECT_NAME}.ipa" ]; then
        print_success "IPA exported successfully"
    else
        print_error "IPA export failed"
        exit 1
    fi
}

# Function to create default export options
create_export_options() {
    cat > "${EXPORT_OPTIONS_PATH}" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>${TEAM_ID}</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>signingCertificate</key>
    <string>Apple Distribution</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>${BUNDLE_ID}</key>
        <string>Growth App Store Distribution</string>
    </dict>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>thinning</key>
    <string>&lt;thin-for-all-variants&gt;</string>
</dict>
</plist>
EOF
}

# Function to analyze IPA size
analyze_ipa_size() {
    print_status "Analyzing IPA size..."
    
    IPA_PATH="${EXPORT_PATH}/${PROJECT_NAME}.ipa"
    if [ -f "$IPA_PATH" ]; then
        IPA_SIZE=$(du -h "$IPA_PATH" | cut -f1)
        print_status "IPA size: $IPA_SIZE"
        
        # Extract and analyze app size
        TEMP_DIR="${BUILD_DIR}/ipa_analysis"
        mkdir -p "$TEMP_DIR"
        cd "$TEMP_DIR"
        unzip -q "$IPA_PATH"
        
        # Find the app bundle
        APP_PATH=$(find . -name "*.app" -type d | head -1)
        if [ -n "$APP_PATH" ]; then
            APP_SIZE=$(du -sh "$APP_PATH" | cut -f1)
            print_status "App bundle size: $APP_SIZE"
            
            # List largest files
            print_status "Largest files in app bundle:"
            find "$APP_PATH" -type f -exec du -h {} + | sort -rh | head -10
        fi
        
        cd - > /dev/null
        rm -rf "$TEMP_DIR"
    fi
}

# Function to generate build report
generate_report() {
    print_status "Generating build report..."
    
    REPORT_PATH="${BUILD_DIR}/build-report.txt"
    
    cat > "$REPORT_PATH" << EOF
Growth App - Build Report
========================
Date: $(date)
Build Number: ${BUILD_NUMBER}
Bundle ID: ${BUNDLE_ID}
Team ID: ${TEAM_ID}

Archive Path: ${ARCHIVE_PATH}
IPA Path: ${EXPORT_PATH}/${PROJECT_NAME}.ipa

Build Configuration: Release
Code Signing: Manual (Apple Distribution)

EOF
    
    # Add archive info
    if [ -d "${ARCHIVE_PATH}" ]; then
        echo "Archive Info:" >> "$REPORT_PATH"
        xcodebuild -showBuildSettings -archivePath "${ARCHIVE_PATH}" | grep -E "(PRODUCT_NAME|PRODUCT_BUNDLE_IDENTIFIER|TARGETED_DEVICE_FAMILY)" >> "$REPORT_PATH"
    fi
    
    print_success "Build report generated at: $REPORT_PATH"
}

# Main build process
main() {
    print_status "🏗️  Building Growth App for Release..."
    echo ""
    
    # Pre-build checks
    check_for_debug_code
    validate_settings
    
    # Build process
    increment_build_number
    clean_build
    optimize_assets
    build_archive
    validate_archive
    export_ipa
    analyze_ipa_size
    generate_report
    
    echo ""
    print_success "🎉 Build completed successfully!"
    print_status "📦 Archive: ${ARCHIVE_PATH}"
    print_status "📱 IPA: ${EXPORT_PATH}/${PROJECT_NAME}.ipa"
    echo ""
    print_status "Next steps:"
    print_status "1. Upload to App Store Connect using Xcode or Transporter"
    print_status "2. Submit for TestFlight testing"
    print_status "3. Submit for App Store review"
}

# Run main function
main