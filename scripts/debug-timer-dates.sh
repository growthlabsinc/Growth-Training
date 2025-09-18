#!/bin/bash

# Script to help debug and fix 1994 date issues in Live Activities

echo "🔍 Debugging Timer Date Issues"
echo "=============================="

# Check for any hardcoded small timestamp values
echo -e "\n📋 Checking for small timestamp values (potential 1994 dates)..."
grep -r "timeIntervalSince1970.*[0-9]\{1,9\}" Growth/Features/Timer --include="*.swift" | grep -v "1577836800" | head -20

# Check for Date() initialization patterns that might be problematic
echo -e "\n📋 Checking for potentially problematic Date initializations..."
grep -r "Date(timeIntervalSince1970:" Growth/Features/Timer --include="*.swift" | grep -E "0\)|[0-9]{1,6}\)" | head -20

# Check for any zero TimeInterval initializations
echo -e "\n📋 Checking for zero TimeInterval values..."
grep -r "TimeInterval.*=.*0[^.]" Growth/Features/Timer --include="*.swift" | grep -v "// " | head -20

# Check widget code for date handling
echo -e "\n📋 Checking widget date handling..."
grep -r "Date\|TimeInterval" GrowthTimerWidget --include="*.swift" | grep -E "= 0|TimeInterval\(0\)" | head -20

# Look for any place where dates might be getting reset to epoch
echo -e "\n📋 Checking for epoch date references..."
grep -r "1970\|epoch" Growth/Features/Timer GrowthTimerWidget --include="*.swift" | head -10

# Summary
echo -e "\n✅ Debug complete. Key findings:"
echo "1. Check any Date(timeIntervalSince1970:) calls with small values"
echo "2. Ensure all TimeInterval values are properly initialized"
echo "3. Add validation to prevent dates before 2020 from being used"
echo "4. Consider using Date() instead of Date(timeIntervalSince1970:0) anywhere"