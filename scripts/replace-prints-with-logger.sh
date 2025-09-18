#!/bin/bash

# Growth App - Replace Print Statements with Logger
# This script safely replaces print() statements with Logger calls

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKUP_DIR="./Growth.backup.$(date +%Y%m%d_%H%M%S)"
LOGGER_IMPORT="import Foundation"
FILES_PROCESSED=0
PRINTS_REPLACED=0

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

# Function to create backup
create_backup() {
    print_status "Creating backup of Growth directory..."
    cp -r Growth "$BACKUP_DIR"
    print_success "Backup created at: $BACKUP_DIR"
}

# Function to check if file needs Logger import
needs_logger_import() {
    local file=$1
    # Check if file already imports the Logger or has it in the same module
    if grep -q "import.*Logger\|struct Logger\|class Logger" "$file"; then
        return 1
    fi
    # Check if it's in Core/Utilities (where Logger lives)
    if [[ "$file" == *"Core/Utilities"* ]]; then
        return 1
    fi
    return 0
}

# Function to add Logger import if needed
add_logger_import() {
    local file=$1
    
    # Skip if Logger is defined in this file
    if grep -q "struct Logger\|class Logger" "$file"; then
        return
    fi
    
    # Skip if already has a Logger import
    if grep -q "import.*Logger" "$file"; then
        return
    fi
    
    # Find the last import statement
    local last_import_line=$(grep -n "^import " "$file" | tail -1 | cut -d: -f1)
    
    if [ -n "$last_import_line" ]; then
        # Add Logger import after the last import
        sed -i '' "${last_import_line}a\\
// Added for production logging\\
import Foundation" "$file"
    else
        # No imports found, add at the beginning after the header comments
        # Find the first non-comment, non-empty line
        local first_code_line=$(grep -n -v "^//" "$file" | grep -v "^$" | head -1 | cut -d: -f1)
        if [ -n "$first_code_line" ]; then
            sed -i '' "${first_code_line}i\\
import Foundation\\
" "$file"
        fi
    fi
}

# Function to determine log level based on context
get_log_level() {
    local line=$1
    local file=$2
    
    # Error patterns
    if echo "$line" | grep -qiE "error|fail|exception|crash|fatal"; then
        echo "error"
        return
    fi
    
    # Warning patterns
    if echo "$line" | grep -qiE "warning|warn|caution|deprecated"; then
        echo "warning"
        return
    fi
    
    # Debug patterns
    if echo "$line" | grep -qiE "debug|test|temp|todo"; then
        echo "debug"
        return
    fi
    
    # Info patterns
    if echo "$line" | grep -qiE "success|complete|finish|done|saved|loaded"; then
        echo "info"
        return
    fi
    
    # Check file context
    if [[ "$file" == *"Service"* ]] || [[ "$file" == *"ViewModel"* ]]; then
        echo "info"
        return
    fi
    
    # Default to debug for UI components
    if [[ "$file" == *"View"* ]] || [[ "$file" == *"Button"* ]]; then
        echo "debug"
        return
    fi
    
    # Default
    echo "debug"
}

