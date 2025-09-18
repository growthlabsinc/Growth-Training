#!/bin/bash

# Script to clean debug code from the project
# This helps prepare the code for production release

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Function to find print statements
find_print_statements() {
    print_status "Searching for print statements..."
    
    PRINT_COUNT=$(find Growth -name "*.swift" -type f -exec grep -H "print(" {} \; | grep -v "// Release OK" | wc -l | tr -d ' ')
    
    if [ "$PRINT_COUNT" -gt 0 ]; then
        print_warning "Found $PRINT_COUNT print statements:"
        find Growth -name "*.swift" -type f -exec grep -Hn "print(" {} \; | grep -v "// Release OK" | head -20
        
        echo ""
        read -p "Would you like to comment out these print statements? (y/n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            comment_out_prints
        fi
    else
        print_success "No print statements found"
    fi
}

# Function to comment out print statements
comment_out_prints() {
    print_status "Commenting out print statements..."
    
    # Create backup
    find Growth -name "*.swift" -type f -exec cp {} {}.backup \;
    
    # Comment out prints (except those marked as Release OK)
    find Growth -name "*.swift" -type f -exec sed -i '' '/print(/s/^[[:space:]]*print(/\/\/ DEBUG: print(/' {} \;
    
    # Restore lines marked as Release OK
    find Growth -name "*.swift" -type f -exec sed -i '' '/\/\/ Release OK/s/\/\/ DEBUG: print(/print(/' {} \;
    
    print_success "Print statements commented out"
}

# Function to find TODO/FIXME comments
find_todos() {
    print_status "Searching for TODO/FIXME comments..."
    
    TODO_COUNT=$(find Growth -name "*.swift" -type f -exec grep -H "TODO\|FIXME" {} \; | wc -l | tr -d ' ')
    
    if [ "$TODO_COUNT" -gt 0 ]; then
        print_warning "Found $TODO_COUNT TODO/FIXME comments:"
        find Growth -name "*.swift" -type f -exec grep -Hn "TODO\|FIXME" {} \; | head -10
        echo "..."
    else
        print_success "No TODO/FIXME comments found"
    fi
}

# Function to find development URLs
find_dev_urls() {
    print_status "Searching for development URLs..."
    
    DEV_URL_COUNT=$(find Growth -name "*.swift" -type f -exec grep -H "localhost\|127.0.0.1\|\.local\|ngrok" {} \; | grep -v "// Release OK" | wc -l | tr -d ' ')
    
    if [ "$DEV_URL_COUNT" -gt 0 ]; then
        print_warning "Found $DEV_URL_COUNT potential development URLs:"
        find Growth -name "*.swift" -type f -exec grep -Hn "localhost\|127.0.0.1\|\.local\|ngrok" {} \; | grep -v "// Release OK"
    else
        print_success "No development URLs found"
    fi
}

# Function to find debug-only views
find_debug_views() {
    print_status "Searching for debug-only views..."
    
    # Look for debug menu or debug views
    DEBUG_VIEW_COUNT=$(find Growth -name "*.swift" -type f -exec grep -l "Debug.*View\|DebugMenu" {} \; | wc -l | tr -d ' ')
    
    if [ "$DEBUG_VIEW_COUNT" -gt 0 ]; then
        print_warning "Found $DEBUG_VIEW_COUNT files with potential debug views:"
        find Growth -name "*.swift" -type f -exec grep -l "Debug.*View\|DebugMenu" {} \;
        
        echo ""
        print_status "Make sure these are wrapped in #if DEBUG"
    else
        print_success "No obvious debug views found"
    fi
}

# Function to check for hardcoded API keys
find_api_keys() {
    print_status "Searching for potential hardcoded API keys..."
    
    # Look for common API key patterns
    API_KEY_COUNT=$(find Growth -name "*.swift" -type f -exec grep -H "apiKey\|api_key\|API_KEY\|secret\|SECRET" {} \; | grep -v "// Release OK" | wc -l | tr -d ' ')
    
    if [ "$API_KEY_COUNT" -gt 0 ]; then
        print_warning "Found $API_KEY_COUNT potential API key references:"
        find Growth -name "*.swift" -type f -exec grep -Hn "apiKey\|api_key\|API_KEY\|secret\|SECRET" {} \; | grep -v "// Release OK" | head -10
        echo ""
        print_warning "Please review these to ensure no keys are hardcoded"
    else
        print_success "No obvious API key patterns found"
    fi
}

# Function to create debug cleanup report
create_report() {
    print_status "Creating debug cleanup report..."
    
    REPORT_FILE="build/debug-cleanup-report.txt"
    mkdir -p build
    
    cat > "$REPORT_FILE" << EOF
Debug Code Cleanup Report
========================
Date: $(date)

Summary:
--------
EOF
    
    # Add counts to report
    echo "Print statements: $(find Growth -name "*.swift" -type f -exec grep -H "print(" {} \; | grep -v "// Release OK" | wc -l | tr -d ' ')" >> "$REPORT_FILE"
    echo "TODO/FIXME comments: $(find Growth -name "*.swift" -type f -exec grep -H "TODO\|FIXME" {} \; | wc -l | tr -d ' ')" >> "$REPORT_FILE"
    echo "Development URLs: $(find Growth -name "*.swift" -type f -exec grep -H "localhost\|127.0.0.1\|\.local" {} \; | grep -v "// Release OK" | wc -l | tr -d ' ')" >> "$REPORT_FILE"
    
    print_success "Report saved to: $REPORT_FILE"
}

# Function to verify Firebase configuration
check_firebase_config() {
    print_status "Checking Firebase configuration..."
    
    # Check if production GoogleService-Info.plist exists
    if [ -f "Growth/Resources/Plist/GoogleService-Info.plist" ]; then
        print_success "Production Firebase config found"
        
        # Check bundle ID in plist
        FIREBASE_BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :BUNDLE_ID" Growth/Resources/Plist/GoogleService-Info.plist 2>/dev/null || echo "")
        if [ "$FIREBASE_BUNDLE_ID" == "com.growthlabs.growthmethod" ]; then
            print_success "Firebase bundle ID matches production"
        else
            print_warning "Firebase bundle ID: $FIREBASE_BUNDLE_ID (expected: com.growthlabs.growthmethod)"
        fi
    else
        print_warning "Production Firebase config not found"
    fi
}

# Main execution
main() {
    print_status "🧹 Starting debug code cleanup..."
    echo ""
    
    find_print_statements
    echo ""
    
    find_todos
    echo ""
    
    find_dev_urls
    echo ""
    
    find_debug_views
    echo ""
    
    find_api_keys
    echo ""
    
    check_firebase_config
    echo ""
    
    create_report
    echo ""
    
    print_success "Debug code scan complete!"
    print_status "Review the findings above and make necessary changes before building for release."
}

# Run main
main