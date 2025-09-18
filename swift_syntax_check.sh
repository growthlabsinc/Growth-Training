#!/bin/bash

# Swift Syntax Check Script
# This script provides a fast way to check Swift syntax without full compilation
# Useful when xcodebuild is slow or stalls

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "🔍 Swift Syntax Check - Quick validation without full build"
echo "============================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counter for errors
ERROR_COUNT=0
WARNING_COUNT=0

# Function to check a single Swift file
check_swift_file() {
    local file="$1"
    local relative_path="${file#$SCRIPT_DIR/}"
    
    # Use swiftc -parse to check syntax without compiling
    if swiftc -parse "$file" -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) -target x86_64-apple-ios15.0-simulator 2>&1 | grep -E "(error:|warning:)" > /tmp/swift_check_output.txt; then
        if grep -q "error:" /tmp/swift_check_output.txt; then
            echo -e "${RED}❌ $relative_path${NC}"
            cat /tmp/swift_check_output.txt
            ((ERROR_COUNT++))
        elif grep -q "warning:" /tmp/swift_check_output.txt; then
            echo -e "${YELLOW}⚠️  $relative_path${NC}"
            cat /tmp/swift_check_output.txt
            ((WARNING_COUNT++))
        fi
    else
        echo -e "${GREEN}✓${NC} $relative_path"
    fi
}

# Find all Swift files in the Growth directory
echo "Checking Swift files..."
echo ""

# Check specific problematic file first if provided as argument
if [ -n "$1" ]; then
    echo "Checking specific file: $1"
    check_swift_file "$1"
else
    # Check all Swift files in the project
    find Growth -name "*.swift" -type f | while read -r file; do
        check_swift_file "$file"
    done
fi

echo ""
echo "============================================"
echo "Summary:"
echo "  Errors: $ERROR_COUNT"
echo "  Warnings: $WARNING_COUNT"

if [ $ERROR_COUNT -gt 0 ]; then
    echo -e "${RED}Build would fail due to syntax errors${NC}"
    exit 1
else
    echo -e "${GREEN}All files passed syntax check!${NC}"
    exit 0
fi