#!/bin/bash

# Verify Build Script - Alternative to xcodebuild for Claude Code
# This script provides multiple quick checks to verify code is buildable

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "🔧 Build Verification Script"
echo "============================"
echo ""

# 1. Swift Syntax Check
echo "1️⃣ Running Swift syntax check..."
if ./swift_syntax_check.sh > /tmp/syntax_check.log 2>&1; then
    echo -e "${GREEN}✅ Syntax check passed${NC}"
else
    echo -e "${RED}❌ Syntax errors found${NC}"
    tail -20 /tmp/syntax_check.log
    exit 1
fi

# 2. Pattern-based error detection
echo ""
echo "2️⃣ Running pattern-based error detection..."
if ./check_swift_errors.py > /tmp/pattern_check.log 2>&1; then
    echo -e "${GREEN}✅ No critical patterns detected${NC}"
else
    # Check if it's just warnings
    if grep -q "No critical errors found" /tmp/pattern_check.log; then
        echo -e "${YELLOW}⚠️  Warnings found but no critical errors${NC}"
    else
        echo -e "${RED}❌ Critical patterns detected${NC}"
        grep -A5 "ERRORS" /tmp/pattern_check.log | head -20
    fi
fi

# 3. Check for common Swift issues
echo ""
echo "3️⃣ Checking for common Swift issues..."

# Check for missing imports
MISSING_IMPORTS=0
if grep -r "Use of unresolved identifier" Growth --include="*.swift" > /tmp/missing_imports.log 2>&1; then
    MISSING_IMPORTS=$(wc -l < /tmp/missing_imports.log)
fi

if [ $MISSING_IMPORTS -eq 0 ]; then
    echo -e "${GREEN}✅ No missing imports detected${NC}"
else
    echo -e "${RED}❌ Found $MISSING_IMPORTS potential missing imports${NC}"
    head -5 /tmp/missing_imports.log
fi

# 4. Quick module import check
echo ""
echo "4️⃣ Verifying module imports..."
MODULE_CHECK_PASSED=true

# Check if SwiftUI files have SwiftUI import
if grep -L "import SwiftUI" $(find Growth -name "*View.swift" -o -name "*ViewModifier.swift") > /tmp/missing_swiftui.log 2>&1; then
    if [ -s /tmp/missing_swiftui.log ]; then
        echo -e "${YELLOW}⚠️  Some View files might be missing SwiftUI import${NC}"
        MODULE_CHECK_PASSED=false
    fi
fi

# Check if files using Firebase have the import
if grep -l "Firestore\|Auth\.auth\|Firebase" Growth/**/*.swift | xargs grep -L "import Firebase\|import FirebaseAuth\|import FirebaseFirestore" > /tmp/missing_firebase.log 2>&1; then
    if [ -s /tmp/missing_firebase.log ]; then
        echo -e "${YELLOW}⚠️  Some files using Firebase might be missing imports${NC}"
        MODULE_CHECK_PASSED=false
    fi
fi

if [ "$MODULE_CHECK_PASSED" = true ]; then
    echo -e "${GREEN}✅ Module imports look good${NC}"
fi

# 5. Final summary
echo ""
echo "============================"
echo "📊 VERIFICATION SUMMARY"
echo "============================"

if [ -f /tmp/syntax_check.log ] && grep -q "All files passed" /tmp/syntax_check.log && [ $MISSING_IMPORTS -eq 0 ]; then
    echo -e "${GREEN}✅ Code appears to be buildable!${NC}"
    echo ""
    echo "Note: This is a quick check. For a full build verification, use:"
    echo "  timeout 60 xcodebuild -project Growth.xcodeproj -scheme Growth -configuration Debug build"
    exit 0
else
    echo -e "${RED}❌ Build issues detected${NC}"
    echo ""
    echo "Please fix the errors above before attempting a full build."
    exit 1
fi