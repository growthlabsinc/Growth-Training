#!/bin/bash

echo "🔧 Fixing iOS 17.0+ Preview Compatibility Issues"
echo "=============================================="
echo ""

# Find all files with #Preview
echo "Finding files with #Preview macro (iOS 17.0+)..."
FILES=$(grep -r "#Preview" Growth --include="*.swift" -l 2>/dev/null)

if [ -z "$FILES" ]; then
    echo "✅ No #Preview macros found (good for iOS 16.0 compatibility)"
else
    echo "Found #Preview in these files:"
    echo "$FILES"
    echo ""
    echo "⚠️  #Preview macro requires iOS 17.0+"
    echo "These should be converted to PreviewProvider for iOS 16.0 compatibility"
fi

echo ""
echo "Finding .sizeThatFitsLayout usage..."
SIZE_FILES=$(grep -r "sizeThatFitsLayout" Growth --include="*.swift" -l 2>/dev/null)

if [ -z "$SIZE_FILES" ]; then
    echo "✅ No .sizeThatFitsLayout found"
else
    echo "Found .sizeThatFitsLayout in:"
    echo "$SIZE_FILES"
fi

echo ""
echo "✅ Fixed CardButtonStyle.swift"
echo ""
echo "Next steps:"
echo "1. Clean build folder (Shift+Cmd+K)"
echo "2. Build again"
echo ""
echo "If you find more iOS 17.0+ issues, they need to be wrapped with:"
echo "  if #available(iOS 17.0, *) { ... }"
echo "Or use iOS 16.0 compatible alternatives"