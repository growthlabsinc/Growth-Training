# Method and Property Error Checker

This directory contains tools to detect and fix Swift compilation errors related to accessing non-existent methods or properties.

## Problem

The app had multiple instances where code was trying to access methods or properties that don't exist on the types being used. For example:
- `viewModel.refresh()` when the method is actually `viewModel.refreshMethods()`
- `viewModel.isEmpty` when the property is actually `viewModel.filteredMethods.isEmpty`
- `loadMethods(forceRefresh: true)` when the method signature is `loadMethods()`

## Tools Provided

### 1. `check_method_property_errors.sh` (Bash Script)

A comprehensive bash script that:
- Extracts all ViewModels and Services from the codebase
- Identifies their properties and methods
- Scans all Swift files for potential access errors
- Reports potential typos and naming mismatches
- Generates suggested fixes

**Usage:**
```bash
./check_method_property_errors.sh
```

**Features:**
- Color-coded output for easy reading
- Analyzes ViewModels in `/ViewModels/` directories
- Analyzes Services in `/Services/` directories
- Detects common typo patterns
- Generates sed commands for bulk fixes

### 2. `fix_method_property_errors.py` (Python Script)

An advanced Python script that:
- Performs deeper analysis of Swift type definitions
- Automatically detects access errors
- Suggests fixes based on Levenshtein distance
- Can automatically apply fixes with user confirmation
- Provides preview mode before applying changes

**Usage:**
```bash
# Analyze current directory
python3 fix_method_property_errors.py

# Analyze specific directory
python3 fix_method_property_errors.py /path/to/project
```

**Features:**
- Interactive fix application
- Preview mode to see changes before applying
- Groups errors by file for easy review
- Calculates string similarity for better suggestions
- Tracks number of fixes applied

## Common Fixes Applied

Based on the analysis, here are the most common fixes:

1. **Method name mismatches:**
   - `viewModel.refresh()` → `viewModel.refreshMethods()`
   - `viewModel.loadData()` → `viewModel.loadMethods()`

2. **Property access errors:**
   - `viewModel.isEmpty` → `viewModel.filteredMethods.isEmpty`
   - `viewModel.data` → `viewModel.methods`

3. **Method signature mismatches:**
   - `loadMethods(forceRefresh: true)` → `loadMethods()`
   - `fetchData(completion:)` → `fetchAllMethods(completion:)`

## How to Use

### Quick Fix (Automated)

1. Run the Python script for automatic detection and fixing:
   ```bash
   python3 fix_method_property_errors.py
   ```

2. Review the detected errors

3. Choose to apply fixes:
   - Type `preview` to see what changes will be made
   - Type `yes` to apply all fixes
   - Type `no` to skip automatic fixes

### Manual Review (Detailed Analysis)

1. Run the bash script for detailed analysis:
   ```bash
   ./check_method_property_errors.sh
   ```

2. Review the output for each potential error

3. Manually fix issues or use the generated sed commands

### Verify Fixes

After applying fixes:

1. Build the project to ensure no compilation errors:
   ```bash
   xcodebuild -project Growth.xcodeproj -scheme Growth -sdk iphonesimulator build
   ```

2. Review changes:
   ```bash
   git diff
   ```

3. Run tests to ensure functionality isn't broken

## Example Output

```
🔍 Analyzing Swift project for method/property access errors...

📋 Step 1: Extracting type definitions...
✅ Found 15 types with 127 total members

🔎 Step 2: Checking for access errors...
✅ Found 4 potential errors

📊 Error Report:

📄 /Users/.../FixedGrowthMethodsListView.swift
  Line 181: viewModel.refresh
    Type: GrowthMethodsViewModel
    Suggestions: refreshMethods
    Code: viewModel.refresh()

  Line 192: viewModel.isEmpty
    Type: GrowthMethodsViewModel
    Suggestions: filteredMethods
    Code: if viewModel.isEmpty {
```

## Prevention

To prevent these errors in the future:

1. **Use Xcode's autocomplete** - It will only suggest methods/properties that actually exist

2. **Build frequently** - Catch errors early before they accumulate

3. **Keep ViewModels consistent** - Use standard naming conventions:
   - `refresh()` or `refreshData()` for refresh operations
   - `isEmpty` computed property for checking empty state
   - `load()` or `loadData()` for loading operations

4. **Document public interfaces** - Add comments to public methods/properties in ViewModels and Services

5. **Use protocols** - Define protocols for common ViewModel operations to ensure consistency

## Troubleshooting

If the scripts don't work as expected:

1. **Permission denied**: Make sure scripts are executable
   ```bash
   chmod +x check_method_property_errors.sh fix_method_property_errors.py
   ```

2. **Python not found**: Ensure Python 3 is installed
   ```bash
   python3 --version
   ```

3. **Too many false positives**: The scripts may detect some valid dynamic property access. Review each case carefully.

4. **Scripts miss some errors**: The patterns might need updating. Check the regex patterns in the scripts.

## Customization

You can customize the scripts by:

1. Adding new type patterns to analyze (e.g., Controllers, Providers)
2. Adding new fix patterns for common mistakes in your codebase
3. Adjusting the similarity threshold for suggestions
4. Adding exclusion patterns for certain files or directories

## Contributing

If you find new patterns of errors, update the scripts:

1. Add new patterns to `fix_patterns` in the Python script
2. Add new type detection patterns in `_analyze_swift_file()`
3. Update the common typo patterns in the bash script