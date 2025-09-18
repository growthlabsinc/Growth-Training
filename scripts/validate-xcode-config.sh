#!/bin/bash

# Growth App - Xcode Configuration Validator
# This script validates that Xcode is properly configured with the build settings

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if xcconfig files exist
check_config_files() {
    print_status "Checking configuration files..."
    
    if [ -f "BuildConfigurations/Debug.xcconfig" ]; then
        print_success "Debug.xcconfig found"
    else
        print_error "Debug.xcconfig not found!"
        return 1
    fi
    
    if [ -f "BuildConfigurations/Release.xcconfig" ]; then
        print_success "Release.xcconfig found"
    else
        print_error "Release.xcconfig not found!"
        return 1
    fi
    
    if [ -f "Growth/Growth.Production.entitlements" ]; then
        print_success "Production entitlements found"
    else
        print_error "Production entitlements not found!"
        return 1
    fi
}

# Check if xcconfig files are linked in project
check_config_linked() {
    print_status "Checking if configuration files are linked..."
    
    local debug_linked=$(grep -c "Debug.xcconfig" Growth.xcodeproj/project.pbxproj || true)
    local release_linked=$(grep -c "Release.xcconfig" Growth.xcodeproj/project.pbxproj || true)
    
    if [ "$debug_linked" -gt 0 ]; then
        print_success "Debug.xcconfig is linked"
    else
        print_warning "Debug.xcconfig not linked in project"
    fi
    
    if [ "$release_linked" -gt 0 ]; then
        print_success "Release.xcconfig is linked"
    else
        print_warning "Release.xcconfig not linked in project"
    fi
}

# Validate build settings
validate_build_settings() {
    print_status "Validating build settings..."
    
    # Check Debug configuration
    print_status "Checking Debug configuration..."
    local debug_bundle_id=$(xcodebuild -showBuildSettings -configuration Debug 2>/dev/null | grep "PRODUCT_BUNDLE_IDENTIFIER = " | awk '{print $3}' | head -1)
    
    if [ "$debug_bundle_id" = "com.growthlabs.growthmethod.dev" ]; then
        print_success "Debug bundle ID correct: $debug_bundle_id"
    else
        print_error "Debug bundle ID incorrect: $debug_bundle_id (expected: com.growthlabs.growthmethod.dev)"
    fi
    
    # Check Release configuration
    print_status "Checking Release configuration..."
    local release_bundle_id=$(xcodebuild -showBuildSettings -configuration Release 2>/dev/null | grep "PRODUCT_BUNDLE_IDENTIFIER = " | awk '{print $3}' | head -1)
    
    if [ "$release_bundle_id" = "com.growthlabs.growthmethod" ]; then
        print_success "Release bundle ID correct: $release_bundle_id"
    else
        print_error "Release bundle ID incorrect: $release_bundle_id (expected: com.growthlabs.growthmethod)"
    fi
}

# Check Firebase configuration
check_firebase_config() {
    print_status "Checking Firebase configuration files..."
    
    if [ -f "Growth/Resources/Plist/dev.GoogleService-Info.plist" ]; then
        print_success "Dev Firebase config found"
    else
        print_error "Dev Firebase config not found!"
    fi
    
    if [ -f "Growth/Resources/Plist/GoogleService-Info.plist" ]; then
        print_success "Production Firebase config found"
    else
        print_error "Production Firebase config not found!"
    fi
}

# Check code signing
check_code_signing() {
    print_status "Checking code signing settings..."
    
    # Debug should be automatic
    local debug_sign_style=$(xcodebuild -showBuildSettings -configuration Debug 2>/dev/null | grep "CODE_SIGN_STYLE = " | awk '{print $3}' | head -1)
    
    if [ "$debug_sign_style" = "Automatic" ]; then
        print_success "Debug uses automatic signing"
    else
        print_warning "Debug not using automatic signing: $debug_sign_style"
    fi
    
    # Release should be manual
    local release_sign_style=$(xcodebuild -showBuildSettings -configuration Release 2>/dev/null | grep "CODE_SIGN_STYLE = " | awk '{print $3}' | head -1)
    
    if [ "$release_sign_style" = "Manual" ]; then
        print_success "Release uses manual signing"
    else
        print_warning "Release not using manual signing: $release_sign_style"
    fi
}