# Function to replace print statements in a file
replace_prints_in_file() {
    local file=$1
    local temp_file="${file}.tmp"
    local file_prints=0
    
    # Skip if file doesn't exist or is not a Swift file
    if [[ ! -f "$file" ]] || [[ ! "$file" =~ \.swift$ ]]; then
        return
    fi
    
    # Skip Logger.swift itself
    if [[ "$file" == *"Logger.swift" ]]; then
        return
    fi
    
    # Create a temporary file
    cp "$file" "$temp_file"
    
    # Process line by line
    local line_num=0
    local modified=false
    
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        
        # Check if line contains print statement (not in a comment)
        if echo "$line" | grep -E "^[^/]*print\(" > /dev/null; then
            # Skip if marked as Release OK
            if echo "$line" | grep -q "// Release OK"; then
                echo "$line" >> "$temp_file.new"
                continue
            fi
            
            # Extract the print content
            local print_content=$(echo "$line" | sed -E 's/.*print\((.*)\).*/\1/')
            
            # Determine appropriate log level
            local log_level=$(get_log_level "$line" "$file")
            
            # Replace print with Logger
            local new_line=$(echo "$line" | sed -E "s/print\(/Logger.${log_level}(/")
            
            echo "$new_line" >> "$temp_file.new"
            modified=true
            file_prints=$((file_prints + 1))
            PRINTS_REPLACED=$((PRINTS_REPLACED + 1))
        else
            echo "$line" >> "$temp_file.new"
        fi
    done < "$file"
    
    # If modifications were made, update the file
    if [ "$modified" = true ]; then
        mv "$temp_file.new" "$file"
        
        # Add Logger import if needed
        if needs_logger_import "$file"; then
            add_logger_import "$file"
        fi
        
        FILES_PROCESSED=$((FILES_PROCESSED + 1))
        print_success "Processed $file - Replaced $file_prints print statements"
    else
        rm -f "$temp_file.new"
    fi
    
    rm -f "$temp_file"
}

# Function to process all Swift files
process_all_files() {
    print_status "Processing Swift files..."
    
    # Find all Swift files, excluding certain directories
    find Growth -name "*.swift" -type f \
        ! -path "*/Build/*" \
        ! -path "*/.build/*" \
        ! -path "*/DerivedData/*" \
        ! -path "*/Pods/*" \
        ! -path "*/.swiftpm/*" \
        -print0 | while IFS= read -r -d '' file; do
        replace_prints_in_file "$file"
    done
}

# Function to handle special cases
handle_special_cases() {
    print_status "Handling special cases..."
    
    # Fix any double imports
    find Growth -name "*.swift" -type f -exec sed -i '' '/^import Foundation$/N;/\nimport Foundation$/d' {} +
    
    # Ensure Logger is accessible in files that need it
    # This is handled by the module structure, but we'll verify
    
    print_success "Special cases handled"
}

# Function to generate report
generate_report() {
    local report_file="./print-replacement-report.md"
    
    cat > "$report_file" << EOF
# Print Statement Replacement Report

Generated: $(date)

## Summary
- Files Processed: $FILES_PROCESSED
- Print Statements Replaced: $PRINTS_REPLACED
- Backup Location: $BACKUP_DIR

## Changes Made
1. Replaced \`print()\` with appropriate \`Logger\` calls
2. Added Foundation imports where needed
3. Preserved prints marked with \`// Release OK\`

## Log Level Assignment
- **error**: Statements containing error/fail/exception
- **warning**: Statements containing warning/warn/caution
- **info**: Statements in Services/ViewModels or success messages
- **debug**: UI components and general debugging

## Next Steps
1. Review the changes using git diff
2. Build and test the application
3. Check for any compilation errors
4. Run the app and verify logging works correctly

## Reverting Changes
If you need to revert all changes:
\`\`\`bash
rm -rf Growth
cp -r $BACKUP_DIR Growth
\`\`\`
EOF
    
    print_success "Report generated at: $report_file"
}

# Main execution
main() {
    print_status "🔄 Starting print statement replacement..."
    echo ""
    
    # Check if we're in the right directory
    if [ ! -d "Growth" ]; then
        print_error "Growth directory not found. Please run from project root."
        exit 1
    fi
    
    # Check if Logger.swift exists
    if [ ! -f "Growth/Core/Utilities/Logger.swift" ]; then
        print_error "Logger.swift not found at Growth/Core/Utilities/Logger.swift"
        print_error "Please ensure Logger utility is properly set up first."
        exit 1
    fi
    
    # Create backup
    create_backup
    
    # Process all files
    process_all_files
    
    # Handle special cases
    handle_special_cases
    
    # Generate report
    generate_report
    
    echo ""
    print_success "🎉 Print replacement completed!"
    print_status "📊 Total files modified: $FILES_PROCESSED"
    print_status "📝 Total prints replaced: $PRINTS_REPLACED"
    echo ""
    print_status "Please review the changes and test thoroughly."
    print_warning "Remember to commit your changes after verification!"
}

# Run main function
main