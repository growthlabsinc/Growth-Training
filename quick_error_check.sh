#!/bin/bash

# Quick script to check for real method/property access errors
# Filters out false positives like comments

echo "🔍 Quick Method/Property Error Check"
echo "===================================="
echo ""

# Common error patterns that indicate real issues
echo "Checking for common access error patterns..."
echo ""

# Pattern 1: viewModel.refresh() when it should be refreshMethods()
echo "1. Checking for viewModel.refresh() calls..."
grep -r "viewModel\.refresh()" . \
    --include="*.swift" \
    --exclude-dir=DerivedData \
    --exclude-dir=.build \
    --exclude-dir=build | grep -v "refreshMethods" | head -5

# Pattern 2: viewModel.isEmpty when it might need a different property
echo ""
echo "2. Checking for potentially incorrect isEmpty usage..."
grep -r "viewModel\.isEmpty" . \
    --include="*.swift" \
    --exclude-dir=DerivedData \
    --exclude-dir=.build \
    --exclude-dir=build | head -5

# Pattern 3: Methods called with wrong parameters
echo ""
echo "3. Checking for methods called with forceRefresh parameter..."
grep -r "loadMethods(forceRefresh:" . \
    --include="*.swift" \
    --exclude-dir=DerivedData \
    --exclude-dir=.build \
    --exclude-dir=build | head -5

# Pattern 4: Check for compilation error comments (might indicate unresolved issues)
echo ""
echo "4. Checking for error comments in code..."
grep -r "has no member\|has no dynamic member\|Cannot call value" . \
    --include="*.swift" \
    --exclude-dir=DerivedData \
    --exclude-dir=.build \
    --exclude-dir=build | grep -v "^Binary" | head -5

# Pattern 5: Service.shared.nonExistentMethod patterns
echo ""
echo "5. Checking for potentially incorrect service method calls..."
grep -r "Service\.shared\.[a-zA-Z]*(" . \
    --include="*.swift" \
    --exclude-dir=DerivedData \
    --exclude-dir=.build \
    --exclude-dir=build | grep -v -E "(shared\.(fetchUser|updateUser|updateUserFields|testConnection|configure|fetchData|fetchSelectedRoutineId))" | head -10

echo ""
echo "✅ Quick check complete!"
echo ""
echo "If any results were shown above, they may need to be fixed."
echo "Run './fix_method_property_errors.py' for a more thorough analysis."