# Check optimization settings
check_optimization() {
    print_status "Checking optimization settings..."
    
    # Debug should have no optimization
    local debug_opt=$(xcodebuild -showBuildSettings -configuration Debug 2>/dev/null | grep "SWIFT_OPTIMIZATION_LEVEL = " | awk '{print $3}' | head -1)
    
    if [ "$debug_opt" = "-Onone" ]; then
        print_success "Debug optimization correct: -Onone"
    else
        print_warning "Debug optimization: $debug_opt (expected: -Onone)"
    fi
    
    # Release should be optimized
    local release_opt=$(xcodebuild -showBuildSettings -configuration Release 2>/dev/null | grep "SWIFT_OPTIMIZATION_LEVEL = " | awk '{print $3}' | head -1)
    
    if [ "$release_opt" = "-O" ]; then
        print_success "Release optimization correct: -O"
    else
        print_warning "Release optimization: $release_opt (expected: -O)"
    fi
}

# Dry run build test
test_build() {
    print_status "Testing build configurations (dry run)..."
    
    # Test Debug
    print_status "Testing Debug build..."
    if xcodebuild -project Growth.xcodeproj -scheme Growth -configuration Debug -sdk iphonesimulator -dry-run >/dev/null 2>&1; then
        print_success "Debug configuration builds successfully"
    else
        print_error "Debug configuration has build errors"
    fi
    
    # Test Release
    print_status "Testing Release build..."
    if xcodebuild -project Growth.xcodeproj -scheme Growth -configuration Release -sdk iphonesimulator -dry-run >/dev/null 2>&1; then
        print_success "Release configuration builds successfully"
    else
        print_error "Release configuration has build errors"
    fi
}

# Generate report
generate_report() {
    local report_file="xcode_config_validation_report.txt"
    
    cat > "$report_file" << EOF
Xcode Configuration Validation Report
Generated: $(date)

Configuration Files:
- Debug.xcconfig: $([ -f "BuildConfigurations/Debug.xcconfig" ] && echo "✅ Found" || echo "❌ Missing")
- Release.xcconfig: $([ -f "BuildConfigurations/Release.xcconfig" ] && echo "✅ Found" || echo "❌ Missing")
- Production Entitlements: $([ -f "Growth/Growth.Production.entitlements" ] && echo "✅ Found" || echo "❌ Missing")

Build Settings:
- Debug Bundle ID: $(xcodebuild -showBuildSettings -configuration Debug 2>/dev/null | grep "PRODUCT_BUNDLE_IDENTIFIER = " | awk '{print $3}' | head -1)
- Release Bundle ID: $(xcodebuild -showBuildSettings -configuration Release 2>/dev/null | grep "PRODUCT_BUNDLE_IDENTIFIER = " | awk '{print $3}' | head -1)

Firebase Configuration:
- Dev Config: $([ -f "Growth/Resources/Plist/dev.GoogleService-Info.plist" ] && echo "✅ Found" || echo "❌ Missing")
- Prod Config: $([ -f "Growth/Resources/Plist/GoogleService-Info.plist" ] && echo "✅ Found" || echo "❌ Missing")

Next Steps:
1. If any files are missing, ensure they're created
2. If settings are incorrect, update in Xcode project settings
3. Link xcconfig files in Xcode if not already done
4. Configure code signing certificates and profiles
EOF
    
    print_success "Report saved to: $report_file"
}

# Main execution
main() {
    print_status "🔍 Xcode Configuration Validator"
    echo ""
    
    # Run all checks
    check_config_files
    echo ""
    
    check_config_linked
    echo ""
    
    validate_build_settings
    echo ""
    
    check_firebase_config
    echo ""
    
    check_code_signing
    echo ""
    
    check_optimization
    echo ""
    
    test_build
    echo ""
    
    # Generate report
    generate_report
    
    echo ""
    print_success "✅ Validation complete!"
    print_status "Review the report for any issues that need attention"
}

# Run main function
main