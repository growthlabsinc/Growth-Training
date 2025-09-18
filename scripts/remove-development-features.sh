#!/bin/bash

# Script to remove all development features from the app
# This can be run before production builds to ensure no debug code is included

echo "🧹 Removing development features from Growth app..."

# Find all files with #if DEBUG blocks
echo "Finding files with DEBUG conditionals..."
DEBUG_FILES=$(find ../Growth -name "*.swift" -exec grep -l "#if DEBUG" {} \;)

if [ -z "$DEBUG_FILES" ]; then
    echo "✅ No DEBUG conditionals found"
else
    echo "📝 Files containing DEBUG conditionals:"
    echo "$DEBUG_FILES" | while read file; do
        echo "  - $file"
    done
    
    echo ""
    echo "To remove DEBUG blocks from these files, you can:"
    echo "1. Manually review and remove #if DEBUG ... #endif blocks"
    echo "2. Use the following command to see the blocks:"
    echo "   grep -n -A 5 -B 1 '#if DEBUG' <filename>"
fi

# Check for specific development files
echo ""
echo "Checking for development-specific files..."

DEVELOPMENT_FILES=(
    "../Growth/Features/Settings/DevelopmentToolsView.swift"
    "../Growth/Features/StyleGuide/StyleGuideViewController.swift"
)

for file in "${DEVELOPMENT_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "⚠️  Found development file: $file"
    fi
done

# Check for development-related strings
echo ""
echo "Checking for development-related strings..."

# Search for common development patterns
PATTERNS=(
    "resetTourState"
    "DevelopmentTools"
    "Developer Options"
    "DEBUG"
    "TEST"
    "Mock"
    "Stub"
)

for pattern in "${PATTERNS[@]}"; do
    echo ""
    echo "Searching for: $pattern"
    MATCHES=$(find ../Growth -name "*.swift" -exec grep -l "$pattern" {} \; 2>/dev/null | grep -v ".build" | grep -v "Tests")
    if [ -n "$MATCHES" ]; then
        echo "$MATCHES" | while read file; do
            echo "  📍 $file"
        done
    fi
done

echo ""
echo "==============================================="
echo "Summary:"
echo "1. Review all #if DEBUG blocks"
echo "2. Remove or comment out DevelopmentToolsView.swift"
echo "3. Remove development menu items from SettingsView"
echo "4. Consider removing resetTourState method if not needed"
echo "5. Run tests to ensure nothing breaks"
echo "==============================================="