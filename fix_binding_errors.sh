#!/bin/bash

# Script to find and report common ObservedObject and Binding errors in Swift files

echo "=== Checking for common ObservedObject and Binding errors ==="
echo ""

# Check 1: Find potential missing $ in sheet presentations
echo "1. Checking for sheet presentations that might need $ prefix..."
find Growth/Features -name "*.swift" -exec grep -H -n "\.sheet(isPresented:.*viewModel\." {} \; | grep -v '\$viewModel' | head -10

echo ""

# Check 2: Find if statements with $ (which is incorrect)
echo "2. Checking for if statements with incorrect $ usage..."
find Growth/Features -name "*.swift" -exec grep -H -n "if.*\\\$viewModel\." {} \; | head -10

echo ""

# Check 3: Find toggle() calls that might need proper binding
echo "3. Checking for toggle() calls..."
find Growth/Features -name "*.swift" -exec grep -H -n "viewModel\..*\.toggle()" {} \; | head -10

echo ""

# Check 4: Find potential property wrapper issues
echo "4. Checking for ObservedObject property access patterns..."
find Growth/Features -name "*.swift" -exec grep -H -n "@ObservedObject.*viewModel" {} \; | head -10

echo ""

# Check 5: Find StateObject to ObservedObject passing
echo "5. Checking for StateObject being passed to views..."
find Growth/Features -name "*.swift" -exec grep -H -n "StateObject.*=.*ViewModel" {} \; | head -10

echo ""

echo "=== Summary ==="
echo "Common fixes needed:"
echo "1. Use \$viewModel.property for bindings (sheet, toggle, TextField, etc.)"
echo "2. Use viewModel.property (no \$) for conditionals and value access"
echo "3. Use viewModel.method() with parentheses for method calls"
echo "4. Create computed properties in ViewModels for nested access"
echo "5. Ensure @Published properties in ViewModels for all UI-bound values"