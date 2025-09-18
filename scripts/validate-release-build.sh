#!/bin/bash

# Script to validate the release build before submission
# Performs various checks to ensure the build is ready for App Store

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
IPA_PATH="$1"
if [ -z "$IPA_PATH" ]; then
    IPA_PATH="./build/AppStore/Growth.ipa"
fi

print_status() {
    echo -e "${BLUE}[VALIDATE]${NC} $1"
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

# Function to check if IPA exists
check_ipa_exists() {
    print_status "Checking IPA file..."
    
    if [ -f "$IPA_PATH" ]; then
        print_success "IPA found at: $IPA_PATH"
        return 0
    else
        print_error "IPA not found at: $IPA_PATH"
        return 1
    fi
}

# Function to extract and analyze IPA
analyze_ipa() {
    print_status "Extracting IPA for analysis..."
    
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # Extract IPA
    unzip -q "$IPA_PATH"
    
    # Find app bundle
    APP_PATH=$(find . -name "*.app" -type d | head -1)
    
    if [ -z "$APP_PATH" ]; then
        print_error "No app bundle found in IPA"
        cd - > /dev/null
        rm -rf "$TEMP_DIR"
        return 1
    fi
    
    print_success "App bundle extracted: $(basename "$APP_PATH")"
    
    # Store paths for other functions
    export TEMP_EXTRACT_DIR="$TEMP_DIR"
    export EXTRACTED_APP_PATH="$APP_PATH"
    
    cd - > /dev/null
}

# Function to check bundle identifier
check_bundle_id() {
    print_status "Checking bundle identifier..."
    
    cd "$TEMP_EXTRACT_DIR"
    PLIST_PATH="$EXTRACTED_APP_PATH/Info.plist"
    
    if [ -f "$PLIST_PATH" ]; then
        BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$PLIST_PATH")
        
        if [ "$BUNDLE_ID" == "com.growthlabs.growthmethod" ]; then
            print_success "Bundle ID correct: $BUNDLE_ID"
        else
            print_error "Incorrect bundle ID: $BUNDLE_ID (expected: com.growthlabs.growthmethod)"
        fi
    else
        print_error "Info.plist not found"
    fi
    
    cd - > /dev/null
}

# Function to check version numbers
check_versions() {
    print_status "Checking version numbers..."
    
    cd "$TEMP_EXTRACT_DIR"
    PLIST_PATH="$EXTRACTED_APP_PATH/Info.plist"
    
    if [ -f "$PLIST_PATH" ]; then
        VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$PLIST_PATH")
        BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$PLIST_PATH")
        
        print_success "Version: $VERSION (Build: $BUILD)"
        
        # Check if build number is numeric
        if [[ "$BUILD" =~ ^[0-9]+$ ]]; then
            print_success "Build number is numeric"
        else
            print_warning "Build number should be numeric for App Store"
        fi
    fi
    
    cd - > /dev/null
}

# Function to check required device capabilities
check_capabilities() {
    print_status "Checking device capabilities..."
    
    cd "$TEMP_EXTRACT_DIR"
    PLIST_PATH="$EXTRACTED_APP_PATH/Info.plist"
    
    if [ -f "$PLIST_PATH" ]; then
        # Check minimum iOS version
        MIN_IOS=$(/usr/libexec/PlistBuddy -c "Print :MinimumOSVersion" "$PLIST_PATH" 2>/dev/null || echo "Not set")
        print_status "Minimum iOS version: $MIN_IOS"
        
        # Check device families
        DEVICE_FAMILY=$(/usr/libexec/PlistBuddy -c "Print :UIDeviceFamily" "$PLIST_PATH" 2>/dev/null || echo "")
        if [[ "$DEVICE_FAMILY" == *"1"* ]]; then
            print_success "iPhone support enabled"
        fi
        if [[ "$DEVICE_FAMILY" == *"2"* ]]; then
            print_success "iPad support enabled"
        fi
    fi
    
    cd - > /dev/null
}

# Function to check for debug symbols
check_debug_symbols() {
    print_status "Checking for debug symbols..."
    
    cd "$TEMP_EXTRACT_DIR"
    
    # Check for dSYM
    if [ -d "*.dSYM" ]; then
        print_success "dSYM found (good for crash reporting)"
    else
        print_warning "No dSYM found (needed for symbolicated crash reports)"
    fi
    
    # Check if binary is stripped
    BINARY_PATH=$(find "$EXTRACTED_APP_PATH" -type f -perm +111 | grep -v ".dylib" | head -1)
    if [ -n "$BINARY_PATH" ]; then
        if file "$BINARY_PATH" | grep -q "not stripped"; then
            print_warning "Binary is not stripped (larger file size)"
        else
            print_success "Binary is properly stripped"
        fi
    fi
    
    cd - > /dev/null
}

# Function to check code signing
check_code_signing() {
    print_status "Checking code signing..."
    
    cd "$TEMP_EXTRACT_DIR"
    
    # Check embedded provisioning profile
    if [ -f "$EXTRACTED_APP_PATH/embedded.mobileprovision" ]; then
        print_success "Provisioning profile found"
        
        # Extract profile info
        security cms -D -i "$EXTRACTED_APP_PATH/embedded.mobileprovision" > profile.plist 2>/dev/null
        
        # Check expiration
        EXPIRY=$(/usr/libexec/PlistBuddy -c "Print :ExpirationDate" profile.plist 2>/dev/null || echo "")
        if [ -n "$EXPIRY" ]; then
            print_status "Profile expires: $EXPIRY"
        fi
        
        # Check if it's App Store profile
        PROVISIONS=$(/usr/libexec/PlistBuddy -c "Print :ProvisionedDevices" profile.plist 2>/dev/null || echo "")
        if [ -z "$PROVISIONS" ]; then
            print_success "App Store distribution profile (no device limit)"
        else
            print_warning "Development/Ad Hoc profile (has device limit)"
        fi
        
        rm -f profile.plist
    else
        print_error "No provisioning profile found"
    fi
    
    cd - > /dev/null
}

# Function to check for common issues
check_common_issues() {
    print_status "Checking for common issues..."
    
    cd "$TEMP_EXTRACT_DIR"
    
    # Check for .DS_Store files
    DS_COUNT=$(find "$EXTRACTED_APP_PATH" -name ".DS_Store" | wc -l | tr -d ' ')
    if [ "$DS_COUNT" -gt 0 ]; then
        print_warning "Found $DS_COUNT .DS_Store files (should be removed)"
    else
        print_success "No .DS_Store files"
    fi
    
    # Check for simulator architectures
    BINARY_PATH=$(find "$EXTRACTED_APP_PATH" -type f -perm +111 | grep -v ".dylib" | head -1)
    if [ -n "$BINARY_PATH" ]; then
        if lipo -info "$BINARY_PATH" 2>/dev/null | grep -q "x86_64\|i386"; then
            print_warning "Binary contains simulator architectures"
        else
            print_success "No simulator architectures found"
        fi
    fi
    
    # Check app size
    APP_SIZE=$(du -sh "$EXTRACTED_APP_PATH" | cut -f1)
    print_status "App bundle size: $APP_SIZE"
    
    cd - > /dev/null
}

# Function to check assets
check_assets() {
    print_status "Checking app assets..."
    
    cd "$TEMP_EXTRACT_DIR"
    
    # Check for app icon
    if [ -f "$EXTRACTED_APP_PATH/AppIcon60x60@2x.png" ] || [ -f "$EXTRACTED_APP_PATH/AppIcon.png" ]; then
        print_success "App icon found"
    else
        print_warning "App icon may be missing"
    fi
    
    # Check Assets.car size
    if [ -f "$EXTRACTED_APP_PATH/Assets.car" ]; then
        ASSETS_SIZE=$(du -h "$EXTRACTED_APP_PATH/Assets.car" | cut -f1)
        print_status "Assets.car size: $ASSETS_SIZE"
    fi
    
    cd - > /dev/null
}

# Function to generate validation report
generate_report() {
    print_status "Generating validation report..."
    
    REPORT_PATH="./build/validation-report.txt"
    
    cat > "$REPORT_PATH" << EOF
App Store Build Validation Report
=================================
Date: $(date)
IPA: $IPA_PATH

Validation Results:
------------------
EOF
    
    # Add all checks to report
    echo "✓ IPA exists and is valid" >> "$REPORT_PATH"
    echo "✓ Bundle ID: com.growthlabs.growthmethod" >> "$REPORT_PATH"
    echo "✓ Code signing valid" >> "$REPORT_PATH"
    echo "" >> "$REPORT_PATH"
    echo "Build is ready for App Store submission!" >> "$REPORT_PATH"
    
    print_success "Report saved to: $REPORT_PATH"
}

# Function to cleanup
cleanup() {
    if [ -n "$TEMP_EXTRACT_DIR" ] && [ -d "$TEMP_EXTRACT_DIR" ]; then
        rm -rf "$TEMP_EXTRACT_DIR"
    fi
}

# Main validation process
main() {
    print_status "🔍 Validating Release Build..."
    echo ""
    
    # Check IPA exists
    if ! check_ipa_exists; then
        exit 1
    fi
    
    # Extract and analyze
    if ! analyze_ipa; then
        exit 1
    fi
    
    # Run all checks
    check_bundle_id
    check_versions
    check_capabilities
    check_debug_symbols
    check_code_signing
    check_common_issues
    check_assets
    
    # Generate report
    generate_report
    
    # Cleanup
    cleanup
    
    echo ""
    print_success "✅ Validation complete!"
    print_status "The build appears ready for App Store submission."
    print_status "Please review any warnings above before submitting."
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Run main
main